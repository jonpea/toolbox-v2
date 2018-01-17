function handle = dispatch(funList, entityToFunIdx, context)
%DISPATCH Interface for combining multiple antenna patterns.
%
%   See also ISOPATTERN, MULTIPATTERN.

narginchk(1, 3)

if ~iscell(funList)
    funList = {funList};
end
if nargin < 2 || isempty(entityToFunIdx)
    % A sensible - actually unique - possibility 
    % exists if all entities share a single pattern.
    assert(isscalar(funList), ...
        'Unless function list is scalar, indices must be supplied.')
    entityToFunIdx = @(entityIdx) ones(size(entityIdx));
end
if nargin < 3
    % Defaults to trivial context
    context = @feval; 
end

    function gain = evaluate(entityIdx, directions)
        gain = dispatchMulti(context, funList, ...
            entityToFunIdx(entityIdx(:)), entityIdx(:), directions);
    end
handle = @evaluate;

end

% -------------------------------------------------------------------------
function result = dispatchMulti(feval, funList, funIdx, entityIdx, x)

assert(isequal(numel(funIdx), numel(entityIdx)))

% Construct list of rows to dispatch to each function
indicesForFun = invertIndices(funIdx, numel(funList));

% Evaluate each function precisely once
resultsForFun = cellfun(@apply, ...
    funList(:), indicesForFun(:), 'UniformOutput', false);
    function c = apply(fun, rows)
        c = feval(fun, entityIdx(rows, :), x(rows, :));
    end

% Recombine individual result blocks in order of original arguments
result(cell2mat(indicesForFun), :) = cell2mat(resultsForFun);

end

% -------------------------------------------------------------------------
function inverted = invertIndices(indices, numgroups)
shape = [numgroups, 1];
indexrange = 1 : numel(indices);
inverted = accumarray(indices(:), indexrange(:), shape, @(a) {a(:)});
if isempty(indices)
    % Corner case: If the input list is empty, then accumarray
    % doesn't realize that the result should be a cell array (of empties)
    inverted = repmat({zeros(0, 1)}, size(inverted));
end
end
