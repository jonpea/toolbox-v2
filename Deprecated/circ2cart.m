function [x, y] = circ2cart(th)
%POL2CART Transform unit-polar to Cartesian coordinates.
%   [X,Y] = POL2CART(TH) transforms corresponding elements of data
%   stored in angle TH to Cartesian coordinates X,Y. 
%   TH must be in radians.
%
%   See also POL2CART, CART2SPH, CART2POL, SPH2CART.

x = cos(th);
y = sin(th);
