function face = cap(fun, dim, varargin)
%CAP Connectivity list of bouding face for complex with axis-aligned hull.
%   FACE = FACEVERTEX.CAP(@MIN,DIM,VERTICES) returns the connectivity
%   indices of the quadrilateral bounding a complex at the lower boundary
%   in dimension DIM.
%
%   FACE = FACEVERTEX.CAP(@MAX,DIM,VERTICES) returns indices for the upper
%   boundary.
%
%   See also FACEVERTEX.

import datatypes.isfunction
import facevertex.vertices

allvertices = facevertex.vertices(varargin{:});

numDirections = 2; % "forward"/"backwards" or "min"/"max"
numDimensions = 3; % "x"/"y"/"z"
numVerticesPerFace = 4; % "quadrilaterals"

assert(size(allvertices, 2) == numDimensions)
assert(isfunction(fun))

extremes = num2cell([
    min(allvertices);
    max(allvertices);
    ], 1);
[temp{1 : numDimensions}] = meshgrid(extremes{:});
extremevertices = cell2mat(cellfun(@(x) x(:), temp, 'UniformOutput', false));

% Note to Maintainer
% Use the following snippet to visualize the adopted labelling:
%
%  [x, y, z] = meshgrid(0 : 1)
%  xyz = [x(:) y(:) z(:)]
%  graphics.plot(xyz)
%  graphics.text(xyz)
%
faceIndices = reshape(1 : numDirections*numDimensions, [], numDimensions);
localFaces = zeros(numel(faceIndices), numVerticesPerFace);
    function assign(dir, dim, value)
        localFaces(faceIndices(dir, dim), :) = value;
    end
assign(1, 1, [1 2 6 5]) % lower-x
assign(2, 1, [3 4 8 7]) % upper-x
assign(1, 2, [1 3 7 5]) % lower-y
assign(2, 2, [2 4 8 6]) % upper-y
assign(1, 3, [1 3 4 2]) % lower-z
assign(2, 3, [5 6 8 7]) % upper-z

faceIndex = fun(faceIndices(:, dim));
localFace = localFaces(faceIndex, :);
localVertices = extremevertices(localFace, :);

[found, face] = ismember(localVertices, allvertices, 'rows');
assert(all(found), ...
    'Boundaries of convex hull of %s-points in dimension %u are not axis-aligned.', ...
    func2str(fun), dim)
face = face(:)'; % return as row vector

end
