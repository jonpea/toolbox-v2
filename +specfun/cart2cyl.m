function [th, r, z] = cart2cyl(x, y, z)
%CART2CYL Transform Cartesian to cylindrical coordinates.
%   [TH,R,Z] = CART2CYL(X,Y,Z) transforms corresponding elements of
%   data stored in Cartesian coordinates X,Y,Z to cylindrical
%   coordinates (angle TH, radius R, and height Z).  The arrays X,Y,
%   and Z must be the same size (or any of them can be scalar).  
%   TH is returned in radians in the range [0, 2*PI].
%
%   See also CART2POL, CART2SPH, SPH2CART, POL2CART.

[th, r, z] = cart2pol(x, y, z);
th = specfun.wrapinterval(th, 0, 2*pi);
