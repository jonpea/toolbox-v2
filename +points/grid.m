function [x1, x2, x3] = grid(varargin)
%PARSE Parse grid arguments.
%   See also GRIDDEDINTERPOLANT, NDGRID.

narginchk(1, 3)

if nargin == 1
    % Unstructured points or grid vectors
    fullGrid = parseOne(varargin{:});
else
    % Full grid
    assert(contracts.issame(@size, varargin{:}))
    assert(all(cellfun(@isnumeric, varargin)))
    assert(ndims(varargin{1}) <= nargin) % MATLAB drops trailing singleton dimensions
    fullGrid = varargin;
end

% Invariants
assert(iscell(fullGrid))
assert(ismember(numel(fullGrid), 2 : 3))

% We use a fixed signature (rather than VARARGOUT) to facilitate
% composition with standard transformations e.g. CART2SPH.
[x1, x2] = deal(fullGrid{1 : 2});
if numel(fullGrid) == 3
    x3 = fullGrid{3};
end

% -------------------------------------------------------------------------
function grid = parseOne(x)
if iscell(x)
    % Grid vectors
    [grid{1 : numel(x)}] = sx.meshgrid(x{:});
else
    % Unstructured points, one per row
    assert(isnumeric(x))
    [grid{1 : size(x, 2)}] = elmat.cols(x);
end
