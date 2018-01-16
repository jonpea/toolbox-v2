function varargout = pipe(varargin)
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
%   PIPE({FK,NK,...F1,N1,F0,X1,X2,..) composes the inner function 
%   F0 and outer functions F1,..,FK with input arities N1,..,NK,
%   respectively, cf. "FK(... F1(F0(X1,X2,..)))".
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

import datatypes.isfunction

if iscell(varargin{1})
    % General form: Accommodating a function handle in the 
    % "argument list" i.e. one that is not part of the composition
    list = varargin{1};
    varargin(1) = [];
else
    % Fluent form: No cell  braces required in the common case that 
    % the first element in the argument list is not a function handle
    last = find(cellfun(@isfunction, varargin), 1, 'last');
    assert(~isempty(last))
    list = varargin(1 : last);
    varargin = varargin(last + 1 : end);
end

if isempty(list) || ~all(cellfun(@isfunction, list([1, end])))
    error(contracts.msgid(mfilename, 'BadFunctionList'), ...
        'First argument must be a function handle or a cell array')
end

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
