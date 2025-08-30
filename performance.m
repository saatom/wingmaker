%Wyatt Richards <wr1701@proton.me>
%
%DEPENDENCIES:
%1. Octave io package
%2. XFOIL (make sure executable is in the system's search path)
%
%USAGE:
%	data = performance(wing_struct, Re, [alpha_min, alpha_max, alpha_increment})
%
%DESCRIPTION:
%	Program to take a wingmaker wing struct and generate performance data using XFOIL
%	*Note: this is only tested on Linux-based systems. It will probably also work with other UNIX-like systems (e.g. macOS or BSD) but will likely not work on Windows
%
%	All calculations are based on the assumption that Cl and Cd between two airfoil sections changes linearly along them (thus half way between the sections would have a Cl equal to the average of the Cl at the two ends)
function data=performance(wing, varargin)
  pkg load io
  amin=-12; amax=12; ainc=1; %alfa min, max, and increment for plotting purposes
  v_inf=50;
  altitude=0; %sea level
  for i = 1:nargin
    switch i
      case 2
	v_inf=varargin{1};
      case 3
	amin=varargin{2}(1); amax=varargin{2}(2); ainc=varargin{2}(3);
      case 4
	altitude=varargin{3};
    endswitch
  endfor
  [mu rho] = atmdata(altitude, "mu", "rho");
  sections=length(wing.sections);
  if sections < 1 || !iscell(wing.sections)
    error("performance - invalid wing input");
  endif
  datas={};
  avg=[[amin:ainc:amax]' zeros((amax-amin)/ainc+1, 4)]; %average of all of the dat
  badrows=[];
  missing=[];
  c0=wing.sections{1}.chord; %initial chord length
  Re=rho*v_inf*c0/mu;
  %v=Re/(rho*c0)*mu; %find air velocity
  for i=1:sections
    sect=wing.sections{i};
    [insfid insname]=mkstemp("xinstrXXXXXX", true); %Create a temporary file for xfoil input
    [secfid secname]=mkstemp("airsecXXXXXX", true); %Create a temporary file with the airfoil pattern
    shape=sect.shape;
    save(secname, "shape");
    fopen(insfid);	
    datname=["airdat" secname(end-6:end) ".txt"]; %Unique name for the to-be-created performance data file produced by xfoil
    %fputs(insfid, ["load " secname "\n" secname(end-6:end) "\noper\npacc\n" datname "\n\naseq " num2str(amin) " " num2str(amax) " " num2str(ainc) "\npacc\n\nquit"]);
    fputs(insfid, [sect.identifier "\n" secname(end-6:end) "\noper\nvisc" num2str(Re*sect.chord/c0) "\niter 100\npacc\n" datname "\n\naseq " num2str(amin) " " num2str(amax) " " num2str(ainc) "\npacc\n\nquit"]);
    system(["xfoil < " insname], true);
    dat=dlmread(datname, '', 12, 0)(:,1:5); %Load xfoil's data into octave; columns 1-5 are [ ALPHA , CL , CD , CDp , CM ]
    data.raw{i}=dat;
    delete(secname, insname, datname); %Get rid of all the temporary files that were just created
    if i>1 %calculate weighted average for performance data
      sec=wing.sections{i}; secp=wing.sections{i-1};
      dp=sec.position-secp.position;
      c1=secp.chord;
      c2=sec.chord;
      datp=data.raw{i-1};
      valid=length(dat(:,1))==length(avg(:,1)); %check if there are as many data points in the latest XFOIL output as we expect
      if valid != 1
	localmissing=[]; %store the indices of the missing data points in this specific airfoil section
	for j=1:length(avg(:,1))
	  k=j-length(localmissing);
	  if avg(j,1)~=dat(k,1)
	    localmissing=[localmissing j]; %add this problematic data point to the list of missing ones
	  endif
	endfor
	dat=sort([dat; avg(localmissing,:)]);
	missing=[missing localmissing];
      endif
      ngood=length(datp);
      localavg(ngood,1:4)=(c1.*datp(ngood,1:4)+c2.*dat(ngood,1:4))./(2)*dp; %find the average of the performance data in this particular section
      localavg(ngood,5)=(c1^2.*datp(ngood,5)+c2^2.*dat(ngood,5))./(2)*dp; %find the average of the performance data in this particular section
      avg=avg+[0 1 1 1 1].*localavg; %add the average performance stuff between two sections
    endif
  endfor
  missing=unique(sort(missing)); %remove contaminated data points from divergence
  avg(missing,:)=inf; %set contaminated data points to infinity so that they're easy to remove
  avg=avg(find(~isinf(avg(:,1))),:); %remove aforementioned data points
  avg(:,2:end)=avg(:,2:end)*.5*rho*v_inf^2;
  data.polar=avg;
  if length(missing)>0
    warning([num2str(length(missing)) " data point(s) missing due to XFOIL divergence\n"]);
  endif
endfunction
