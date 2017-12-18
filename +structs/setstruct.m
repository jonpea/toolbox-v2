function s = setstruct(s, varargin)
%SETSTRUCT Set fields of an existing struct.
%
%   T = SETSTRUCT(S,'N1',V1,'N2',V2,...) sets fields N1,N2,... of
%   structure S to values V1,V2,... etc. If S is a structure array, then
%   all elements are assigned the same values.
%
%   Example:
%   >> setstruct(struct, 'Name', 'Pete', 'Age', 23, 'Height', 1.8)
%   ans =
%     struct with fields:
%
%         Name: 'Pete'
%          Age: 23
%       Height: 1.8
%
% See also GETSTRUCT, SETFIELD.

narginchk(1, nargin)
assert(mod(nargin, 2) == 1, 'Arguments should appear in name-value pairs')

    function set(name, value)
        [s.(name)] = deal(value);
    end
names = varargin(1 : 2 : end - 1);
values = varargin(2 : 2 : end);
cellfun(@set, names, values)

end
