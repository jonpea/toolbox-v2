function result = isfunction(f)
%ISFUNCTION True for MATLAB functions.
%   IFFUNCTION(F) returns 1 if F is a MATLAB function and 0 otherwise.
%
%   See also ISCELL, ISNUMERIC, ISSTRUCT etc. in DATATYPES.
result = isa(f, 'function_handle');
