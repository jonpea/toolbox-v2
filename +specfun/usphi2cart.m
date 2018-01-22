function [x, y, z] = usphi2cart(azimuth, inclination)
%USPHI2CART Transform unit-spherical to Cartesian coordinates.

% The choide of "azimuth" or "inclination" here is immaterial
% since "r" ultimately multiplies both within SPH2CART.
radius = ones(sx.size(azimuth, inclination), 'like', inclination);

[x, y, z] = specfun.sphi2cart(azimuth, inclination, radius);
