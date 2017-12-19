function varargout = feval(fun, c, varargin)

import arguments.nargoutfor
import datatypes.isfunction

assert(isfunction(fun))
assert(iscell(c))

varargout = cell(1, nargoutfor(fun, nargout));
[varargout{:}] = fun(c{:}, varargin{:});
