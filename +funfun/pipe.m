function varargout = pipe(head, varargin)
%PIPE Function composition.
%   [Y1,Y2,..] = PIPE(OUTER,INNER,X1,X2,..) is equivalent to
%   the composition
%           [Y1,Y2,..] = OUTER(INNER(X1,X2,..)).
%
%   [Y1,Y2,..] = PIPE(OUTER,N,INNER,X1,X2,..) is equivalent to
%   the composition
%           [T1,T2,..,TN] = INNER(X1,X2,..);
%           [Y1,Y2,..] = OUTER(T1,T2,..,TN).
%
%   PIPE({F1,N1,F2,N2,...FK,NK,G},X1,X2,..) composes the inner function 
%   G and outer functions F1,..,NK with input arities N1,..,NK, respectively.
%
%   NB: This function should *not* be confused with built-in COMPOSE,
%   which converts data into formatted string arrays and has nothing 
%   to do with function composition.
%
%   Example:
%   >> theta = pi/2; r = 1.0;
%   >> [x, y] = pol2cart(theta, r);
%   >> p1 = [x, y];
%   >> p2 = funfun.pipe(@horzcat, 2, @pol2cart, theta, r);
%   >> assert(isequal(p1, p2))
%
%   See also COMPOSE.

%   Note to Maintainers:
%   The interface of this routine is consistent with that of
%   PARFEVAL in the Parallel Computing Toolbox.

narginchk(1, nargin)

if iscell(head)
    impl = @pipeMany;
    fouter = head{1};
else
    impl = @pipeTwo;
    fouter = head;
end

nout = arguments.nargoutfor(fouter, nargout);

[varargout{1 : nout}] = impl(head, varargin{:});

% -------------------------------------------------------------------------
function varargout = pipeTwo(fouter, varargin)
[numout, finner, varargin] = arguments.parsefirst(@isnumeric, 1, 1, varargin{:});
[temporary{1 : numout}] = feval(finner, varargin{:});
[varargout{1 : nargout}] = feval(fouter, temporary{:});

% -------------------------------------------------------------------------
function varargout = pipeMany(list, varargin)

assert(iscell(list))
assert(~isempty(list))

% Insert "1" between every consecutive pair of functions
% e.g. {@f, 2, @g, @h} becomes {@f, 2, @g, 1, @h}
isfun = cellfun(@datatypes.isfunction, list);
consecutive = isfun(1 : end - 1) & isfun(2 : end);
positions = find(consecutive);
defaults = cellfun(@nargin, list(positions));
defaults(defaults == -1) = 1; % most reasonable default for functions with variable argument lists
list = elmat.insert(list, 1 + positions, num2cell(defaults));

import datatypes.isfunction
assert(all(cellfun(@isfunction, list(1 : 2 : end))))
assert(all(cellfun(@(n) isnumeric(n) && isscalar(n), list(2 : 2 : end))))

fun = list(1 : 2 : end);
numout = [nargout, cell2mat(list(2 : 2 : end))];

for k = numel(fun) : -1 : 1
    varargout = cell(1, numout(k));
    [varargout{:}] = feval(fun{k}, varargin{:});
    varargin = varargout;
end
