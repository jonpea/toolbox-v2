function [azimuth, inclination, r] = cart2sphi(x, y, z)
%CART2SPHI Transform Cartesian to spherical coordinates (inclination form).
%   [PHI,INC,R] = CART2SPHI(X,Y,Z) transforms corresponding elements 
%   of data stored in Cartesian coordinates X,Y,Z to spherical coordinates 
%   (azimuth PHI, inclination INC, and radius R) in inclination form.
%
%   For further details, see section "Phi and Theta Angles" at
%   http://mathworks.com/help/antenna/gs/antenna-coordinate-system.html
%
%   NB: The Greek symbols adopted in the documentation for
%   CART2SPH/SPH2CART do not match those adopted in CART2SPHI/SPHI2CART:
%   - In CART2SPH/SPH2CART: "azimuth TH, elevation PHI"
%   - In CART2SPHI/SPHI2CART: "azimuth PHI, inclination THETA"
%
%   See also SPHI2CART, SPH2CART, CART2SPH, CART2POL, POL2CART.

narginchk(3, 3)

[azimuth, elevation, r] = cart2sph(x, y, z);
inclination = pi/2 - elevation;
