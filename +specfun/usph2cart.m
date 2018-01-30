function [x, y, z] = usph2cart(azimuth, elevation)
%USPH2CART Transform unit-spherical to Cartesian coordinates.
%   [X,Y,Z] = USPH2CART(TH,PHI,R) transforms corresponding elements of
%   data on the unit sphere stored in spherical coordinates (azimuth TH,
%   elevation PHI) to Cartesian coordinates X,Y,Z.  The arrays TH,PHI must
%   be the same size (or any of them can be scalar).  TH and
%   PHI must be in radians.
%
%   TH is the counterclockwise angle in the xy plane measured from the
%   positive x axis.  PHI is the elevation angle from the xy plane.
%
%   See also SPH2CART, CART2SPH, CART2POL, POL2CART.

% The choice for the 'like' parameter is immaterial.
radius = ones('like', azimuth);

[x, y, z] = sph2cart(azimuth, elevation, radius);

% Since "z" has the shape of "elevation", explicit expansion is required.
% This is less expansive than expanding "radius" before call to sph2cart.
z = sx.expand(z, x, y);
