function g = friis(distance, lambda)
%FRIIS Friis formula for signal gain of free-space propagation.
%   FRIIS(DIST,LAMBDA) returns the Friis free-space gain associated with
%   free-space propagation over a distance DIST of a signal of at
%   wavelength LAMBDA. 
%
%   DIST and LAMBDA should have identical units. 
%
%   Further information on wikipedia.org:
%     https://en.wikipedia.org/wiki/Friis_transmission_equation
%
%   See also FRIISDB.

narginchk(2, 2)

g = (lambda./(4*pi*distance)).^2;
