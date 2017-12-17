function s = getstruct(s, varargin)
%GETSTRUCT Subset of the fields of a structure array.
%   SS = GETSTRUCT(S,'A','B',...) returns a structure array S 
%   comprising the subset of the fields of structure array S 
%   specified in 'A', 'B', etc.
%
%   See also SETFIELD, GETFIELD, STRUCT.

import contracts.ndebug

assert(ndebug || iscellstr(varargin))

values = cellfun(@(name) s.(name), varargin, 'UniformOutput', false);
s = cell2struct(values, varargin, 2);


