function varargout = parsefirst(predicate, default, n, varargin)
%PARSEFIRST Parse argument list with optional distinguished argument.
%   [FIRST,A1,...,AN,REST] = PARSEFIRST(FUN,DEFAULT,N,ARGS{:}) parses the
%   arguments given in ARGS.
%
%   FUN is a unary logical-valued function handle;
%   DEFAULT is an arbitrary value;
%   N is a non-negative integer-valued scalar;
%
%   If ARGS is not empty and FUN(ARGS{1}) is TRUE, thet:
%           FIRST is ARGS{1}
%        A1,...AN is ARGS{2},...,ARGS{N+1}
%            
%   Otherwise:
%           FIRST is DEFAULT
%        A1,...AN is ARGS{1},...,ARGS{N}
%
%   Example:
%   function myplot(varargin)
%     % Assign GCA to AX unless specified as first input argument
%     [ax, x, y, varargin] = parsefirst(@isaxes, gca, 2, varargin);
%     ...
%   end
%
%   See also ISGRAPHICS, INPUTPARSER, ISA, ISAXES.

narginchk(3, nargin)
nargs = numel(varargin);
assert(isscalar(n) && 0 <= n && n <= nargs)
nargoutchk(1 + n, nargout)

if ~isempty(varargin) && testAll(predicate, varargin{1})
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

function tf = testAll(predicate, x)
temp = predicate(x);
tf = all(temp(:));
