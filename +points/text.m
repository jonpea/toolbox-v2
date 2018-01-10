function varargout = text(varargin)

narginchk(1, nargin)

import arguments.parsefirst
import datatypes.isaxes
[ax, xyz, varargin] = parsefirst(@isaxes, gca, 1, varargin{:});

xyz = points.components(xyz);
default = cellstr(num2str(index(xyz{1})));

[txt, varargin] = parsefirst(@iscellstr, default, 0, varargin{:});

if mod(numel(varargin), 2) == 1
   error( ...
       contracts.msgid(mfilename, 'BadOptionalPairs'), ...
       ['Options do not appear in key-value pairs:' ...
       ' Ensure that labels are provided in a cellstr.'])       
end

[varargout{1 : nargout}] = text(ax, xyz{:}, txt, varargin{:});

% -------------------------------------------------------------------------
function idx = index(x, varargin)
%INDEX Indices for first non-singleton array dimension.
dim = sx.leaddim(x);
idx = (1 : size(x, dim))';
