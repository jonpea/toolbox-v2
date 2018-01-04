function [success, points] = imagemethod(xfirst, xlast, normals, offsets)
%IMAGEMETHOD Reflection path through specified facet sequence.
% [INDICES,POINTS] = IMAGEMETHOD(@INTERSECT,@MIRROR,SEQ,XFIRST,XLAST)
% where
%  INTERSECT(ORIGIN,DIRECTION,TNEAR,TFAR,FACEID) computes the
%  XFIRST and XLAST have identical sizes
%  XFIRST(I,:) are coordinates of the origin of the (I)th pairing
%  XLAST(I,:) are coordinates of the terminus of the (I)th pairing

% Preconditions
narginchk(4, 4)
assert(isvector(xfirst))
assert(isvector(xlast))
assert(isequal(size(xfirst), size(xlast)))
assert(isequal(class(xfirst), class(xlast)))
assert(ismatrix(normals))
assert(isvector(offsets))
assert(size(normals, 1) == size(offsets, 1))
assert(size(normals, 2) == numel(xfirst))
assert(isequal(class(normals), class(xfirst)))
assert(isequal(class(offsets), class(xfirst)))

    function m = mirror(x, id)
        m = reference.mirror(x, normals(id, :), offsets(id));
    end

xfirst = xfirst(:)';
xlast = xlast(:)';

sequence = 1 : size(normals, 1);

% Key dimensions
numpairs = 1;
numfaces = numel(sequence);

if isempty(sequence)
    % Direct rays i.e trivial paths without reflections
    success = true;
    points = cat(3, xfirst, xlast);
    return
end

% Sequence of mirror images of source point through successive facets
fwdmirror = cell(1, numfaces);
fwdmirror{1} = mirror(xfirst, sequence(1));
for i = 2 : numfaces
    fwdmirror{i} = mirror(fwdmirror{i - 1}, sequence(i));
end

% Prepare for image propagation
points = cell(1, numfaces);
next = xlast;
previous = fwdmirror{end};

% There is a dependence between successive executions of this loop
for i = numfaces : -1 : 1
    
    % Compute intersection point at current facet
    [success, points{i}] = intersect( ...
        previous, ... % ray origin
        next - previous, ... % ray direction
        0.0, 1.0, ... % limits on ray parameter
        sequence(i)); % face index
    
    if ~success || i == 1
        % There is no need to update "previous" and "next"
        break
    end
    
    % Prepare for next facet
    previous = fwdmirror{i - 1};
    next = points{i};
    
end

end
