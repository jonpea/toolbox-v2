function varargout = quiver(varargin)

[~, xyz, ~] = arguments.parsefirst(@datatypes.isaxes, gca, 1, varargin{:});

assert(ismatrix(xyz))
assert(isnumeric(xyz))
assert(ismember(size(xyz, 2), 2 : 3))

switch size(xyz, 2)
    case 2
        plotter = @quiver;
    case 3
        plotter = @quiver3;
end

[varargout{1 : nargout}] = points.binary(plotter, varargin{:});
