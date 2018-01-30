function th = cart2upol(x, y)
%CART2UPOL Transform Cartesian directions to polar coordinates on unit circle.
%   [TH,R] = CART2UPOL(X,Y) transforms corresponding elements of direction
%   data stored in Cartesian coordinates X,Y to polar coordinates 
%   (angle TH and radius R). The arrays X and Y must be the same size (or
%   either can be scalar). TH is returned in radians in [0, 2*PI]. 
%
%   See also CART2POL, CART2SPH, SPH2CART, POL2CART.

% Discards radial coordinates
th = specfun.cart2pol(x, y);
