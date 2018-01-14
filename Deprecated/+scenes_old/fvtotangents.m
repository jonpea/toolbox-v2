function [origin, tangents] = fvtotangents(faces, vertices)
%FVTOTANGENTS Origin and spanning tangents for affine facets.
% [ORIGIN,TANGENT]=FVTOTANGENTS(FACES,VERTICES) returns 2D frame
% data for face-vertex models where vertices has 2 columns.
% [ORIGIN,TANGENT1,TANGENT2]=FVTOTANGENTS(FACES,VERTICES) returns 
% 3D frame data for face-vertex models where vertices has 3 columns.

narginchk(1, 2)

if nargin == 1
    vertices = faces.Vertices;
    faces = faces.Faces;
end

assert(ismember(size(vertices, 2), 2 : 3))
assert(ismember(size(faces, 2), [2, 4]))

% Origin
origin = vertices(faces(:, 1), :);

% Edge tangents
tangents{1} = vertices(faces(:, 2), :) - origin;
if size(vertices, 2) == 3
    tangents{2} = vertices(faces(:, end), :) - origin;
end
