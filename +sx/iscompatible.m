function result = iscompatible(varargin)
%ISCOMPATIBLE True if set of arguments admits singleton expansion.
%   ISCOMPATIBLE(A,B) returns true only if A and B are
%   compatible for element-wise operations like PLUS, TIMES etc.
%
%   ISCOMPATIBLE(A1,A2,...,AN) returns TRUE only if arrays
%   A1 to AN are compatible in an N-ary elementwise operation.
%
%   ISCOMPATIBLE() and ISCOMPATIBLE(A) always return TRUE.
%
%   See also SIZE.

if nargin == 2
    % Special case:
    % A comparison of two arguments is faster than general case
    [arg1, arg2] = varargin{:};
    [size1, size2] = deal(cell(1, max(ndims(arg1), ndims(arg2)))); % pre-allocate
    [size1{:}] = size(arg1);
    [size2{:}] = size(arg2);
    size1 = cell2mat(size1);
    size2 = cell2mat(size2);
    result = all(1 == size1 | size1 == size2 | size2 == 1);
    return
end


import singletonexpansion.sizetable

% Form table of sizes and drop singleton entries
nonsingleton = sizetable(varargin{:});
nonsingleton(nonsingleton == 1) = nan;

% Ignoring singletons, the set of values in each column of the
% table of sizes should have cardinality one i.e. "min equals max".
    function result = scanColumns(fun)
        result = fun(nonsingleton, [], 1, 'omitnan');
    end
lower = scanColumns(@min);
upper = scanColumns(@max);
result = isequaln(lower, upper);

end
