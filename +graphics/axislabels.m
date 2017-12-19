function varargout = axislabels(varargin)

import arguments.parsefirst
import datatypes.isaxes

narginchk(2, nargin)
[ax, labelx, labely, varargin] = parsefirst(@isaxes, gca, 2, varargin{:});

isThreeDimensional = mod(numel(varargin), 2) == 1;

if isThreeDimensional
    labelz = varargin{1};
    varargin(1) = [];
end

h = [
    xlabel(ax, labelx, varargin{:});
    ylabel(ax, labely, varargin{:});
    ];

if isThreeDimensional
    h(end + 1) = zlabel(ax, labelz, varargin{:});
end

[varargout{1 : nargout}] = deal(h);
