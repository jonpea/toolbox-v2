function [x, y] = pol2cart(th, r)
%POL2CART Transform polar to Cartesian coordinates.
%   [X,Y] = POL2CART(TH,R) transforms corresponding elements of data
%   stored in polar coordinates (angle TH, radius R) to Cartesian
%   coordinates X,Y.  The arrays TH and R must the same size (or
%   either can be scalar).  TH must be in radians.
%
%   See also CART2SPH, CART2POL, SPH2CART.

% Adapted from original ternary version of POL2CART:
%   L. Shure, 4-20-92.
%   Copyright 1984-2004 The MathWorks, Inc. 

x = r.*cos(th);
y = r.*sin(th);
