function varargout = scatter(varargin)

[~, xyz, ~] = arguments.parsefirst(@datatypes.isaxes, gca, 1, varargin{:});

assert(ismatrix(xyz))
assert(isnumeric(xyz))
assert(ismember(size(xyz, 2), 2 : 3))

switch size(xyz, 2)
    case 2
        plotter = @scatter;
    case 3
        plotter = @scatter3;
end

[varargout{1 : nargout}] = unary(plotter, varargin{:});

