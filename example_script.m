%CREATED BY: Wyatt Richards
%EMAIL: wr1701@proton.me
%
%DEPENDENCIES:
%	Octave io package
%	XFOIL
%
%DESCRIPTION:
%	This is an example script for how to use wingmaker to analyze a custom wing configuration. Please see the "sampleconfig.csv" file for an idea of how to format the instructions
function example_script()
    close all; %close all plot windows
    wing = loadwingdata("sampleconfig.csv", 1); %create a struct with all of the wing data and create a 3D mesh of the wing design
    wing_area = wing.S %get the wing area
    wing_AR = wing.AR %get the wing aspect ratio
    performance_data = performance(wing, 3e6, [-12 12 1]); %generate performance curves for the wing where the Reynold's number for the first section is 3x10^6 with data taken from -12 degrees to 12 degrees angle of attack with 1 degree increments
endfunction
