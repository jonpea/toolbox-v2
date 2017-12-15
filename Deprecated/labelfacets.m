function varargout = labelfacets(varargin)

import facevertex.fv
import graphics.isaxes
import helpers.parsefirst

[ax, varargin] = parsefirst(@isaxes, gca, 0, varargin{:});
[faces, vertices, varargin] = parseFaceVertexPair(varargin);
switch mod(numel(varargin), 2)
    case 0
        labels = 1 : size(faces, 1);
    case 1
        labels = varargin{1};
        varargin(1) = [];
end

assert(ismatrix(faces))
assert(ismatrix(vertices))
assert(ismember(size(vertices, 2), 2 : 3))
assert(iscell(labels) || isnumeric(labels))
assert(size(faces, 1) == numel(labels))

if isnumeric(labels)
    labels = num2cell(labels);
end

extendedpoints = reshape( ...
    vertices(faces', :), ...
    size(faces, 2), ...
    size(vertices, 2), ...
    []);
centroids = mean(extendedpoints, 1);
centroids = reshape(centroids, [], size(vertices, 2));
centroids2 = fvcentroids(faces, vertices);
assert(isequal(centroids2, centroids))

% Shift vertices by 1% to prevent interference with lines/glyphs
extents = max(centroids) - min(centroids);
centroids = bsxfun(@plus, centroids, labelshift(ax, extents)); % implicit expansion

centroids = num2cell(centroids, 1);
[varargout{1 : nargout}] = ...
    text(centroids{:}, labels(:), varargin{:}, 'Parent', ax);
