function subs = imagemethodsequence(ind, n, d)
%IMAGEMETHODSEQUENCE Candidate facet sequence subscripts from index.
% SUBSCRIPTS = IMAGEMETHODSEQUENCE(INDEX, NUMFACES, NUMSUBSCRIPTS) returns
% the sequence of

narginchk(3, 3)
assert(isscalar(n))
assert(isscalar(d))
assert(all(1 <= ind & ind <= rayoptics.imagemethodcardinality(n, d)))
%#ok<*DEFNU>
subs = imagemethodsequenceVersion2(ind, n, d); % fastest (~6 sec)
%subs = imagemethodsequenceVersion1(ind, n, d); % very slow (~15 sec)
end

% -------------------------------------------------------------------------
function subs = imagemethodsequenceVersion2(ind, n, d)

if d == 0
    % Trivial case requires no work
    subs = [];
    return
end

% "cardinality(K)" is the cardinality of the
% set of values taken by the Kth loop variable
% e.g. in the case d = 3,
%  for i = 1 : n
%      for j = setdiff(1 : n, i)
%          for k = setdiff(1 : n, j)
% the cardinalities are [n, n-1, n-1] for (i, j, k).
cardinalities = [n, repmat(n - 1, 1, d - 1)];

% "stepsizes(K)" is the change in linear index
% associated with an increment of 1 in the Kth loop variable
% e.g. in the case d = 3, as above:
% the step sizes are [(n-1)*(n-1), n-1, 1] for (i, j, k).
stepsizes = [fliplr(cumprod(fliplr(cardinalities(2 : end)))), 1];

% Returns the next subscript, assuming that
% start with the outermost loop and work inwards.
    function [ind, sub] = update(k, ind)
        sub = 1 + floor((ind - 1)/stepsizes(k));
        ind = ind - (sub - 1)*stepsizes(k);
    end

% Preallocate array of subscripts
subs = zeros(numel(ind), d);

% Range of outermost loop is contiguous (no jumps)
[ind, subs(:, 1)] = update(1, ind(:));

% Each inner loops involves one jump
for k = 2 : d
    [ind, sub] = update(k, ind);
    % Subscript "jumps" when it reaches that of enclosing loop
    jump = subs(:, k - 1) <= sub; % 0 or 1 (logical)
    subs(:, k) = sub + jump; % implicit cast from logical to numeric
end

end

% -------------------------------------------------------------------------
function subs = imagemethodsequenceVersion1(ind, n, d)
cardinalities = [n, repmat(n - 1, 1, d - 1)];
stepsizes = [fliplr(cumprod(fliplr(cardinalities(2 : end)))), 1];
ind = ind(:);
subs = zeros(numel(ind), d);
arrayfun(@updateresult, 1 : d);
    function updateresult(k)
        sub = 1 + floor((ind - 1)/stepsizes(k));
        ind = ind - (sub - 1)*stepsizes(k);
        if 1 < k
            sub = sub + (subs(:, k - 1) <= sub);
        end
        subs(:, k) = sub;
    end
end
