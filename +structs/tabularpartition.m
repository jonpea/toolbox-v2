function [partitioned, uniquelabels] = tabularpartition(tabular, rowlabels)
%PARTITIONTABULAR Partition rows of tabular struct.
% PT=PARTITIONTABULAR(T,LABELS) with a matrix LABELS having one row for
% each rows of tabular struct T returns an array of tabular structs
% corresponding to a partition of the rows of T defined by the unique rows
% in LABELS. PT has as many entries as there are unique rows in LABELS.
%
% [PT,UNIQUELABELS] = PARTITIONTABULAR(T,LABELS) also returns the unique
% rows of LABELS.
%
% See also TABULARTOMATRIX, UNIQUE, STRUCT2TABLE.
narginchk(2, 2)
assert(isstruct(tabular))
assert(ismatrix(rowlabels))
assert(all(structfun(@(x) size(x, 1), tabular) == size(rowlabels, 1)))
numrows = size(rowlabels, 1);
allrows = 1 : numrows;
[uniquelabels, ~, blockindices] = unique(rowlabels, 'rows');
rowsets = accumarray(blockindices(:), allrows(:), [], @(i) {i});
function result = partitionrows(field)
    assert(ndims(field) <= 4)
    result = cellfun( ...
        @(rows) field(rows, :, :, :), rowsets, 'UniformOutput', false);
end
temp = structfun(@partitionrows, tabular, 'UniformOutput', false);
temp = [fieldnames(tabular), struct2cell(temp)]';
partitioned = struct(temp{:});
end
