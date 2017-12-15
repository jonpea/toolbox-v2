function varargout = parsefirst(predicate, default, n, varargin)
%PARSEFIRST Parse argument list with optional distinguished argument.
%   Detailed explanation goes here
% See also AXESCHECK, ISGRAPHICS, ISA.

narginchk(3, nargin)
nargs = numel(varargin);
assert(isscalar(n) && 0 <= n && n <= nargs)
nargoutchk(1 + n, nargout)

if ~isempty(varargin) && predicate(varargin{1})
    first = varargin{1};
    varargin(1) = []; % drop first entry
else
    first = default;
end

varargout = {
    first ...
    varargin{1 : n} ...
    varargin(n + 1 : end)
    };
