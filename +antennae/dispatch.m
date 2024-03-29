function handle = dispatch(funList, entityToFunIdx, context)
%DISPATCH Uniform interface to multiple functions.
%   H = DISPATCH({F1,..,FM},MAP,CONTEXT) where 
%      F1,..,FM are callable entities (typically function handles) with
%         identical argument lists,
%      MAP is an array of indices of any length, each in the range [1,M],
%      and 
%      CONTEXT is a function handle that accepts 
%            an element F of F1,..,FM, 
%            an element ID of MAP, and
%            a matrix X of global Cartesian coordinates with each row
%            corresponding to a single direction vector
%         and returns the value F associates with entity ID and direction
%         X - after appropriate coordinate transformation.
%
%   DISPATCH({F1,..,FM},MAP) uses @FEVAL for CONTEXT
%   i.e. each function F1,..,FM must have signature (ID,X).
%
%   DISPATCH({F1}) uses MAP that is identically one.
%
%   DISPATCH(F1,..) is equivalent to DISPATCH({F1},..).
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
        if isscalar(entityIdx)
            % Duplicate singleton entity index over directions
            entityIdx = repmat(entityIdx, size(directions, 1), 1);
        end
        if isrow(directions)
            % Duplicate singleton direction over entities
            directions = repmat(directions, numel(entityIdx), 1);
        end
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
