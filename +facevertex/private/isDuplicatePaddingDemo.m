function isDuplicatePaddingDemo

x = [ % (7 vertices)x(4 faces) 
    1 1 1 1 % #1
    1 1 1 1 % #2
    2 2 2 2 % #3
    1 1 1 1 % #4
    2 2 2 1 % #5
    3 3 2 1 % #6
    4 3 2 1 % #7
    ];
x = [x, fliplr(x)] %#ok<*NOPTS>

% Mark duplicate trailing vertices with NaN
faces = reshape(1 : numel(x), size(x));
faces(isDuplicatePadding(x)) = nan;

% NB: Transpose only *after* indices have been assigned
faces = faces' ;

% NB: Client must call fvunique to get rid of duplicates that were
% introduced by padding or otherwise. We leave this to the client 
% in case he/she needs to preserve vertex indexing.
vertices = x(:); % similarly for columns "y" and "z"

newfaces = faces;
[rows, cols] = find(isnan(faces));
assert(all(1 < cols))
assert(issorted(cols, 'ascend'))
arrayfun(@padWithDuplicates, rows, cols)
    function padWithDuplicates(row, col)
        assert(1 < col)
        newfaces(row, col) = newfaces(row, col - 1);
    end
newfaces

newa = vertices(newfaces');
assert(isequal(x, newa))

h = patch('XData', x, 'YData', x);
h.Faces

end

