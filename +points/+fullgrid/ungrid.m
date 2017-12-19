function [x, y, f] = ungrid(x, y, f)
%UNGRID Converts flat data to NDGRID format.
% See also NDGRID, MESHGRID.

narginchk(3, 3)
assert(numel(x) == numel(y))
assert(numel(x) == numel(f))

% NDGRID format:
% - "x" varies down 1st dimension
% - "y" across across 2nd dimension
[success, shape] = leadingdimension(y);
if success
    x = reshape(x, shape);
    y = reshape(y, shape);
    f = reshape(f, shape);
    assert(allzero(columndiff(x)))
    assert(allzero(rowdiff(y)))
    x = x(:, 1);
    y = y(1, :).';
    return
end

% MESHGRID format:
% - "x" varies across 2nd dimension
% - "y" down 1st dimension
[success, shape] = leadingdimension(x);
if success
    x = reshape(x, shape); 
    y = reshape(y, shape); 
    f = reshape(f, shape).';
    assert(allzero(rowdiff(x)))
    assert(allzero(columndiff(y)))
    x = x(1, :).';
    y = y(:, 1);
    return
end

error('Could not convert to NDGRID format')

function [success, shape] = leadingdimension(y)
narginchk(1, nargin)
nargoutchk(0, 2)
pos = find(diff(y(:), 1, 1) ~= 0);
if isempty(pos)
    % Special case: Generated from a scalar "grid vector"
    pos = numel(y);
end
success = numel(pos) + 1 < numel(y) && all(mod(pos, pos(1)) == 0);
shape = tern(success, [pos(1), numel(y)/pos(1)], []);

function result = allzero(x)
result = all(x(:) == 0);

function d = rowdiff(x)
d = diff(x, 1, 1);

function d = columndiff(x)
d = diff(x, 1, 2);
