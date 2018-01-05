function varargout = polar(varargin)
%POLAR Polar plot on arbitrary Cartesian axes.
%
%   Unlike POLARPLOT, ordinary Axes (rather than PolarAxes) are employed.
%   It is not possible to create a POLARPLOT in Cartesian Axes.
%
%   See also POLARPLOT.

[ax, fun, origins, frames, varargin] = ...
    arguments.parsefirst(@datatypes.isaxes, gca, 3, varargin{:});

assert(isgraphics(ax))
assert(datatypes.isfunction(fun))
assert(ismember(size(origins, 2), 2 : 3))
assert(size(origins, 2) == size(frames, 2))
assert(size(origins, 2) == size(frames, 3))

switch size(origins, 2)
    case 2
        defaultplotter = @plot; % @plot | @scatter
    case 3
        defaultplotter = @plot3; % @plot3 | @scatter3
end

parser = inputParser;
parser.addParameter('Azimuth', openlinspace(0, 2*pi), @isvector) % default for 3D case only
parser.addParameter('Inclination', openlinspace(0, pi), @isvector)
parser.addParameter('Radius', 1.0, @(r) isscalar(r) && 0 < r)
parser.addParameter('Plotter', defaultplotter, @isfunction)
parser.KeepUnmatched = true;
parser.parse(varargin{:})
angles = parser.Results;
options = parser.Unmatched;

assert(datatypes.isfunction(fun))
assert(ismatrix(origins))
assert(ndims(frames) == 3)
assert(isvector(angles.Azimuth))

[origins, frames] = unsingleton(origins, frames);
[numantennae, numdirections] = size(origins);
assert(size(frames, 1) == numantennae)
assert(size(frames, 2) == numdirections)
assert(size(frames, 3) == numdirections)

switch numdirections
    case 2
        assert(ismember('Inclination', parser.UsingDefaults))
        angles = rmfield(angles, 'Inclination');
        run = @run2d;
    case 3
        assert(isvector(angles.Inclination))
        run = @run3d;
end

handles = run(ax, fun, origins, frames, angles, options);
if 0 < nargout
    varargout = {handles};
end

end

% -------------------------------------------------------------------------
function handles = run2d(ax, fun, origins, frames, angles, options)

handles = arrayfun(@display, 1 : size(origins, 1), 'UniformOutput', false);

    function handle = display(id)
        
        function direction = transform(radius)
            % Transform radius for each angle to associated
            % cartesian vector with respect to the global coordinate frame
            % based at the antenna
            [temp{1 : 2}] = pol2cart(angles.Azimuth(:), radius);
            direction = globalpoints(frames(id, :, :), [temp{:}]);
        end
        
        % Free cartesian vectors from antenna base to
        % (portion of) the unit circle centred there
        circle = transform(angles.Radius);
        
        % Evauate target function on global direction vectors
        radius = fun(id, circle);
        radius = abs(radius); % TODO: Is this sensible?
        
        % Evaluate contours in global
        % coordinate frame based now at the global origin
        points = origins(id, :) + transform(radius);
        
        handle = angles.Plotter(ax, ...
            points(:, 1), points(:, 2), options);
        
    end

end

% -------------------------------------------------------------------------
function handles = run3d(ax, fun, origins, frames, angles, options)

assert(~ismember('CData', fieldnames(options)), ...
    'Field ''CData'' will be over-ridden so must not be set')

[inclinationgrid, azimuthgrid] = ...
    meshgrid(angles.Inclination, angles.Azimuth);

handles = arrayfun(@displaycontours, 1 : size(origins, 1), 'UniformOutput', false);

    function handle = displaycontours(id)
        
        % Global coordinate frame (unspecified base point)
        function direction = globaldirection(varargin)
            direction = globalpoints(frames(id, :, :), gridtopoints(varargin{:}));
        end
        
        % (Free) cartesian vectors pointing from the origin of the local
        % coordinate frame to points on the "unit" sphere (scaled to any
        % radius) centered there
        unitradius = repmat(angles.Radius, size(angles.Azimuth(:)));
        [directionslocal{1 : 3}] = sph2cart( ...
            angles.Azimuth(:), ...
            pi/2 - angles.Inclination(:)', ... % i.e. angle of elevation
            unitradius);
        gridshape = size(directionslocal{1});
        
        % The same "unit" sphere in the standard/global cartesian
        % coordinate frame based at the antenna
        directions = globaldirection(directionslocal);
        
        % Evaluate target function on global direction vectors
        radial = reshape(fun(id, directions), gridshape);
        radial = abs(radial); % TODO: Is this sensible?
        
        % Evaluate "planar contours" from (3D) radial values
        % NB: The original radius is employed in the horizontal plane
        % i.e. this is not an orthogonal projection onto the plane
        contourslocal = {
            radial .* cos(azimuthgrid)
            radial .* sin(azimuthgrid)
            cos(inclinationgrid) % height of slice through unit sphere
            };
        
        contours = origins(id, :) + globaldirection(contourslocal);
        
        handle = plot3(ax, extract(1), extract(2), extract(3), '-', options);
        function result = extract(i)
            result = reshape(contours(:, i), gridshape);
        end
        
    end

end

% -------------------------------------------------------------------------
function x = openlinspace(a, b)
% To eliminate singularities at extremes of angular coordinates
delta = sqrt(eps(class(a)))*(b - a);
x = linspace(a + delta, b - delta);
end

% -------------------------------------------------------------------------
function result = gridtopoints(varargin)
%GRIDTOPOINTS Convert grid matrices to a single matrix of points.
% See also MESHGRID, NDGRID.
narginchk(1, nargin)
if iscell(varargin{1})
    % Accept a cell array or multiple matrices
    assert(nargin == 1)
    varargin = varargin{1};
end
shape = size(varargin{1});
assert(all(cellfun(@(a) isequal(size(a), shape), varargin)))
varargin = cellfun(@(x) x(:), varargin, 'UniformOutput', false);
result = horzcat(varargin{:});
end
