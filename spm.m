function out = spm(airfoil, v_inf, alpha)
    global alpha=-deg2rad(alpha);
    global v_inf;
    global points=airfoil.shape;
    global ctls=(points(1:end-1, :)+points(2:end,:))./2; %panel control point coordinates
    global dxs=points(2:end,1)-points(1:end-1,1);
    global dys=points(2:end,2)-points(1:end-1,2);
    global lens=sqrt(dxs.^2+dys.^2);
    global phis=atan2(dys, dxs);
    %phis=phis+(phis<0).*2*pi;
    %phis=phis.*(phis<pi)+(pi-phis).*(phis>=pi);
    global betas=mod(phis-alpha+pi/2, 2*pi);

    A=[]; %making A matrix for computing lambdas
    for i=1:length(ctls)
	row=[];
	for j=1:length(ctls)
	    if i==j
		val=pi;
	    else
		val=Iij(i,j);
	    endif
	    row=[row val];
	endfor
	A=[A; row];
    endfor
    B=-v_inf*2*pi*cos(betas); %making B matrix for computing lambdas 
    global lambdas=linsolve(A,B); %solving for lambdas
    lambdasum=sum(lambdas.*lens)
 
    gridpoints=40; %number of points to sample on the grid
    gridbuffer=.25; %distance to add to edge of airfoil
    [xx yy]=meshgrid(linspace(min(points(:,1))-gridbuffer, max(points(:,1))+gridbuffer,gridpoints), linspace(min(points(:,2))-gridbuffer, max(points(:,2))+gridbuffer, gridpoints));
    [xx2 yy2]=meshgrid(linspace(min(points(:,1))-gridbuffer, max(points(:,1))+gridbuffer,gridpoints*4), linspace(min(points(:,2))-gridbuffer, max(points(:,2))+gridbuffer, gridpoints*4));

    vts=[];
    cps=[];
    cls=[];
    cds=[];
    for i=1:length(ctls)
	vts=[vts vt(i)];
    endfor
    cps=1-(vts./v_inf).^2;
    %fixed=find(abs(cps)<2); %fixed indices for outliers at the trailing edge of the airfoil
    fixed=[1:length(ctls)];
    cns=(-cps.*lens'.*sin(betas'))(fixed);
    cas=(-cps.*lens'.*cos(betas'))(fixed);
    cl=(sum(cns.*cos(alpha))-sum(cas.*sin(alpha)))
    cd=sum(cns.*sin(alpha))+sum(cas.*cos(alpha))

    clf;
    figure 1
    %plot(ctls(:,1), ctls(:,2), '*'); %plotting center points
    vels=vxy(xx, yy);
    vmags=sqrt(vels.xc.^2+vels.yc.^2);
    cpxy=1-(vmags./v_inf).^2;
    %subplot(2,1,1); 
    hold on
    fill(points(:,1), points(:,2), 'k'); %plotting airfoil
    q=quiver(xx, yy, vels.x, vels.y, 'r');
    set(q, "linewidth", 1)  
    streamline(xx, yy, vels.x, vels.y, xx(:,1), yy(:,1));
    axis tight
    daspect([1 1 1])
    title("Flow over object using source panel method")
    hold off

    %subplot(2,1,2);
    figure 2
    title("Cp scalar field visualization")
    hold on
    %cpxy2=interp2(xx, yy, cpxy, xx2, yy2, 'linear'); %expand grid for more refined data
    %imagesc([min(xx)(:) max(xx)(:)], [min(yy)(:) max(yy)(:)], cpxy2);
    xxr=[xx(:); ctls(:,1)]';
    yyr=[yy(:); ctls(:,2)]';
    cpxyr=[cpxy(:); cps(:)];
    [xi yi cpi]=griddata(xxr, yyr, cpxyr, xx2, yy2);
    %pcolor(xi, yi, cpi);
    cpxy(find(cpxy==0))=min(cpxy(find(cpxy>0)));
    pcolor(xx, yy, cpxy);
    %shading interp
    shading flat
    colorbar
    fill(points(:,1), points(:,2), 'k'); %plotting airfoil
    axis tight
    daspect([1 1 1])
    hold off

    figure 3 %plotting pressure values
    plot(ctls(:,1)(fixed), cps(fixed))
    set(gca, "ydir", "reverse")
    hold on
    %plot(ctls(:,1), vts) %plotting velocities
    hold off
    title("Cp vs x")
    xlabel("x")
    ylabel("Cp")

    %figure 3 %plotting velocities
    %surf(xx, yy, sqrt(vels.x.^2+vels.y.^2));
endfunction

function out=vt(i)
    global v_inf;
    global betas;
    global lambdas;
    global ctls;
    out=v_inf*sin(betas(i));
    for j=1:length(ctls)
	out=out+lambdas(j)/(2*pi)*Jij(i,j);
    endfor
