function n = ncols(varargin)
%NCOLS Number of columns.
%   NCOLS(X1,..,XN) returns the number of columns in the result 
%   of any N-ary elementwise operation between arrays X1, .., XN.
%
%   See also ELMAT.NCOLS, SX.NROWS.

n = sx.size(varargin, 2);
