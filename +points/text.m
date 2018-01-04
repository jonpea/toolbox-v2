function varargout = text(varargin)

import arguments.parsefirst
import datatypes.isaxes
import elmat.index
import points.components;

narginchk(1, nargin)

[ax, xyz, varargin] = parsefirst(@isaxes, gca, 1, varargin{:});

xyz = components(xyz);
default = cellstr(num2str(index(xyz{1})));

[txt, varargin] = parsefirst(@iscellstr, default, 0, varargin{:});

if mod(numel(varargin), 2) == 1
   error( ...
       contracts.msgid(mfilename, 'BadOptionalPairs'), ...
       ['Options do not appear in key-value pairs:' ...
       ' Ensure that labels are provided in a cellstr.'])       
end

[varargout{1 : nargout}] = text(ax, xyz{:}, txt, varargin{:});
