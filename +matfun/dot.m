function result = dot(a, b, varargin)
%DOT  Vector dot product (singleton expansion compatible).
%   DOT(A,B), for N-D arrays A and B, returns the scalar product
%   along the first non-singleton dimension of A and B. 
%
%   DOT(A,B,DIM) returns the scalar product of A and B in dimension DIM.
%
%   See also DOT, BSXFUN.

narginchk(2, 3)

% NB: SUM operates along the first non-singleton dimension by default
result = sum(bsxfun(@times, a, b), varargin{:});
