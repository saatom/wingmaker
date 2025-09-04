%Wyatt Richards <wr1701@proton.me>
%
%DEPENDENCIES:
%1. Octave io package
%2. Octave parallel package
%3. XFOIL (make sure executable is in the system's search path)
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
  pkg load parallel
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
  data.cpu = {};
  data.cpl = {};
  for i=1:sections
    sect=wing.sections{i};
    %Creating cell of inputs
    alphas = [amin:ainc:amax]';
    inputs = {};
    for j=1:length(alphas)
      inputs{j}.Re = sect.chord/c0*Re;
      inputs{j}.alpha = alphas(j);
      inputs{j}.secname = sect.identifier;
    endfor
    outputs = parcellfun(nproc-1, @getSectionPerformance, inputs, "UniformOutput", false, "ChunksPerProc", 4); %cell array containing structs with fields polar, cpu, and cpl (see outputs of getSectionPerformance) using parallel processing
    rawdat = [];
    for j=1:length(outputs)
      incdat = outputs{j}; %structure with data at a specific alpha
      if length(incdat.polar) != 0
	rawdat = [rawdat; incdat.polar];
	data.cpu{i}{j} = incdat.cpu;
	data.cpl{i}{j} = incdat.cpl;	
      else
	missing = [missing; i j];
      endif
    endfor

    dat=[alphas];
    for j=2:5
      dat=[dat interp1(rawdat(:,1), rawdat(:,j), alphas, "extrap")];
    endfor
    data.raw{i}=dat;

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

  %fix missing cp data
  for sec = 1:sections
    numlocalmissing = find(missing(:,1)==sec); %find all of the missing data points for this airfoil section only
    localmissing = missing(numlocalmissing,2);
    if length(localmissing) != 0
      goodcpus = []; %matrix for good cpu data points
      goodcpls = []; %matrix for good cpl data points
      goodalphas = [];
      xls = [];
      xus = [];
      for k = 1:length(alphas); %create a matrix of all the good data points that we can use for extrapolation later
	if length(find(localmissing==k))==0
	  if length(xls) == 0
	    xls = data.cpl{sec}{k}(:,1);
	    xus = data.cpu{sec}{k}(:,1);
	  endif
	  goodalphas = [goodalphas; alphas(k)];
	  goodcpus=[goodcpus; data.cpu{sec}{k}(:,2)'];
	  goodcpls=[goodcpls; data.cpl{sec}{k}(:,2)'];
	endif
      endfor
      for k = 1:length(localmissing) %now go fix the data points of the missing ones
	j = localmissing(k);
	data.cpu{sec}{j} = [xus interp1(goodalphas, goodcpus, alphas(j), "extrap")'];
	data.cpl{sec}{j} = [xls interp1(goodalphas, goodcpls, alphas(j), "extrap")'];
      endfor
    endif
  endfor
  if length(missing) != 0
    msg = sprintf("filling %.f missing data points using linear extrapolation\n", size(missing)(1));
    warning(msg);
  endif

  data.polar=avg;
  data.alpha_l0=fzero(@(x) interp1(avg(:,1), avg(:,2), x)-0, -2); %find alpha where lift is 0
endfunction

function out = getSectionPerformance(in)
  %in should be a struct containing the fields: secname, alpha, Re
  alpha = in.alpha; Re = in.Re; secid = in.secname;
  [insfid insname]=mkstemp("xinstrXXXXXX", true); %Create a temporary file for xfoil input
  [secfid secname]=mkstemp("airsecXXXXXX", true); %Create a temporary file with the airfoil pattern
  fopen(insfid);	
  datname=["airdat" secname(end-6:end) ".txt"]; %Unique name for the to-be-created performance data file produced by xfoil
  cpname=["cpdat" secname(end-6:end) ".txt"]; %Unique name for the to-be-created cp data file produced by xfoil
  fputs(insfid, ["plop\ng\n\n" secid "\noper\nvisc" num2str(Re) "\niter 100\npacc\n" datname "\n\nalfa " num2str(alpha) "\npacc\ncpwr " cpname "\n\nquit\n"]);
  system(["xfoil < " insname " > /dev/null 2>&1"], true);
  plr=dlmread(datname, '', 12, 0); %Load xfoil's data into octave; columns 1-5 are [ ALPHA , CL , CD , CDp , CM ] (omits first 12 lines because they're a header output from XFOIL)
  length(plr);
  if length(plr) == 0
    msg = sprintf("Xfoil diverged for %s at %.1f deg AoA, Re = %.1e\n", secid, alpha, Re);
    warning(msg);
    out.polar = [];
    out.cpu = [];
    out.cpl = [];
  else
    out.polar = plr(:,1:5);
    cpraw=dlmread(cpname, '', 1, 0); %Load xfoil's cp vs x data; columns 1-2 are [ x Cp ]

    cpxmin = min(cpraw(:,1)); %find minimum x in the cp distribution for the purposes of separating upper surface from lower surface
    cpxmini(1) = find(cpraw(:,1) == cpxmin); %find index at which the minimum x occurs
    out.cpu = cpraw(1:cpxmini,:); %pressure coefficient distribution (upper surface)
    out.cpl = cpraw(cpxmini+1:end, :); %perssure coefficient distribution (lower surface)
  endif
  %delete(secname, cpname, insname, datname); %Get rid of all the temporary files that were just created
endfunction
