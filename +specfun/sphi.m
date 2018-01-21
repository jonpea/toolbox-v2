function [azimuth, alpha, r] = sphi(azimuth, beta, r)
%SPHI Toggle spherical coordinates between elevation- and inclination form.
%   [AZ,EL,R] = SPHI(AZ,INC,R) transforms corresponding elements 
%   of data stored in spherical coordinates in azimuth-inclination form to
%   spherical coordinates in azimuth-elevation form.
% 
%   [AZ,INC,R] = SPHI(AZ,EL,R) transforms corresponding elements 
%   of data stored in spherical coordinates in azimuth-elevation form to
%   spherical coordinates in azimuth-inclination form.
%
%   This transformation is involutive i.e. SPHI is its own inverse.
%
%   For further details, see section "Phi and Theta Angles" at
%   http://mathworks.com/help/antenna/gs/antenna-coordinate-system.html
%
%   NB: The Greek symbols adopted in the documentation for
%   CART2SPH/SPH2CART do not match those adopted in CART2SPHI/SPHI2CART:
%   - In CART2SPH/SPH2CART: "azimuth TH, elevation PHI"
%   - In CART2SPHI/SPHI2CART: "azimuth PHI, inclination THETA"

%   See also CART2SPHI, SPHI2CART.

alpha = specfun.elinc(beta);