endfunction

function out=Iij(i,j)
    if i==j
	out=0;
    else
	global v_inf;
	global alpha;
	global dxs;
	global dys;
	global lens;
	global ctls;
	global phis;
	xi=ctls(i,1); yi=ctls(i,2); xj=ctls(j,1)-lens(j)/2*cos(phis(j)); yj=ctls(j,2)-lens(j)/2*sin(phis(j));
	A=-(xi-xj)*cos(phis(j))-(yi-yj)*sin(phis(j));
	B=(xi-xj)^2+(yi-yj)^2;
	C=sin(phis(i)-phis(j));
	D=-(xi-xj)*sin(phis(i))+(yi-yj)*cos(phis(i));
	E=sqrt(B-A^2);
	if ~isreal(E)
	    E=0;
	endif
	sj=lens(j); 
	out=C/2*(log((sj^2+2*A*sj+B)/B))+(D-A*C)/E*(atan2((sj+A),E)-atan2(A,E));
    endif
endfunction

function out=Jij(i,j)
    if i==j
	out=0;
    else
	global v_inf;
	global alpha;
	global dxs;
	global dys;
	global lens;
	global ctls;
	global phis;
	xi=ctls(i,1); yi=ctls(i,2); xj=ctls(j,1)-lens(j)/2*cos(phis(j)); yj=ctls(j,2)-lens(j)/2*sin(phis(j));
	A=-(xi-xj)*cos(phis(j))-(yi-yj)*sin(phis(j));
	B=(xi-xj)^2+(yi-yj)^2;
	C=-cos(phis(i)-phis(j));
	D=(xi-xj)*cos(phis(i))+(yi-yj)*sin(phis(i));
	E=sqrt(B-A^2);
	if ~isreal(E)
	    E=0;
	endif
	sj=lens(j); 
	out=C/2*(log((sj^2+2*A*sj+B)/B))+(D-A*C)/E*(atan((sj+A)/E)-atan(A/E));
    endif
endfunction

function out=vxy(x, y)
    if length(x)~=1
	out.x=[];
	out.y=[];
	out.xc=[];
	out.yc=[];
	for a=1:size(x)(1)
	    row.x=[];
	    row.y=[];
	    row.xc=[];
	    row.yc=[];
	    for b=1:size(x)(2)
		res=vxy(x(a,b), y(a,b));
		row.x=[row.x res.x];
		row.y=[row.y res.y];
		row.xc=[row.xc res.xc];
		row.yc=[row.yc res.yc];
	    endfor
	    out.x=[out.x; row.x];
	    out.y=[out.y; row.y];
	    out.xc=[out.xc; row.xc];
	    out.yc=[out.yc; row.yc];
	endfor
    elseif size(x) ~= size(y)
	error("both inputs to vxy need to be the same size")
    else
	global v_inf;
	global alpha;
	global dxs;
	global dys;
	global lens;
	global ctls;
	global phis;
	global lambdas;
	global points;
	%if ~inpolygon(x, y, points(:,1), points(:,2))
	    vx=v_inf*cos(alpha);
	    vy=v_inf*sin(alpha);
	    for j=1:length(ctls)
		xj=ctls(j,1)-lens(j)/2*cos(phis(j)); yj=ctls(j,2)-lens(j)/2*sin(phis(j));
		A=-(x-xj)*cos(phis(j))-(y-yj)*sin(phis(j));
		B=(x-xj)^2+(y-yj)^2;
		E=sqrt(B-A^2);
		if ~isreal(E)
		    E=0;
		endif
		sj=lens(j); 

		Cx=-cos(phis(j)); Cy=-sin(phis(j));
		Dx=(x-xj); Dy=(y-yj);

		mxpj=Cx/2*(log((sj^2+2*A*sj+B)/B))+(Dx-A*Cx)/E*(atan2((sj+A),E)-atan2(A,E));
		mypj=Cy/2*(log((sj^2+2*A*sj+B)/B))+(Dy-A*Cy)/E*(atan2((sj+A),E)-atan2(A,E));
		newx=lambdas(j)/(2*pi)*mxpj;
		newy=lambdas(j)/(2*pi)*mypj;
		if isnan(newx) || newx == inf || ~isreal(newx)
		    newx=0;
		endif
		if isnan(newy) || newy == inf || ~isreal(newx)
		    newy=0;
		endif
		newx;
		newy;
		vx=vx+newx;
		vy=vy+newy;
	    endfor
	    if inpolygon(x, y, points(:,1), points(:,2))
		out.xc=vx;
		out.yc=vy;
		out.x=0;
		out.y=0;
	    else
		out.x=vx;
		out.y=vy;
		out.xc=vx;
		out.yc=vy;
	    endif
	    %{
	else
	    out.x=0;
	    out.y=0;
	endif
	%}
    endif
endfunction
