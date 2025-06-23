%Generates MCL and full airfoil shape from NACA identifier codes
%Only accepts airfoils in the format
%    NACA 23012
%
%Handles 4, 5, and 6-series NACA airfoils

function [shape, mcl]=airfoilgen(ident)
    if length(ident)>=9 && strcmpi(ident(1:4), "NACA")
	series=length(ident(6:end));
	nums=ident(6:end)
	switch series
	    case 4 %NACA 4-series airfoil (e.g. NACA 2412)
		m=str2num(nums(1))/100 %max camber as a multiple of chord
		p=str2num(nums(2))/10 %location of max camber along chord
		t=str2num(nums(3:4))/100 %max thickness as a multiple of chord
		if (m==0 || p==0) && m!=p
		    error("invalid airfoil designator - symmetrical airfoils must follow the format of 00XX")
		elseif m==0 %symmetrical airfoil
		    yc=@(x) x.*0;
		    dycdx=@(x) x.*0;
		    theta=@(x) x.*0;
		else %cambered airfoil
		    yc=@(x) (x<=p).*(m/p^2.*(2*p.*x-x.^2)) + (x>p).*(m/(1-p)^2).*((1-2*p)+2*p.*x-x.^2); %equation for MCL
		    dycdx=@(x) (x<=p).*(2*m/p^2*(p-x)) + (x>p).*(2*(m/(1-p^2)*(p-x))); %derivative of the MCL
		    theta=@(x) atan(dycdx(x)); %finding the slope in radians of the MCL
		end
		yt=@(x) 5*t*(.2969*sqrt(x)-.1260*x-.3516*x.^2+.2843*x.^3-.1015*x.^4);
		xu=@(x) x-yt(x).*sin(theta(x));
		xl=@(x) x+yt(x).*sin(theta(x));
		yu=@(x) yc(x)+yt(x).*cos(theta(x));
		yl=@(x) yc(x)-yt(x).*cos(theta(x));

		xs=linspace(0,1,50); %x values for sampling the MCL

		shape=[xu(xs.^2)' yu(xs.^2)'; xl((1-xs).^2)' yl((1-xs).^2)']; %squaring the x indices to have more points at the sharper curves of the airfoil (toward the leading edge)
		mcl=[xs' yc(xs)'];	
	    case 5 %NACA 5-series airfoil (e.g. NACA 23012)

	    case 6 %NACA 6-series airfoil
		l=str2num(nums(1)) %theoretical optimal lift coefficient
		p=str2num(nums(2)) %distance along chord of maximum camber
		s=str2num(nums(3)) %camber identifier
		tt=str2num(nums(4:5)) %max thickness

		cli=0.15*l;
		
	endswitch

	%plotting the airfoil
	clf;
	plot(shape(:,1), shape(:,2))
	hold on
	plot(mcl(:,1), mcl(:,2))
	hold off
	daspect([1 1 1])
    else
	error("invalid airfoil designator")
    endif
endfunction
