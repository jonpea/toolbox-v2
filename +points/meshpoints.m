function [points, varargout] = meshpoints(varargin)
%MESHPOINTS Mesh as scattered points.
% See also MESHGRID, NDGRID.

import contracts.issame

narginchk(1, nargin)

if nargin == 1
    if iscell(varargin{1})
        % ... for grid matrices from the grid vectors
        gridvectors = varargin{:};
        assert(all(cellfun(@isvector, gridvectors)), ...
            'Expected cell array to contain grid vectors.')
        assert(ismember(numel(gridvectors), 2 : 3), ...
            'Expected two or three grid vectors')
        varargin = cell(1, numel(gridvectors));
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

% Return grid matrices if requested
varargout = varargin;
