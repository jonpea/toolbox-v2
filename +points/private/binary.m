function varargout = binary(fun, varargin)

import arguments.parsefirst
import datatypes.isaxes
import datatypes.isfunction
import points.components

narginchk(3, nargin)

[ax, xyz, uvw, varargin] = parsefirst(@isaxes, gca, 2, varargin{:});

assert(isfunction(fun))

xyz = components(xyz);
uvw = components(uvw);
[varargout{1 : nargout}] = feval(fun, ax, xyz{:}, uvw{:}, varargin{:});
