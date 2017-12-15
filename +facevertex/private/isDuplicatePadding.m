function select = isduplicatepadding(x)

narginchk(1, 1)
assert(size(x, 1) > 1)

select = x(1 : end - 1, :) == x(2 : end, :);
[rows, cols] = find(select);

% Adjust for the missing row in select
rows = rows + 1;

% Split matches in each column into separate chunks
    function chunks = chunkByColumns(values)
        chunks = accumarray(cols(:), values(:), [], @(a) {a});
    end
rowChunks = chunkByColumns(rows);
colChunks = chunkByColumns(cols);

% Filter out matches that do not correspond to 
% contiguous trailing subsequences in each column
numrows = size(x, 1);
[rowChunks, colChunks] = cellfun( ...
    @(varargin) trailingDuplicate(numrows, varargin{:}), ...
    rowChunks, colChunks, ...
    'UniformOutput', false);

% Convert chunks back to single arrays
rows = cell2mat(rowChunks);
cols = cell2mat(colChunks);

% Create logical mask that selects for trailing duplicates
shape = size(x);
select = false(shape);
select(sub2ind(shape, rows, cols)) = true;

end

% -------------------------------------------------------------------------
function [rows, cols] = trailingDuplicate(numrows, rows, cols)

if isempty(rows)
    return % nothing to be done
end

% Preconditions
assert(iscolumn(rows))
assert(isequal(size(rows), size(cols)))

% Sort in decending order of row index
[rows, permutation] = sort(rows, 'descend');
cols = cols(permutation);

% Look for contiguous trailing row indices
target = numrows - (0 : numel(rows) - 1);
select = rows(:) == target(:);
select(find(~select, 1, 'first') : end) = false;

rows(~select, :) = [];
cols(~select, :) = [];

% Postconditions
assert(iscolumn(rows))
assert(isequal(size(rows), size(cols)))

end
