function g = fullgrid(varargin)

narginchk(1, nargin)
assert(all(cellfun(@isvector, varargin)))

g = cell(size(varargin));
[g{:}] = meshgrid(varargin{:});
