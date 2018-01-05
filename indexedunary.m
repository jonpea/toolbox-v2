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
rowsoffun = invertindices(funofrow, numel(functions));
cellfun(@apply, functions(:), rowsoffun(:));

end
