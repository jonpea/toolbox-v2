function tf = isfg(a)
%ISFULL True for points in full grid format.
tf = iscell(a) && all(cellfun(@isNumericVector, a));

function tf = isNumericVector(a)
tf = isnumeric(a) && isvector(a);
