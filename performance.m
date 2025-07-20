%MADE BY: Wyatt Richards
%EMAIL: wr1701@proton.me
%
%DEPENDENCIES:
%1. Octave io package
%2. Xfoil
%
%Program to take a wingmaker wing struct and generate performance data using xfoil
%*Note: this is only tested on Linux-based systems. It will probably also work with other UNIX-like systems (e.g. macOS or BSD) but will likely not work on Windows
function data=performance(wing)
    pkg load io
    amin=-5; amax=5; ainc=.5; %alfa min, max, and increment for plotting purposes
    sections=length(wing);
    if sections < 1 || !iscell(wing)
	error("performance - invalid wing input");
    endif
    for i=1:sections
	sect=wing{i};
	[insfid insname]=mkstemp("xinstrXXXXXX", true); %Create a temporary file for xfoil input
	[secfid secname]=mkstemp("airsecXXXXXX", true); %Create a temporary file with the airfoil pattern
	shape=sect.shape;
	save(secname, "shape");
	fopen(insfid);	
	datname=["airdat" secname(end-6:end) ".txt"]; %Unique name for the to-be-created performance data file produced by xfoil
	%fputs(insfid, ["load " secname "\n" secname(end-6:end) "\noper\npacc\n" datname "\n\naseq " num2str(amin) " " num2str(amax) " " num2str(ainc) "\npacc\n\nquit"]);
	fputs(insfid, [sect.identifier "\n" secname(end-6:end) "\noper\npacc\n" datname "\n\naseq " num2str(amin) " " num2str(amax) " " num2str(ainc) "\npacc\n\nquit"]);
	system(["xfoil < " insname], true);
	dat=dlmread(datname, '', 12, 0)(:,1:5); %Load xfoil's data into octave; columns 1-5 are [ ALPHA , CL , CD , CDp , CM ]
	data.raw{i}=dat;
	delete(secname, insname, datname); %Get rid of all the files we just created
    endfor
endfunction
