function th = cart2circ(x, y)
%CART2CIRC Transform Cartesian to polar coordinates.
%   [TH,R] = CART2CIRC(X,Y) transforms corresponding elements of data
%   stored in Cartesian coordinates X,Y to an angle TH on the unit circle.  
%   The arrays X and Y must be the same size (or either can be scalar). 
%   TH is returned in radians. 
%
%   NB: TH is wrapped to [0, 2*PI].
%
%   See also CART2POL, CART2SPH, SPH2CART, POL2CART.

th = specfun.wrapinterval(atan2(y, x), 0, 2*pi);
