function varargout = unary(fun, varargin)

import arguments.parsefirst
import datatypes.isaxes
import datatypes.isfunction
import points.components;

narginchk(2, nargin)
assert(isfunction(fun))

[ax, xyz, varargin] = parsefirst(@datatypes.isaxes, gca, 1, varargin{:});

xyz = components(xyz);
[varargout{1 : nargout}] = feval(fun, ax, xyz{:}, varargin{:});
