function [azimuth, inclination] = cart2uqsphi(x, y, z)
%CART2SPHI Transform Cartesian to unit-quarter-spherical coordinates (inclination form).
[azimuth, inclination] = specfun.cart2sphi(x, y, z);
azimuth = specfun.wrapquadrant(azimuth);
inclination = specfun.wrapquadrant(inclination);
