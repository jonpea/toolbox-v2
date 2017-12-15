function varargout = fv2xy(varargin)
%FV2XY Convert face-vertex representation to vertex lists.
%   [X,Y] = FC2XY(FACES,VERTICES) returns the vertex lists of a polygon
%   complex given in face-vertex representation:
%   FACES(j,:) is the connectivity list for polygon j;
%   VERTICES(i,1:2) are the coordinate of vertex i; and
%   [X(i,j),Y(i,j)] are the coordinate of vertex i of polygon j.
%
%   [X,Y,Z] = FC2XY(FACES,VERTICES) also returns the third (vertical)
%   coordinate of each vertex for polygons in 3-D.
%
%   With respect to PATCH properties:
%      Faces corresponds to 'Faces'
%   Vertices corresponds to 'Vertices'
%          X corresponds to 'XData'
%          Y corresponds to 'YData'
%          Z corresponds to 'ZData'
%
%   See the reference page on Patch Properties for further details.
%
%   See also PATCH, XY2FV.

import contracts.ndebug
import facevertex.fv

narginchk(1, 2)

[faces, vertices] = fv(varargin{:});

assert(ndebug || ismatrix(faces))
assert(ndebug || ismatrix(vertices))
assert(ndebug || isnumeric(faces))
assert(ndebug || isnumeric(vertices))
assert(ndebug || all(isWithin(faces(isfinite(faces)), 1, size(vertices, 1))))
assert(ndebug || nargout <= size(vertices, 2))

[rows, cols] = find(isnan(faces));
assert(ndebug || issorted(cols, 'ascend')) % invariant of find()
newfaces = faces;
    function padWithDuplicates(row, col)
        assert(1 < col)
        newfaces(row, col) = newfaces(row, col - 1);
    end
arrayfun(@padWithDuplicates, rows, cols)

varargout = arrayfun(@extract, 1 : max(1, nargout), 'UniformOutput', false);
    function x = extract(dim)
        % One row for each column of connectivity array
        x = reshape(vertices(newfaces', dim), fliplr(size(newfaces)));
    end

end

function tf = isWithin(a, lower, upper)
tf = lower <= a & a <= upper;
end
