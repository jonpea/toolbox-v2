function [azimuth, elevation, radius] = cart2sph(x, y, z)
%CART2SPH Transform Cartesian to spherical coordinates (elevation form).
%   [TH,PHI,R] = CART2SPH(X,Y,Z) transforms corresponding elements of
%   data stored in Cartesian coordinates X,Y,Z to spherical
%   coordinates (azimuth TH, elevation PHI, and radius R).  The arrays
%   X,Y, and Z must be the same size (or any of them can be scalar).
%   TH and PHI are returned in radians.
%
%   TH is the counterclockwise angle in the xy plane measured from the
%   positive x axis.  PHI is the elevation angle from the xy plane.
%
%   <strong>Note well:</strong>
%   In contrast to the behavior of the built-in CART2SPH, 
%       TH is wrapped to [0, 2*PI]
%   and PHI is wrapped to [-PI, PI].
%
%   See also CART2SPH, CART2POL, SPH2CART, POL2CART.

[azimuth, elevation, radius] = cart2sph(x, y, z);

azimuth = specfun.wrapinterval(azimuth, 0, 2*pi);
elevation = specfun.wrapinterval(elevation, -pi, pi);
