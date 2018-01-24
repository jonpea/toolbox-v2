function g = friisdb(distance, lambda)
%FRIISDB Friis formula for gain (in dBW) of free-space propagation.
%   FRIISDB(DIST,LAMBDA) returns the Friis free-space gain (in decibel
%   watts, dBW) associated with free-space propagation over a distance DIST
%   of a signal of at wavelength LAMBDA. 
%
%   DIST and LAMBDA should have identical units. 
%
%   Further information on wikipedia.org:
%     https://en.wikipedia.org/wiki/Friis_transmission_equation
%
%   See also FRIISDB.

narginchk(2, 2)

% Note to Maintainer:
% This formula may improve on the finite-precision accuracy of the
% mathematically equivalent expression "todb(friis(distance,lambda))".
g = 20*(log10(lambda) - log10(4*pi*distance));
