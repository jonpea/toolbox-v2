function grid = grid(varargin)
%PARSE Parse grid arguments.
%   See also GRIDDEDINTERPOLANT, NDGRID.

narginchk(1, 3)

if nargin == 1
    % Unstructured points or grid vectors
    grid = parseOne(varargin{:});
else
    % Full grid
    assert(contracts.issame(@size, varargin{:}))
    assert(all(cellfun(@isnumeric, varargin)))
    assert(ndims(varargin{1}) <= nargin) % MATLAB drops trailing singleton dimensions
    grid = varargin;
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
