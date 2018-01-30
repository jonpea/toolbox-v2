function [x, y, z] = sphi2cart(azimuth, inclination, radius)
%SPHI2CART Transform spherical (inclination form) to Cartesian coordinates.
%   [X,Y,Z] = SPHPT2CART(PHI,THETA,R) transforms corresponding elements of
%   data stored in spherical coordinates (azimuth PHI, inclination THETA,
%   radius R) to Cartesian coordinates X,Y,Z.  
%
%   For further details, see section "Phi and Theta Angles" at
%   http://mathworks.com/help/antenna/gs/antenna-coordinate-system.html
%
%   NB: The Greek symbols adopted in the documentation for
%   CART2SPH/SPH2CART do not match those adopted in CART2SPHI/SPHI2CART:
%   - In CART2SPH/SPH2CART: "azimuth TH, elevation PHI"
%   - In CART2SPHI/SPHI2CART: "azimuth PHI, inclination THETA"
%
%   See also CART2SPHI, SPH2CART, CART2SPH, CART2POL, POL2CART.

narginchk(3, 3)
elevation = specfun.elinc(inclination);
[x, y, z] = sph2cart(azimuth, elevation, radius);
