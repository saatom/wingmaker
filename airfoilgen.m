%Generates MCL and full airfoil shape from NACA identifier codes
%Only accepts airfoils in the format
%    NACA 23012
%
%Handles 4, 5, and 6-series NACA airfoils

function out=airfoilgen(ident, varargin)
    if length(ident)>=9 && strcmpi(ident(1:4), "NACA")
	series=length(ident(6:end));
	nums=ident(6:end);
	switch series
	    case 4 %NACA 4-series airfoil (e.g. NACA 2412)
		m=str2num(nums(1))/100; %max camber as a multiple of chord
		p=str2num(nums(2))/10; %location of max camber along chord
		t=str2num(nums(3:4))/100; %max thickness as a multiple of chord
		if (m==0 || p==0) && m!=p
		    error("invalid airfoil designator - symmetrical airfoils must follow the format of 00XX")
		elseif m==0 %symmetrical airfoil
		    yc=@(x) x.*0;
		    dycdx=@(x) x.*0;
		else %cambered airfoil
		    yc=@(x) (x<=p).*(m/p^2.*(2*p.*x-x.^2)) + (x>p).*(m/(1-p)^2).*((1-2*p)+2*p.*x-x.^2); %equation for MCL
		    dycdx=@(x) (x<=p).*(2*m/p^2*(p-x)) + (x>p).*(2*m/(1-p)^2*(p-x)); %derivative of the MCL
		end
	    case 5 %NACA 5-series airfoil (e.g. NACA 23012)
		prof=str2num(nums(1:3)) %camber profile for determining coefficients
		s=str2num(nums(3)); %camber index
		t=str2num(nums(4:5))/100 %max thickness
		if s==0 %simple camber
		    coeffs=[ %non-reflexed camber coefficients
		    210 .05 .0580 361.40; %camber line profile, p, r, k1
		    220 .1 .126 51.640;
		    230 .15 .2025 15.957;
		    240 .2 .29 6.643;
		    250 .25 .391 3.23];
		    index=find(coeffs==prof);
		    coeflist=coeffs(index,:); %getting the line in the above matrix with the relevant coefficients
		    p=coeflist(2); r=coeflist(3); k1=coeflist(4); %finding coefficients

		    yc=@(x) (x<r).*(k1/6*(x.^3-3*r.*x.^2+r.^2*(3-r).*x)) + (x>=r).*(k1*r^3/6*(1-x)); %mcl equation	
		    dycdx=@(x) (x<r).*(k1/6*(3*x.^2-6*r.*x+r^2*(3-r))) + (x>=r).*(-k1*r^3/6); %mcl gradient
		elseif s==1 %reflexed camber
		    coeffs=[ %reflexed camber coefficients
		    221 .1 .13 51.99 7.64e-4; %camber line profile, p, r, k1, k2/k1
		    231 .15 .216 15.793 6.77e-3;
		    241 .2 .318 6.52 3.03e-2;
		    251 .25 .441 3.101 1.355e-1
		    ];
		    index=find(coeffs==prof);
		    coeflist=coeffs(index,:); %getting the line in the above matrix with the relevant coefficients
		    p=coeflist(2); r=coeflist(3); k1=coeflist(4); k2=k1*coeflist(5); %finding coefficients
		    yc=@(x) (x<r).*(k1/6*((x-r).^3-k2/k1*(1-r)^3*x-r^3*x+r^3)) + (x>=r).*(k1/6*(k2/k1*(x-r).^3-k2/k1*(1-r)^3*x-r^3*x+r^3));
		    dycdx=@(x) (x<r).*(k1 .* (-r .^ 3 + 3 * (-r + x) .^ 2 - k2 .* (1 - r) .^ 3 ./ k1) / 6) + (x>=r).*(k1 .* (-r .^ 3 - k2 .* (1 - r) .^ 3 ./ k1 + 3 * k2 .* (-r + x) .^ 2 ./ k1) / 6);
		else
		    error("invalid airfoil designator - 5 series airfoil must have either 0 or 1 camber identifier")
		endif
	    case 6 %NACA 6-series airfoil
		%not yet implemented
	endswitch
	theta=@(x) atan(dycdx(x)); %finding the slope in radians of the MCL
	yt=@(x) 5*t*(.2969*sqrt(x)-.1260*x-.3516*x.^2+.2843*x.^3-.1015*x.^4);
	xu=@(x) x-yt(x).*sin(theta(x)); %x value corresponding to point on upper camber
	xl=@(x) x+yt(x).*sin(theta(x));
	yu=@(x) yc(x)+yt(x).*cos(theta(x)); %y value corresponding to the xu point on upper camber (thus the [xu, yu] pair produces a valid point on the surface of the airfoil)
	yl=@(x) yc(x)-yt(x).*cos(theta(x));

	%xs=(linspace(0,1,80)); %x values for sampling the MCL
	xs=linspace(1,0,80);

	shape=[xu(xs.^2)' yu(xs.^2)'; xl((1-xs).^2)' yl((1-xs).^2)']; %squaring the x indices to have more points at the sharper curves of the airfoil (toward the leading edge)
	mcl=[xs' yc(xs)'];	

	%plotting the airfoil
	if nargin > 1 
	    clf;
	    plot(shape(:,1), shape(:,2))
	    hold on
	    plot(mcl(:,1), mcl(:,2))
	    hold off
	    axis off
	    axis tight
	    daspect([1 1 1]) 
	endif

	%performance calculations
	alpha_l0=-1/pi*quad(@(th) dycdx(.5*(1-cos(th)))*(cos(th)-1), 0, pi); %angle of attack at 0 lift
	alpha_l0_deg=rad2deg(alpha_l0);
	cl=@(alpha) 2*pi*(deg2rad(alpha)-alpha_l0);
	An=@(n) 2/pi*quad(@(th) dycdx(.5*(1-cos(th)))*cos(n*th),0,pi); %An for moment coefficient calculation
	A1=An(1);
	A2=An(2);

	out.shape=shape; %exporting the overall shape as a point matrix for plotting purposes
	out.mcl=mcl; %exporting mcl as point matrix for plotting, but it's probably useless compared to the raw equation
	out.yc=yc; %exporting mcl equation as an anonymous function
	out.dycdx=dycdx; %exporting mcl gradient as an anonymous function
	out.theta=theta;
	%out.cl=cl;
	%out.alphal0=alpha_l0_deg;
	%out.cm=pi/4*(A2-A1); %moment coefficient about 1/4 chord
	%out.xcp=@(alpha) 1/4*(1+pi/cl(alpha)*(A1-A2)); %center of pressure location
    else
	error("invalid airfoil designator")
    endif
endfunction
