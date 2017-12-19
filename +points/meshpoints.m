function [points, varargout] = meshpoints(varargin)
%SCATTEREd.MESHPOINTS Mesh as scattered points.
% See also MESHGRID, NDGRID.

import contracts.issame

narginchk(1, nargin)

if nargin == 1
    if iscell(varargin{1})
        assert( ...
            all(cellfun(@isvector, varargin)), ...
            'Expected cell array to contain grid vectors.')
        % ... for grid matrices from the grid vectors
        gridvectors = varargin{:};
        varargin = cell(size(gridvectors));
        [varargin{:}] = meshgrid(gridvectors{:});
    end
end

assert( ...
    all(cellfun(@isnumeric, varargin)), ...
    'Arguments must be numeric arrays.')
assert( ...
    all(issame(@size, varargin)), ...
    'Arguments must have identical sizes.')

% Pack grid matrices into the columns of the the points matrix
% i.e. containing the coordinates of one point per row
points = cell2mat(cellfun(@(x) x(:), varargin, 'UniformOutput', false));

if 1 < nargout
    % Return grid matrices if requested
    varargout = varargin;
end
