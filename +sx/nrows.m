function n = nrows(varargin)
%NROWS Number of rows.
%   NROWS(X1,..,XN) returns the number of rows in the result 
%   of any N-ary elementwise operation between arrays X1, .., XN.
%
%   See also ELMAT.NROWS, SX.NCOLS, SIZE.

n = sx.size(varargin, 1);
