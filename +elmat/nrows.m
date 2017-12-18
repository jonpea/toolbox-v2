function n = nrows(x)
%NROWS Number of rows.
%   N = NROWS(X) returns the number of rows in the array X.
%
%   See also ELMAT.NCOLS, NDIMS, SIZE.

n = size(x, 1);
