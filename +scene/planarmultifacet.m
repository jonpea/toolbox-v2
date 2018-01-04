function obj = planarmultifacet(faces, vertices)

narginchk(1, 2)

if nargin == 1
    % Conversion from struct or patch instance
    assert(isstruct(faces) || isgraphics(faces))
    vertices = faces.Vertices;
    faces = faces.Faces;
end

assert(ismember(size(vertices, 2), 2 : 3))
assert(ismember(size(faces, 2), [2, 4]))

[origin, tangents] = fvtotangents(faces, vertices);
[frame, map, normal, offset] = fvframes(origin, tangents{:});

% Tabular struct
obj.Origin = origin;
obj.UnitNormal = normal;
obj.UnitNormalOffset = offset;
obj.OffsetToEdgeMap = map;
obj.Frame = frame;
obj.NumFacets = size(faces, 1);

% These fields should eventually be removed
obj.Private.Faces = faces;
obj.Private.Vertices = vertices;

% Methods
obj.Intersect = @(varargin) intersectpaths(obj, varargin{:});
obj.IntersectFacet = @(varargin) intersect(obj, varargin{:});
obj.Mirror = @(varargin) mirror(obj, varargin{:});
%obj.Project = @(varargin) project(obj, varargin{:});

% =========================================================================
function hits = intersectpaths(obj, origins, directions, faceindices)
narginchk(4, 4)
assert(ndebug || isequal(size(origins), size(directions)))
assert(ndebug || size(origins, 3) == numel(faceindices) + 1)
faceidtoignore = reflectionsegments(faceindices);
numsegments = numel(faceindices) + 1;
for i = 1 : numsegments
    hits(i) = intersectscene( ...
        obj, ...
        origins(:, :, i), ...
        directions(:, :, i), ...
        faceidtoignore{i}); %#ok<AGROW>
    hits(i).SegmentIndex(:) = i; %#ok<AGROW>
end
hits = tabularvertcat(hits);

% =========================================================================
function interactions = intersectscene(obj, origin, direction, ignore)
narginchk(3, 4)
if nargin < 4
    ignore = [];
end
numfaces = size(obj.Origin, 1);
faceid = 1 : numfaces;
faceid(ignore) = []; % faster than "setdiff" for (sorted) 1:N
interactions = intersect(obj, origin, direction, faceid);

% =========================================================================
function interactions = intersect(obj, origin, direction, faceid)
%INTERSECT Ray-facet intersection points.

narginchk(4, 4)

tnear = 0.0;
tfar = 1.0;

[faceindex, rayindex, t, point, beta] = ...
    planarintersection( ...
    obj.Origin(faceid, :), ...
    obj.UnitNormal(faceid, :), ...
    obj.OffsetToEdgeMap(faceid, :, :), ...
    origin, ...
    direction, ...
    tnear, ...
    tfar);

faceid = faceid(:); % Ensure that indexing produces column vector
interactions = struct( ...
    'RayIndex', rayindex(:), ...
    'SegmentIndex', zeros(size(rayindex)), ... % TODO: Best assigned in caller
    'FaceIndex', faceid(faceindex(:), 1), ...
    'Point', point, ...
    'RayParameter', t(:), ...
    'FaceCoordinates', beta);

% =========================================================================
function points = mirror(obj, points, varargin)
%MIRROR Mirror point relative to affine hull of face.

% Workings:
% m = p + (p - x) = 2*p - x ... mirror m, projection p, arbitrary x
% p = x + offset*n ... offset as in projection calculation
% m = 2*(x + offset*n) - x = x + 2*offset*n
narginchk(2, 3)
faceid = parseindices(varargin{:});
n = obj.UnitNormal(faceid, :);
c = obj.UnitNormalOffset(faceid, :);
assert(ndebug || ismember(numel(c), [1, size(points, 1)]))
dotproduct = sum(bsxfun(@times, n, points), 2);
offset = bsxfun(@minus, c, dotproduct);
points = points + bsxfun(@times, n, 2*offset);

% =========================================================================
% function points = project(obj, points, varargin)
% %PROJECT Projection onto affine hull of face.
%
% % Workings:
% % p = x + offset*n ... arbitrary x, projection p, scalar offset, normal n
% % n.p = n.(x + offset*n) = n.x + offset = c ... since n.n = 1
% % offset = c - n.x
% % p = x + offset*n
% narginchk(2, 3)
% faceid = parseindices(varargin{:});
% n = obj.UnitNormal(faceid, :);
% c = obj.UnitNormalOffset(faceid, :);
% assert(ndebug || ismember(numel(c), [1, size(points, 1)]))
% dotproduct = sum(bsxfun(@times, n, points), 2);
% offset = bsxfun(@minus, c, dotproduct);
% points = points + bsxfun(@times, n, offset);
