function idx = index(x, varargin)
%INDEX Array indices.
%   See also SIZE, NDIMS.

import sx.leaddim

narginchk(1, 2)

dim = leaddim(x, varargin{:});
idx = (1 : size(x, dim))';
