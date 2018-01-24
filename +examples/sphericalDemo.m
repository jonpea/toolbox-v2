clear

[azimuth, inclination] = sx.meshgrid( ...
    linspace(0, pi/2, 5), ...
    linspace(0, pi/2, 5));

axis1 = matfun.unit([ 1  1  1]);
axis2 = matfun.unit([-1  1  0]);
axis3 = specfun.cross(axis1, axis2);
frame = cat(3, axis1, axis2, axis3);
origin = [1 1 1];
zero = [0 0 0];

[u, v, w] = specfun.usphi2cart(azimuth, inclination);
uvw = points.meshpoints(u, v, w);

newaxes = graphics.tabbedaxes( ...
    clf(figure(1), 'reset'), 'Name', mfilename, 'NumberTitle', 'off');

%%
ax = newaxes('Local coordinates');
hold(ax, 'on')
points.quiver(ax, zero, uvw, 'k')
graphics.axislabels(ax, 'u', 'v', 'w')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

%%
xyz = points.cart.local2global(frame, uvw);

%%
ax = newaxes('Global coordinates');
hold(ax, 'on')
points.quiver(ax, zero, xyz, 'k')
points.quiver(ax, zero, axis1, 'r')
points.quiver(ax, zero, axis2, 'g')
points.quiver(ax, zero, axis3, 'b')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

%%
[azimuth, inclination] = sx.ndgrid(linspace(0, pi, 50), linspace(0, pi/2, 25));
pattern = sx.expand(sin(inclination), azimuth);
interpolant = griddedInterpolant({azimuth, inclination}, pattern);
whos azimuth inclination pattern
disp(interpolant)

%%
ax = newaxes('Pattern (sphi)');
mesh(ax, azimuth, inclination, pattern')
graphics.axislabels(ax, '\phi', '\theta')
axis(ax, 'tight')
view(ax, 2)

%%
ax = newaxes('Pattern (cart)');
hold(ax, 'on')
points.quiver(ax, zero, xyz, 'k')
points.quiver(ax, zero, axis1, 'r')
points.quiver(ax, zero, axis2, 'g')
points.quiver(ax, zero, axis3, 'b')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

[u, v, w] = specfun.usph2cart(azimuth, inclination);
uvw = points.meshpoints(u, v, w);
xyz = points.cart.local2global(frame, uvw);
fun = antennae.dispatch( ...
    interpolant, 1, antennae.orthocontext(frame, @specfun.cart2uqsphi));
r = reshape(fun(ones(size(xyz, 1), 1), xyz), size(u));
component = @(i) reshape(xyz(:, i), size(u));
x = component(1);
y = component(2);
z = component(3);
surf(ax, x, y, z, 'CData', r, 'EdgeAlpha', 0.1)

%%
ax = newaxes('Lobes');
hold(ax, 'on')
points.quiver(ax, zero, axis1, 'r')
points.quiver(ax, zero, axis2, 'g')
points.quiver(ax, zero, axis3, 'b')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

s = r./max(r(:));
surf(ax, s.*x, s.*y, s.*z, 'CData', r, 'EdgeAlpha', 0.1)


% -------------------------------------------------------------------------
function [x, y, z] = local2global(varargin)
assert(ismember(nargin, 4, 6))
assert(nargout <= nargin/2)
switch nargin
    case 4
        [x, y] = transform2d(varargin{:});
    case 6
        [x, y, z] = transform3d(varargin{:});
end
    function [x, y] = transform2d(a, b, u, v)
        x = a.*u + b.*v;
    end
    function [x, y] = transform3d(a, b, c, u, v, w)
        x = a.*u + b.*v + c.*w;
    end
end
