function [x,y,z] = cyl2cart(th,r,z)
%CYL2CART Transform cylindrical to Cartesian coordinates.
%   [X,Y,Z] = CYL2CART(TH,R,Z) transforms corresponding elements of
%   data stored in cylindrical coordinates (angle TH, radius R, height
%   Z) to Cartesian coordinates X,Y,Z. The arrays TH, R, and Z must be
%   the same size (or any of them can be scalar).  TH must be in radians.
%
%   See also CART2SPH, CART2POL, SPH2CART.

% Adapted from POL2CART:
%   L. Shure, 4-20-92.
%   Copyright 1984-2004 The MathWorks, Inc. 

x = r.*cos(th);
y = r.*sin(th);
