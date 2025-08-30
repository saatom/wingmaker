%Wyatt Richards <wr1701@proton.me>
%
%DEPENDENCIES:
%	pkg io
%
%USAGE:
%	[data] = tabledata(altitude_kilometers, VARIABLE)
%
%	Currently supported VARIBLES (input is case insensitive):
%	"mu" - dynamic viscosity
%	"rho" - density
%	"T" - temperature
%	"k" - kinematic viscosity
%	"p" - pressure
%
%DESCRIPTION:
%	Pull various standard atmospheric variables given a density altitude.
%	Thank you to Nicholas Sarmiento (https://github.com/nicolasarmientor) for the atmospheric data table
function varargout = atmdata(h, varargin)
  pkg load io;
  data = cell2mat(csv2cell("standard_atmosphere_table.csv")(2:end,:));
  alts = data(:,1); %column vector with altitudes in km
  if h < min(alts) || h > max(alts)
    msg = sprintf("tabledata: altitude outside of model bounds %.1f km < h < %.1f km\n", min(alts), max(alts));
    error(msg);
  endif
  variables = {"T", "P", "rho", "mu", "k"};
  for i=1:nargin-1
    col = find(strcmpi(varargin{i}, variables))+1;
    if col == 6 %k is just mu/rho
      [mus rhos] = atmdata(h, "mu", "rho");
      varargout{i} = mus./rhos;
    else
      dat = data(:,col); %find data column you're interested in
      varargout{i} = interp1(alts, dat, h);
    endif
  endfor
endfunction
