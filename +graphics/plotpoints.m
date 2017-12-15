function varargout = plotpoints(varargin)

[ax, points, varargin] = axisforplot(1, varargin{:});

assert(ismember(size(points, 2), 2 : 3))
assert(ismatrix(points))

switch size(points, 2)
    case 2
        plotter = @plot;        
    case 3
        plotter = @plot3;
end

points = num2cell(points, 1);
[varargout{1 : nargout}] = plotter(points{:}, varargin{:}, 'Parent', ax);

% -------------------------------------------------------------------------
% Initial attempt at support for series of points in 3D arrays
% if ~ismatrix(points)
%     cleaner = setsafely(ax, 'NextPlot', 'add'); %#ok<NASGU>
%     handles = cellfun( ...
%         @(p) plotpoints(ax, p, varargin{:}), ...
%         matrixslices(points), ...
%         'UniformOutput', false);
%     if 0 < nargout
%         varargout{1} = reshape([handles{:}], size(points));
%     end
%     return
% end

