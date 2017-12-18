function w = width(t)
%WIDTH Number of variables in a table.
%   W = WIDTH(T) returns the number of variables in the table T.
%  
%   See also HEIGHT.

assert(isstruct(t))
w = numel(fieldnames(t));
