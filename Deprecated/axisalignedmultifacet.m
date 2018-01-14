function obj = axisalignedmultifacet(lower, upper)

narginchk(1, 2)

if nargin == 1
    % Conversion from struct or patch instance
    upper = lower.Upper;
    lower = lower.Lower;
end

assert(isequal(size(lower), size(upper)))

% Normal direction is associated with edges of zero width
differences = upper - lower;
[row, column] = find(differences == 0);
assert(numel(unique(row)) == numel(row), ...
    'Each block must contain exactly one collapsed dimension')
normaldirection = accumarray(row, column);

% Tangent vectors are associated with edges of positive width
numdirections = size(lower, 2);
numtangents = numdirections - 1;
[rows, columns, signs] = find(sign(differences));
assert(all(accumarray(rows, 1) == numtangents))
counters = zeros(numel(unique(rows)), 1);
layers = zeros(size(rows));
    function cumulativecount(index, value)
        incremented = counters(value) + 1;
        layers(index) = incremented;
        counters(value) = incremented;
    end
arrayfun(@cumulativecount, 1 : numel(rows), rows(:)');
temporary = accumarray( ...
    [rows(:), columns(:), layers(:)], signs(:), ...
    [size(differences), numdirections - 1]);
tangents = num2cell(temporary, [1, 2]);
frame = fvframes(lower, tangents{:});

% Value of the fixed coordinate of offset from the origin
offset = lower(columntoindex(lower, normaldirection));
offset = offset(:);

obj.Direction = normaldirection;
obj.Offset = offset;
obj.Lower = lower;
obj.Upper = upper;
obj.Origin = lower;
obj.Frame = frame;

% Methods
obj.Project = @(varargin) project(obj, varargin{:});
obj.Intersect = @(varargin) intersect(obj, varargin{:});
% projectfun = @project;
% intersectfun = @intersect;

end

% =========================================================================
function points = project(obj, points, varargin)
%PROJECT Projection onto affine hull of facets.
narginchk(2, 3)
rows = parseindices(varargin{:});
directions = obj.Direction(rows, :);
offsets = obj.Offset(rows, :);
if isscalar(directions)
    % Employs optimal indexing
    points(:, directions) = offsets;
    return
end
% No short-cut is possible here
points(columntoindex(points, directions)) = offsets;
end

% =========================================================================
function interactions = intersect(obj, ray, varargin)
%INTERSECT Ray-facet intersection points.
narginchk(2, 3)
rows = parseindices(varargin{:});
[faceindex, rayindex, t] = ...
    axisalignedintersection( ...
    obj.Lower(rows, :), ...
    obj.Upper(rows, :), ...
    ray.Origin, ...
    ray.Direction, ...
    [ray.LowerLimit, ray.UpperLimit]);
interactions = interactionset(faceindex, rayindex, t);
interactions.Point = ...
    ray.Origin(rayindex, :) + ...
    bsxfun(@times, ray.Direction(rayindex, :), t);
end

% =========================================================================
function indices = columntoindex(like, columns)
assert(size(like, 1) == numel(columns))
indices = sub2ind(size(like), 1 : size(like, 1), columns(:)');
end
