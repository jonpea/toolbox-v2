function [indices, points] = imagemethod( ...
    intersect, mirror, sequence, xfirst, xlast)
%IMAGEMETHOD Reflection path through specified facet sequence.
% [INDICES,POINTS] = IMAGEMETHOD(@INTERSECT,@MIRROR,SEQ,XFIRST,XLAST).

import contracts.ndebug
import datatypes.isfunction

% Preconditions
narginchk(5, 5)
assert(isfunction(intersect))
assert(isfunction(mirror))
assert(isnumeric(sequence))
assert(ismatrix(xfirst) && isnumeric(xfirst))
assert(ismatrix(xlast) && isnumeric(xlast))

% Expand singletons
if size(xfirst, 1) == 1
    xfirst = repmat(xfirst, size(xlast, 1), 1);
end
if size(xlast, 1) == 1
    xlast = repmat(xlast, size(xfirst, 1), 1);
end

assert(isequal(size(xfirst), size(xlast)))

% Key dimensions
numpairs = max(size(xfirst, 1), size(xlast, 1));
numfaces = numel(sequence);

if isempty(sequence)
    % Direct rays i.e trivial paths without reflections
    indices = transpose(1 : numpairs);
    points = cat(3, ... % TODO: combine with "cat(3,...)" in imagemethod
        xfirst(indices, :), ...
        xlast(indices, :));
    return
end

% Sequence of mirror images of source point through successive facets
fwdmirror = cell(1, numfaces);
fwdmirror{1} = mirror(xfirst, sequence(1));
for i = 2 : numfaces
    fwdmirror{i} = mirror(fwdmirror{i - 1}, sequence(i));
end

% Prepare for image propagation
[points, selected] = deal(cell(1, numfaces));
filter = transpose(1 : numpairs); % no rays rejected yet
previous = fwdmirror{end};
next = xlast;

% There is a dependence between successive executions of this loop
for i = numfaces : -1 : 1
    
    % Compute intersection point at current facet
    interactions = intersect( ...
        previous, ... % ray origin
        next - previous, ... % ray direction
        sequence(i)); % face index
    assert(ndebug || all(interactions.FaceIndex == sequence(i))) % invariant
    rayid = interactions.RayIndex;
    selected{i} = rayid;
    
    assert(ndebug || ~any(structfun(@(a) any(isnan(a(:))), interactions)))
    
    % Note: It is possible to break early here if no intersections
    % exist, but doing appears to require a slightly more complex
    % implemenation without providing a meaningful reduction in work.
    
    % Store computed reflection points
    points{i} = interactions.Point;
    
    % Reject complement of selected rays
    filter = filter(selected{i});
    
    if i == 1
        % There is no need to update "previous" and "next"
        break
    end
    
    % Prepare for next facet
    previous = fwdmirror{i - 1}(filter, :);
    next = points{i};
    
end

% Invariant
assert(all(0 <= diff(cellfun(@numel, selected))))

% Discard those candidate paths that were rejected at intermediate steps
% e.g. accepated at step 1 but rejected at step N.
% This must, necessarily, be done sequentially.
indices = selected{1};
for i = 2 : numfaces
    points{i} = points{i}(indices, :);
    indices = selected{i}(indices);
end

% Convert from "{facet}(path,:)" to "(path,:,facet)"
points = cat(3, ... 
    xfirst(indices, :), ...
    points{:}, ...
    xlast(indices, :));

assert(size(points, 1) == numel(indices))
assert(size(points, 2) == size(xfirst, 2))
assert(size(points, 3) == numel(sequence) + 2) % "+2" for source & target

end
