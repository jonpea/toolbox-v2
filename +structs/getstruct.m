function s = getstruct(s, varargin)
%GETSTRUCT Subset of the fields of a structure array.
%   SS = GETSTRUCT(S,'A','B',...) returns a structure array S 
%   comprising the subset of the fields of structure array S 
%   specified in 'A', 'B', etc.
%
%   See also SETFIELD, GETFIELD, STRUCT.

narginchk(1, nargin)
assert(iscellstr(varargin))

% This arrangement accommodates struct arrays as well as scalars
s = rmfield(s, setdiff(fieldnames(s), varargin));

% Ensure that fields appear in the order specified by client
s = orderfields(s, varargin);
