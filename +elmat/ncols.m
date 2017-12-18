function n = ncols(x)
%NCOLS Number of columns.
%   N = NCOLS(X) returns the number of columns in the array X.
%
%   See also ELMAT.NROWS, NDIMS, SIZE.

n = size(x, 2);
