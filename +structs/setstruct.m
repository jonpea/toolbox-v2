function s = setstruct(s, varargin)
%SETSTRUCT Set fields of an existing struct.
% Example:
% >> setstruct(struct, 'Name', 'Pete', 'Age', 23, 'Height', 1.8)
% ans =
%   struct with fields:
%
%       Name: 'Pete'
%        Age: 23
%     Height: 1.8
%
% See also GETSTRUCT, SETFIELD.

assert(mod(nargin, 2) == 1, ...
    'Arguments should appear in name-value pairs')

    function set(name, value)
        s.(name) = value;
    end
cellfun(@set, varargin(1 : 2 : end - 1), varargin(2 : 2 : end))

end
