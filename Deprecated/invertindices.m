function inverted = invertindices(indices, numgroups)
narginchk(1, 2)
if nargin == 2
    shape = [numgroups, 1];
else
    shape = [];
end
indexrange = 1 : numel(indices);
inverted = accumarray(indices(:), indexrange(:), shape, @(a) {a(:)});
if isempty(indices)
    % Corner case: If the input list is empty, then accumarray 
    % doesn't realize that the result should be a cell array (of empties)
    inverted = repmat({zeros(0, 1)}, size(inverted));
end
