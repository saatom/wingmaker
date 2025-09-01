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
  q_inf=.5*rho*v_inf^2; %freestream dynamic pressure
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
    rawdat=dlmread(datname, '', 12, 0)(:,1:5); %Load xfoil's data into octave; columns 1-5 are [ ALPHA , CL , CD , CDp , CM ]
    alphas=avg(:,1); %list of alphas
    dat=[alphas];
    for j=2:5
      dat=[dat interp1(rawdat(:,1), rawdat(:,j), alphas, "extrap")];
    endfor
    data.raw{i}=dat;
    delete(secname, insname, datname); %Get rid of all the temporary files that were just created
    if i>1 %calculate weighted average for performance data
      sec=wing.sections{i}; secp=wing.sections{i-1}; %sec = current section, secp = previous section
      dp=sec.position-secp.position; %difference in position along wing between sections
      c1=secp.chord; %chord of previous section
      c2=sec.chord; %chord of current section
      datp=data.raw{i-1}; %get data of previous section
      valid=length(rawdat(:,1))==length(avg(:,1)); %check if there are as many data points in the latest XFOIL output as we expect
      if valid != 1
	msg=sprintf("%.f data points missing due to XFOIL divergence; using linear extrapolation to fill the gaps\n", length(avg(:,1))-length(rawdat(:,1)));
	warning(msg);
      endif
      localavg(:,1:4)=(c1.*datp(:,1:4)+c2.*dat(:,1:4))./(2)*dp; %find the average of the performance data in this particular section
      localavg(:,5)=(c1^2.*datp(:,5)+c2^2.*dat(:,5))./(2)*dp; %find the average of the performance data in this particular section
      avg=avg+[0 1 1 1 1].*localavg*q_inf*.5; %add the average performance stuff between two sections
    endif
  endfor
  data.polar=avg;
  data.alpha_l0=fzero(@(x) interp1(avg(:,1), avg(:,2), x)-0, -2); %find alpha where lift is 0
  if length(missing)>0
    warning([num2str(length(missing)) " data point(s) missing due to XFOIL divergence\n"]);
  endif
endfunction
