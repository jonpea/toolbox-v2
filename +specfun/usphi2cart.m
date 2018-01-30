function [x, y, z] = usphi2cart(azimuth, inclination)
%USPHI2CART Transform unit-spherical to Cartesian coordinates.
%   [X,Y,Z] = USPHI2CART(AZ,INC) returns the Cartesian coordinates X,Y,Z 
%   of points on the unit sphere with azimuthal angle AZ (radians) and
%   angles of inclination INC (radians) from the vertical axis. 
%
%   See also SPHI2CART, CART2SPHI.

% The choice for the 'like' parameter is immaterial.
radius = ones('like', azimuth);

[x, y, z] = specfun.sphi2cart(azimuth, inclination, radius);

% Since "z" has the shape of "elevation", explicit expansion is required.
% This is less expansive than expanding "radius" before call to sph2cart.
z = sx.expand(z, x, y);
