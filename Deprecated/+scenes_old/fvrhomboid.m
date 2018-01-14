function result = fvrhomboid(faces, vertices)
%FVRHOMBOID True if all facets are rhomboid.
% FVRHOMBOID(FACES, VERTICES) returns true if all facets in the the given 
% face-vertex representation are rhomboid 
% i.e. quadrilateral with parallel opposing sides.

if size(faces, 2) ~= 4 || size(vertices, 2) ~= 3
    result = false;
    return
end

sw = vertices(faces(:, 1), :);
se = vertices(faces(:, 2), :);
ne = vertices(faces(:, 3), :);
nw = vertices(faces(:, 4), :);
result = isequalfp(nw + se, sw + ne);
