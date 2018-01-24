function result = indexedunary(functions, funofrow, x, varargin)
%INDEXEDUNARY Evaluate functionals of one row-indexed argument.

narginchk(3, nargin)

import contracts.ndebug
assert(ndebug || iscell(functions))
if isscalar(funofrow)
    funofrow = repmat(funofrow, size(x, 1), 1);
end
assert(ndebug || size(x, 1) == numel(funofrow))
assert(ndebug || ndims(x) <= 4)

result = zeros(size(x, 1), 1);
    function apply(fun, rows)
        result(rows, :) = fun(x(rows, :, :, :), varargin{:});
    end
rowsoffun = invertIndices(funofrow, numel(functions));
cellfun(@apply, functions(:), rowsoffun(:));

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
