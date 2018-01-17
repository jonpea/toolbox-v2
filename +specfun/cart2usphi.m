function [azimuth, inclination] = cart2usphi(x, y, z)
%CART2SPHI Transform Cartesian to unit-spherical coordinates (inclination form).
[azimuth, inclination] = specfun.cart2sphi(x, y, z);
