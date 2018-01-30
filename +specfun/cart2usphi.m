function [azimuth, inclination] = cart2usphi(x, y, z)
%CART2USPHI Transform Cartesian directions to unit-spherical coordinates (inclination form).

% Discards radial coordinates
[azimuth, inclination] = specfun.cart2sphi(x, y, z);
