function [edge1, edge2, origin] = fvtangents(faces, vertices)
facevertices = @(i) vertices(faces(:, i), :);
origin = facevertices(1);
edge1 = facevertices(2) - origin;
edge2 = facevertices(size(faces, 2)) - origin;
