function varargout = feval(fun, c, varargin)

assert(datatypes.isfunction(fun))
assert(iscell(c))

varargout = cell(1, arguments.nargoutfor(fun, nargout));
[varargout{:}] = fun(c{:}, varargin{:});
