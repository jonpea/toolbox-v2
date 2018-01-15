function varargout = tangents(varargin)
%FVTOTANGENTS Origin and spanning tangents for affine facets.
%   TANGENT = TANGENTS(FACES,VERTICES) returns the edge tangent 
%   vector for face-vertex models where VERTICES has 2 columns.
%
%   [TANGENT1,TANGENT2] = TANGENTS(FACES,VERTICES) returns a pair of
%   tangent vectors for face-vertex models where vertices has 3 columns.

[faces, vertices] = facevertex.fv(varargin{:});
origin = facevertex.origin(faces, vertices);
assert(ismember(size(vertices, 2), 2 : 3))
varargout{1} = vertices(faces(:, 2), :) - origin;
if size(vertices, 2) == 3
    varargout{2} = vertices(faces(:, end), :) - origin;
end
