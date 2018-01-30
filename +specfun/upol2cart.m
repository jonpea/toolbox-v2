function [x, y] = upol2cart(th)
%UPOL2CART Transform unit-polar to Cartesian coordinates.
%   [X,Y] = UPOL2CART(TH) transforms corresponding elements of data on the
%   unit circle stored in polar coordinates (angle TH) to Cartesian
%   coordinates X,Y.  TH must be in radians.
%
%   See also CART2SPH, CART2POL, SPH2CART.

x = cos(th);
y = sin(th);
