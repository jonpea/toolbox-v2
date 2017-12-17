function result = tabularsize(tabular, dim)
%TABULARSIZE Size of a tabular struct.
% TABULARSIZE(T) returns the number of rows in tabular struct T.
% TABULARSIZE(T,DIM) for DIM>1 returns an array whose elements are the
% result of calling SIZE(..,DIM) on each column of T.
narginchk(1, 2)
assert(ndebug || istabular(tabular))
if nargin < 2
    dim = 1;
end
assert(ndebug || isscalar(dim))
result = structfun(@(a) size(a, dim), tabular);
if isempty(result)
    % Special case: tabular struct has no fields
    result = 0; 
    return
end
if dim == 1
    result = unique(result);
    assert( ...
        isscalar(result) || ...
        (numel(result) == 2 && ismember(1, result)), ...
        'Row sizes must be uniform and/or singleton')
    if numel(result) == 2
        result = result(result ~= 1);
    end
end
