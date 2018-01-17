function [th, r, z] = cart2pol(x, y, z)
%CART2POL Transform Cartesian to polar coordinates.
%   [TH,R] = CART2POL(X,Y) transforms corresponding elements of data
%   stored in Cartesian coordinates X,Y to polar coordinates (angle TH
%   and radius R).  The arrays X and Y must be the same size (or
%   either can be scalar). TH is returned in radians. 
%
%   [TH,R,Z] = CART2POL(X,Y,Z) transforms corresponding elements of
%   data stored in Cartesian coordinates X,Y,Z to cylindrical
%   coordinates (angle TH, radius R, and height Z).  The arrays X,Y,
%   and Z must be the same size (or any of them can be scalar).  TH is
%   returned in radians.
%
%   NB: In contrast to the behavior of the built-in CART2POL, 
%       TH is wrapped to [0, 2*PI].
%
%   See also CART2POL, CART2SPH, SPH2CART, POL2CART.

[th, r] = cart2pol(x, y);
th = specfun.wrapinterval(th, 0, 2*pi);
