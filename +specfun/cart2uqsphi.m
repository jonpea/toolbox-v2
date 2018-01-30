function [azimuth, inclination] = cart2uqsphi(x, y, z)
%CART2UQSPHI Transform Cartesian directions to unit-spherical coordinates on quarter-sphere.

% Discards radial coordinates
[azimuth, inclination] = specfun.cart2sphi(x, y, z);

azimuth = specfun.wrapquadrant(azimuth);
inclination = specfun.wrapquadrant(inclination);
