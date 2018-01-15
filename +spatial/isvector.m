function tf = isvector(c)
%ISVECTOR True for points in grid-vector format.
narginchk(1, 1)
tf = iscell(c) && all(cellfun(@(a) isnumeric(a) && isvector(a), c));
