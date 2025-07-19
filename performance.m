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
    amin=-5; amax=5; ainc=.5; %alfa min, max, and increment for plotting purposes
    sections=length(wing);
    if sections < 1 || !iscell(wing)
	error("performance - invalid wing input");
    endif
    for i=1:sections
	sect=wing(i);
	[insfid insname]=mkstemp("xinstrXXXXXX"); %Create a temporary file for xfoil input
	[secfid secname]=mkstemp("airsecXXXXXX"); %Create a temporary file for xfoil input
	shape=sect.shape;
	save(secname, "shape");
	fopen(insfid);	
	fputs(["load " secname "\n" 
	secname(end-6:end) 
	"\npacc\nairdat" secname(end-6:end) 
	".txt\naseq " num2str(amin) " " num2str(amax) " " num2str(inc) "\n"
	)];
    endif
endfunction
