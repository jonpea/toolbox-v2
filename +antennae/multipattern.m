function fun = multipattern(functions, facetofunction, context)
%MULTIPATTERN Interface for combining multiple antenna patterns.
%
%   See also ISOPATTERN.

narginchk(1, 3)

if ~iscell(functions)
    functions = {functions};
end

if nargin < 2
    assert(isscalar(functions), ...
        'Unless function list is scalar, indices must be supplied.')
    facetofunction = @(i) ones(size(i));
end

if nargin < 3
    context = @feval;
end

import datatypes.isfunction
assert(isfunction(context))
assert(iscell(functions))
assert(all(cellfun(@isfunction, functions)))
assert(all(isfunction(facetofunction) || ...
    ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)        
        assert(isvector(faceindices))
        assert(ismatrix(directions))     
        assert(numel(faceindices) == size(directions, 1))
        gain = dispatchMulti(context, functions, ...
            facetofunction(faceindices(:)), faceindices(:), directions);        
    end
fun = @evaluate;

end

% -------------------------------------------------------------------------
function result = dispatchMulti(feval, funs, funofrow, id, x)

% Construct list of rows to dispatch to each function
indicesForFun = invertIndices(funofrow, numel(funs));

% Evaluate each function precisely once
resultsForFun = cellfun(@apply, funs(:), indicesForFun(:), 'UniformOutput', false);
    function c = apply(fun, rows)
        c = feval(fun, id(rows, :), x(rows, :));
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
