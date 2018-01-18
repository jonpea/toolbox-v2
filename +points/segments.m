function varargout = segments(varargin)
%SEGMENTS Plot line segments.
%
% See also POINTS.QUIVER.

[ax, a, b, varargin] = ...
    arguments.parsefirst(@datatypes.isaxes, gca, 2, varargin{:});
[varargout{1 : nargout}] = points.quiver(ax, ...
    a, ... % origin
    b - a, ... % direction
    0, ... % no scaling
    varargin{:});
