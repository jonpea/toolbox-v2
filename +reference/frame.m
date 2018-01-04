function [origin, normal, map] = frame(face, vertices)

narginchk(2, 2)
assert(isrow(face))
assert(ismember(size(face, 2), 2 : 4))
assert(ismatrix(vertices))
assert(ismember(size(vertices, 2), 2 : 3))

[origin, tangents] = fvtangents(face, vertices);

numdimensions = size(vertices, 2);

% An economy-sized QR decomposition to preserve control
% of the orientation of the normal vector (that would be computed
% up-to-unknown-sign in the final column of the comple QR decomposition).
[q, r] = qr(tangents', 0);

% Workings:
% T := tangents'
% p(:) = T*alpha(:) = (Q*R)*alpha(:)
% --> alpha(:) = inv(Q*R)*p(:) = inv(R)*Q'*p(:)
% --> alpha(:)' = p(:)'*(inv(R)*Q')' = p(:)'*(Q/R')
map = reshape(q/r', 1, numdimensions, []);

individualtangents = num2cell(tangents, 2);
normal = unitrows(perp(individualtangents{:})); % unit normal vector

% ========================================================================
function [origin, tangents] = fvtangents(indices, vertices)
%FVTOTANGENTS Origin and spanning tangents for affine facets.
narginchk(2, 2)
assert(size(indices, 1) == 1)
origin = vertices(indices(:, 1), :);
switch numel(indices)
    case 2
        axial = 2; % line segments in R^2
    case 3
        axial = [2, 3]; % triangles in R^3
    case 4
        axial = [2, 4]; % quadrilaterals in R^2
end
tangents = vertices(indices(:, axial), :) - origin;

% -------------------------------------------------------------------------
function c = perp(a, b)
narginchk(1, 2)
assert(numel(a) == nargin + 1)
switch numel(a)
    case 2
        c = cross([unit(a), 0], [0 0 1]); % embed in R^3
        c(3) = []; % exact projection back to R^2
    case 3
        c = cross(unit(a), unit(b));
end

% -------------------------------------------------------------------------
function v = unit(v)
assert(isvector(v))
v = v/norm(v);
