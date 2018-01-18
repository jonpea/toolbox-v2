function varargout = paths(varargin)

[ax, pathpoints, varargin] = ...
    arguments.parsefirst(@datatypes.isaxes, gca, 1, varargin{:});

assert(ismember(size(pathpoints, 2), 2 : 3))
assert(ismember(ndims(pathpoints), 2 : 3))

numpaths = size(pathpoints, 3) - 1;
handles = arrayfun(@plotpath, 1 : numpaths, 'UniformOutput', false);
    function handle = plotpath(k)
        handle = points.segments(ax, ...
            pathpoints(:, :, k), ...
            pathpoints(:, :, k + 1), ...
            varargin{:});
    end

if nargout == 1
    varargout{1} = vertcat(handles{:});
end

end
