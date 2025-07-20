%CREATED BY: WYATT RICHARDS
%CONTACT: wr1701@proton.me
%
%Function for loading and interpreting a wingmaker configuration file
%
%Dependencies:
%	pkg io
%Usage:
%	data = loadwingdata("my_config_file.csv")
%	data = loadwingdata("my_config_file.csv", 1) %the 1 is an optional flag to produce a plot of the wing
%
%OUTPUT:
%	Cell array of structs (one for each section) with the following fields:
%	.identifier
%	.chord
%	.position
%	.lsweep
%	.vsweep
%	.data
function out=loadwingdata(in, varargin)
    check=exist(in);
    if check ~= 2
	error(["input argument is not a valid file; exist returned ", num2str(check)]);
    endif
    pkg load io;
    file=csv2cell(in);
    sections={};
    secnum=0;
    xx=[];
    yy=[];
    zz=[];
    area=0; %initializing variable for planform wing area
    for i=1:size(file)(1)
	if length(file{i,1})>=4 && strcmpi(file{i,1}(1:4), "NACA") %Check for a valid airfoil section specification
	    secnum=secnum+1;
	    sec.identifier=file{i,1};
	    sec.chord=file{i,2};
	    sec.position=file{i,3};
	    sec.lsweep=-file{i,4};
	    sec.vsweep=-file{i,5};
	    sec.data=airfoilgen(sec.identifier);
	    if secnum==1
		dxy=[0 0]; %change in XY coordinates based on sweep angles and chord positioning
		sec.area=0;
	    else	
		dp=(sections{secnum-1}.position-sec.position);
		dxyp=sections{secnum-1}.dxy; %dxy of the previous airfoil section
		dxy=[dp*tand(sec.lsweep), dp*tand(sec.vsweep)]+dxyp;
		sec.area=-dp*(sec.chord+sections{secnum-1}.chord)/2;
		area=area+sec.area;
	    endif
	    sec.dxy=dxy;
	    sec.shape=sec.data.shape*sec.chord+dxy;
	    xx=[xx sec.shape(:,1)];
	    zz=[zz sec.shape(:,2)];
	    yy=[yy ones(1,length(sec.shape))'*sec.position];
	    sections{secnum}=sec;
	endif
    endfor
    area=area*2; %compensate for the fact that all calculations are done for half of a wing
    wingspan=sections{end}.position*2;
    out.AR=wingspan^2/area; %wing aspect ratio for drag calculations
    out.S=area;
    out.sections=sections;
    if nargin>1 && varargin{nargin-1}==1
	surf(xx, yy, zz); %Plotting the wing shape
	hold on 
	surf(xx, -yy, zz); %Plotting the wing shape
	hold off
	daspect([1 1 1]); %Make the wing to scale
	lighting flat
	shading interp
    endif
endfunction
