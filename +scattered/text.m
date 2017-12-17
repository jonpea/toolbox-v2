function varargout = text(varargin)

import datatypes.isaxes
import helpers.parsefirst

narginchk(1, nargin)

[ax, points, varargin] = parsefirst(@isaxes, gca, 1, varargin{:});

switch mod(numel(varargin), 2)
    case 0
        labels = 1 : size(points, 1);
    case 1
        labels = varargin{1};
        varargin(1) = [];
end

assert(ismatrix(points))
assert(ismember(size(points, 2), 2 : 3))
assert(iscell(labels) || isnumeric(labels))
assert(size(points, 1) == numel(labels))

if isnumeric(labels)
    labels = num2cell(labels);
end

% Shift points by 1% to prevent interference with lines/glyphs
extents = max(points) - min(points);
points = points + labelshift(ax, extents); % implicit expansion

points = num2cell(points, 1);
[varargout{1 : nargout}] = builtin( ...
    'text', ax, points{:}, labels(:), varargin{:});
