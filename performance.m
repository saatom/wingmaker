function out = performance(airfoil, v_inf, alpha)
    alpha=deg2rad(alpha);
    global v_inf;
    global alpha;
    global points=airfoil.shape;
    global ctls=(points(1:end-1, :)+points(2:end,:))./2; %panel control point coordinates
    %betas=alpha+(atan2(points(2:end,2)-points(1:end-1,2), points(2:end,1)-points(1:end-1,1))+pi/2); %beta angles between n vector and freestream
    global dxs=points(2:end,1)-points(1:end-1,1);
    global dys=points(2:end,2)-points(1:end-1,2);
    %global lens=sqrt((points(2:end,2)-points(1:end-1,2)).^2 + (points(2:end,1)-points(1:end-1,1)).^2);
    global lens=sqrt(dxs.^2+dys.^2);
    %global phis=(atan2(points(2:end,2)-points(1:end-1,2), points(2:end,1)-points(1:end-1,1))); %slope of the panel itself
    global phis=atan2(dys, dxs);
    betas=phis+alpha+pi/2;

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

    %[xx yy]=meshgrid(linspace(min(points(:,1))-.05, max(points(:,1))+.05,20), linspace(min(points(:,2))-.05, max(points(:,2))+.05,20));
    clf;
    plot(points(:,1), points(:,2), '-*');
    hold on
    plot(ctls(:,1), ctls(:,2), '*');  
    for i=1:length(betas) %plotting normal vectors
	delta=betas(i)-alpha; %angle of normal with respect to the x axis
	phi=phis(i);
	mag=.05;
	plot([ctls(i,1) ctls(i,1)+mag*cos(delta)], [ctls(i,2) ctls(i,2)+mag*sin(delta)], 'k')
	plot([ctls(i,1) ctls(i,1)+mag*cos(phi)], [ctls(i,2) ctls(i,2)+mag*sin(phi)], 'r')
    endfor
    
    hold off
    axis equal
    daspect([1 1 1])
endfunction

function out=psi(x,y)
    global ctls;
    global lambdas;
    global lens;
    global points;
    global v_inf;
    global alpha;
    global phis;

    out=v_inf*(cos(alpha)*x+sin(alpha)*y);
    %out=v_inf*(cos(alpha)+sin(alpha));
    for j=1:length(ctls)
	pntx=@(s) ctls(j,1)+(-lens(j)/2+s)*cos(phis(j));
	pnty=@(s) ctls(j,2)+(-lens(j)/2+s)*sin(phis(j));
	rpj=@(s) sqrt((pntx(s)-x)^2+(pnty(s)-y)^2);
	out=out+lambdas(j)/(2*pi)*quad(@(s) log(rpj(s)),0,lens(j));
	%out=out+lambdas(j)/(2*pi)*(lens(j)*log(rpj(lens(j)))+lens(j));
    endfor
endfunction

function out=strm(xs, y) %generate matrix of streamlines at a group of xs and an initial y
   pot=psi(xs(1),y);
   %pot = v_inf*(x*cos(alpha)+y*sin(alpha)) + sigma lambdas(j)/(2*pi) *
endfunction

function out=lerp(a,b,c) %linear interpolation function at c fraction between a and b
    out=a+c*(b-a);
endfunction

function out=Iij(i,j)
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
    sj=lens(j); 

    out=C/2*(log((sj^2+2*A*sj+B)/B))+(D-A*C)/E*(atan2((sj+A),E)-atan2(A,E));
endfunction
