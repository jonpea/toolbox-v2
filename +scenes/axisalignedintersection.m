function [face, tail, t] = ...
    axisalignedintersection(lower, upper, tails, directions, limits)

narginchk(4, 5)

if nargin < 5 || isempty(limits)
    limits = 1;
end

if isscalar(limits)
    assert(0 < limits)
    limits = [0, limits];
end

% Preconditions
assert(ismatrix(lower))
assert(ismatrix(upper))
assert(isequal(size(lower), size(upper)))
assert(ismatrix(tails))
assert(size(tails, 2) == size(lower, 2))
assert(ismember(ndims(directions), 2 : 3))
assert(size(directions, ndims(directions)) == size(lower, 2))
assert(isnumeric(limits))
assert(ismember(size(limits, 1), [1, size(tails, 1)]))
assert(size(limits, 2) == 2)

% Prepare for singleton expansion
numslots = 3;
lower = reshape(lower, sxshape(lower, [1, numslots]));
upper = reshape(upper, sxshape(upper, [1, numslots]));
tails = reshape(tails, sxshape(tails, [2, numslots]));
directions = reshape(directions, sxshape(directions, [2, numslots]));

% Parameter interval for bounding box slab in each direction
    function t = parameterfor(offset)
        t = (offset - tails) ./ directions;
    end
tlower = parameterfor(lower);
tuppercopy = parameterfor(upper); % saves one copy in updates below

% Ensure that "lower" and "upper" are consistent with ray orientation
% i.e. re-ordering may be necessary, depending of location of ray tail
tupper = max(tlower, tuppercopy);
tlower = min(tlower, tuppercopy); % NB: must come second

% Update larger bound to ensure robust intersection
% See explanation in Physically Based Rendering, 3rd Edition
tupper = tupper*(1 + 2*thetabound(3));

% Compute intersection of parameter intervals
% associated with each spatial direction
% NB: Although this code would run slightly faster if we had originally
% transposed the inputs so as to min/maximize here over the leading
% dimension rather than over the trailing dimention, that arrangement
% would leave an additional empty/unsed index of size 1 in the *leading*
% position, leaving us with [~, i, j, k] = ind2sub( ... ).
% Ultimately, while neither of these two implementations is 100%
% satisfactory, the difference in performance is likely to be small.
lastdim = ndims(tlower);
assert(lastdim == numslots)
t0 = max(tlower, [], lastdim);
t1 = min(tupper, [], lastdim);

% It is cheaper to perform this restriction (involving comparison
% with a scalar) only after the preceding restriction (extremizing
% over multiple directions).
t0 = max(limits(:, 1)', t0); %#ok<UDIM>
t1 = min(limits(:, 2)', t1); %#ok<UDIM>

% Non-empty parameter interval signifies intersection
select = t0 <= t1;
indices = find(select);
[face, tail] = ind2sub(size(select), indices);
t = reshape(t0(indices), [], 1); % "empty" is 0x1

end

function gamma = thetabound(n, varargin)
%THETABOUND Finte precision bound on the exact value of |1-(1+0.5*EPS)^N|.
% This is a translation of "Float gamma(int n)" in PBRT3 by Pharr et al.
epsilon = 0.5*eps(varargin{:});
gamma = (n*epsilon)/(1 - n*epsilon);
end
