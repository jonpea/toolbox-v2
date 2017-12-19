function result = dotsx(a, b, varargin)
%DOTSX  Vector dot product (singleton expansion compatible).
%   DOTSX(A,B), for N-D arrays A and B, returns the scalar product
%   along the first non-singleton dimension of A and B. 
%
%   DOTSX(A,B,DIM) returns the scalar product of A and B in the
%   dimension DIM.
%
%   See also DOT, BSXFUN.

narginchk(2, 3)
result = sum(bsxfun(@times, a, b), varargin{:});
