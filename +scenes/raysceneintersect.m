function [faceid, rayid, point, output] = raysceneintersect( ...
    facenormal, faceoffset, facefilter, ...
    rayorigin, raydirection, tspan)

narginchk(5, 6)

% Convenient default definition for intervals of admissible ray coordinate
if nargin < 6 || isempty(tspan)
    tspan = [0, 1];
end
if isscalar(tspan)
    tspan = [0, tspan];
end

% Pre-conditions
assert(ndebug || size(facenormal, 1) == numel(faceoffset))
assert(ndebug || size(facenormal, 2) == size(rayorigin, 2))
assert(ndebug || iscolumn(faceoffset))
assert(ndebug || isfunction(facefilter))
assert(ndebug || isequal(size(rayorigin), size(raydirection)))
assert(ndebug || numel(tspan) == 2)
assert(ndebug || tspan(1) < tspan(2)) % for speed only; saves sort()

% Sanity checks
assert(ndebug || 0 <= tspan(1))
assert(ndebug || isequal(class(facenormal), class(faceoffset)))
assert(ndebug || isequal(class(facenormal), class(rayorigin)))
assert(ndebug || isequal(class(facenormal), class(raydirection)))
assert(ndebug || isequal(class(facenormal), class(tspan)))

% Evaluate ray coordinate of interesection with affine hulls
t = offsetwithbsxfun(facenormal, faceoffset, rayorigin, raydirection);
assert(ndebug || isequal(size(t), ...
    [size(facenormal, 1), size(rayorigin, 1)]))

if ~ndebug
    tt = offsetwithisx(facenormal, faceoffset, rayorigin, raydirection);
    assert(isequal(t, tt))
end

% Filter based on admissible range of ray parameter
tfilter = tspan(1) <= t & t <= tspan(2);
[tfaceid, trayid] = find(tfilter);
tfiltered = t(tfilter(:)); % "(:)" ensures "empty is a (0x1) column"

assert(iscolumn(tfaceid))
assert(iscolumn(trayid))
assert(iscolumn(tfiltered))

% Evaluate global/cartesian coordinates of admissible intersection points
point = rayorigin(trayid, :) + ...
    bsxfun(@times, raydirection(trayid, :), tfiltered);

% Filter based on admissible local/facet coordinates
[uvfilter, uv] = facefilter(tfaceid, point);
uvfilterindices = find(uvfilter); % used multiple times, so prefer indices over logical mask

% Return face indices and cartesian coordinates of intersection points
faceid = tfaceid(uvfilterindices, :);
rayid = trayid(uvfilterindices, :);
point = point(uvfilterindices, :);

if 4 <= nargout
    % NB: Store (logical) masks rather than indices so resulting
    % struct is tabular, having the same number of rows in each column
    raydata = struct( ...
        'RayCoordinate', t, ...
        'RayCoordinateFilter', tfilter);
    facedata = struct( ...
        'FaceIndex', tfaceid, ...
        'RayIndex', trayid, ...
        'FaceCoordinates', uv, ...
        'FaceCoordinatesFilter', uvfilter);
    output = struct( ...
        'RayCoordinateFilter', raydata, ...
        'FaceCoordinatesFilter', facedata);
end

% -------------------------------------------------------------------------
function t = offsetwithisx( ...
    facenormals, faceoffsets, rayorigins, raydirections)
% Candidate ray coordinates via Implicit Singleton eXpansion (since R2016b)
numslots = 3;
sxshapeface = sx.shape(facenormals, [1, numslots]);
sxshaperay = sx.shape(rayorigins, [2, numslots]);
dot = @(a, b) dotsx( ...
    reshape(a, sxshapeface), ...
    reshape(b, sxshaperay), ...
    numslots);
numerators = faceoffsets(:) - dot(facenormals, rayorigins);
denominators = dot(facenormals, raydirections);
t = numerators ./ denominators;

% -------------------------------------------------------------------------
function t = offsetwithbsxfun( ...
    facenormals, faceoffsets, rayorigins, raydirections)
% Candidate ray coordinates via BSXFUN (since R2007a)
numslots = 3;
sxshapeface = sx.shape(facenormals, [1, numslots]);
sxshaperay = sx.shape(rayorigins, [2, numslots]);
dot = @(a, b) sum(bsxfun(@times, ...
    reshape(a, sxshapeface), ...
    reshape(b, sxshaperay)), ...
    numslots);
numerators = faceoffsets(:) - dot(facenormals, rayorigins);
denominators = dot(facenormals, raydirections);
t = bsxfun(@rdivide, numerators, denominators);
