function tf = isgv(a)
%ISGV True for points in grid-vector format.
tf = iscell(a) && all(cellfun(@isNumericVector, a));

function tf = isNumericVector(a)
tf = isnumeric(a) && isvector(a);
