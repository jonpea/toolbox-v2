function varargout = spherical(varargin)

%[ax, fun, origins, frames, varargin] = axisforplot(3, varargin{:});
[ax, fun, origins, frames, varargin] = ...
    arguments.parsefirst(@datatypes.isaxes, gca, 3, varargin{:});

% Preconditions
assert(isgraphics(ax))
assert(datatypes.isfunction(fun))
assert(ismatrix(origins))
assert(ndims(frames) == 3)
assert(ismember(size(origins, 2), 2 : 3))
assert(size(origins, 2) == size(frames, 2))
assert(size(origins, 2) == size(frames, 3))

[origins, frames] = unsingleton(origins, frames);
[numantennae, numdirections] = size(origins);

% Invariants
assert(numdirections == 3)
assert(size(frames, 1) == numantennae)
assert(size(frames, 2) == numdirections)
assert(size(frames, 3) == numdirections)

% Parse optional arguments
parser = inputParser;
parser.addParameter('Azimuth', linspace(0, 2*pi), @isvector) % default for 3D case only
parser.addParameter('Inclination', linspace(0, pi), @isvector)
parser.addParameter('Radius', @unitradius, @datatypes.isfunction)
parser.KeepUnmatched = true;
parser.parse(varargin{:})
angles = parser.Results;
options = parser.Unmatched;
if ismember('CData', fieldnames(options))
    warning([mfilename, ':CDataIsSet'], ...
        'Field ''CData'' is set but will be over-ridden.')
end

% Sampling points in local spherical coordinates...
phi = angles.Azimuth(:); % m-by-1
theta = angles.Inclination(:)'; % 1-by-n
    function handle = display(id)
        r = angles.Radius(id, phi, theta); % m-by-n
        % ... expressed in global cartesian coordinates
        [x, y, z, c] = surfdata( ...
            @(direction) fun(id, direction), ...
            origins(id, :), ...
            frames(id, :, :), ...
            phi, theta, r);
        handle = surf(ax, x, y, z, setfield(options, 'CData', c)); %#ok<SFLD>
    end
handles = arrayfun(@display, 1 : numantennae, 'UniformOutput', false);

if 0 < nargout
    varargout = {handles};
end

end

function [x, y, z, c] = surfdata(fun, origins, frames, phi, theta, r)

% Elevation from xy-plane
thetabar = pi/2 - theta;

% Direction vectors from sampling surface to local
% origin expressed in local spherical coordinates
[dx0, dy0, dz0] = sph2cart(phi, thetabar, r);
dxyz0 = [dx0(:), dy0(:), dz0(:)];

% Directions expressed in global cartesian coordinates
dxyz = globalpoints(frames, dxyz0);

shape = [numel(phi), numel(theta)];
assert(isequal(size(dx0), shape)) % invariant

% Intensities (color) values
% NB: We choose not to normalize each row of the direction vector because
% the sampling surface may contain points at the origin (e.g. a 3D plot of
% antenna lobes is likely to have points of very small or zero length).
% Normalising would introduce NaNs in this benign case.
c = reshape(fun(dxyz), shape);

% Global cartesian coordinates
% i.e. "global axes at global origin"
xyz = origins + dxyz;
    function result = globalcartesian(i)
        result = reshape(xyz(:, i), shape);
    end
x = globalcartesian(1);
y = globalcartesian(2);
z = globalcartesian(3);

end

function r = unitradius(~, azimuth, inclination)
% First input argument (unused) corresponds to "index".
import sx.sizesx
r = ones(sizesx(azimuth, inclination), 'like', azimuth);
end