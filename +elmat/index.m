function idx = index(x, varargin)
%INDEX Array indices in a single dimension/subscript.
%   INDEX(A,DIM) returns TRANSPOSE(1:SIZE(A,DIM)).
%
%   INDEX(A) applies to the first non-singleton dimension of A.
%
%   See also SIZE, NDIMS.

narginchk(1, 2)

dim = sx.leaddim(x, varargin{:});
idx = (1 : size(x, dim))';
