%% Demonstation of antennae configuration and visualization

%% Prepare workspace and figure
clear % workspace
newAxes = graphics.tabbedaxes( ...
    clf(figure(1), 'reset'), ...
    'Name', mfilename, ...
    'NumberTitle', 'off');
tol = 1e-14;
zero = [0 0 0]; % "global origin"

%% Define two local coordinate systems
% The local coordinate axes and origin are expressed in global Cartesian
% coordinates
axis1 = matfun.unit([1  -1  0]);
axis2 = matfun.unit([1  1  1]);
axis3 = specfun.cross(axis1, axis2);
frame1 = cat(3, axis1, axis2, axis3);
frameMatrix1 = [axis1; axis2; axis3];
origin1 = [0 2 1]; % "local origin"

axis1 = matfun.unit([1  0 -1]);
axis2 = matfun.unit([1  1  1]);
axis3 = specfun.cross(axis1, axis2);
frame2 = cat(3, axis1, axis2, axis3);
frameMatrix2 = [axis1; axis2; axis3];
origin2 = [2 1 0]; % "local origin"

%% Gain patterns
gain1 = @(az, inc) sin(inc).*exp(cos(3*az))/3;
gain2 = @(az, inc) 0.75*sx.expand(sin(inc), az);

%% Patterns in local coordinates
delta = 1e-2;
[az, inc] = sx.meshgrid( ...
    linspace(0, 4/3*pi, 30), ...
    linspace(delta, pi - delta, 30)); % avoid singularity at "0 == pi"
[u1, v1, w1] = specfun.sphi2cart(az, inc, gain1(az, inc));
[u2, v2, w2] = specfun.sphi2cart(az, inc, gain2(az, inc));

ax = newAxes('Gain 1 (local)');
hold(ax, 'on')
surf(ax, u1, v1, w1, 'EdgeAlpha', 0.1, 'FaceAlpha', 1.0)
points.quiver(ax, zero, [1 0 0], 0, 'Color', 'red')
points.quiver(ax, zero, [0 1 0], 0, 'Color', 'green')
points.quiver(ax, zero, [0 0 1], 0, 'Color', 'blue')
graphics.axislabels(ax, 'u', 'v', 'w')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 35, 35)

%%
ax = newAxes('Gain 2 (local)');
hold(ax, 'on')
surf(ax, u2, v2, w2, 'EdgeAlpha', 0.1, 'FaceAlpha', 1.0)
points.quiver(ax, zero, [1 0 0], 0, 'Color', 'red')
points.quiver(ax, zero, [0 1 0], 0, 'Color', 'green')
points.quiver(ax, zero, [0 0 1], 0, 'Color', 'blue')
graphics.axislabels(ax, 'u', 'v', 'w')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 35, 35)

%% Gain patterns in global coordinates
ax = newAxes('Global coordinates');
hold(ax, 'on')
rotate3d(ax, 'on')

points.text(ax, zero, '0')
points.quiver(ax, zero, origin1, 0, 'Color', 'black')
points.quiver(ax, origin1, frameMatrix1(1, :), 0, 'Color', 'red')
points.quiver(ax, origin1, frameMatrix1(2, :), 0, 'Color', 'green')
points.quiver(ax, origin1, frameMatrix1(3, :), 0, 'Color', 'blue')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

points.text(ax, origin1 + frameMatrix1(1, :), 'e_1')
points.text(ax, origin1 + frameMatrix1(2, :), 'e_2')
points.text(ax, origin1 + frameMatrix1(3, :), 'e_3')

[x, y, z] = elmat.local2global(origin1, frameMatrix1, u1, v1, w1);
mesh(ax, x, y, z)

uvw = [u1(:), v1(:), w1(:)];
xyz = origin1 + points.cart.local2global(cat(3, frameMatrix1(1, :), frameMatrix1(2, :), frameMatrix1(3, :)), uvw);
% points.plot(xyz, '.')

[uu, vv, ww] = elmat.global2local(origin1, frameMatrix1, x, y, z);

assert(norm([x(:), y(:), z(:)] - xyz, inf) < tol)
assert(norm([uu(:), vv(:), ww(:)] - uvw, inf) < tol)
assert(norm(points.cart.global2local(cat(3, frameMatrix1(1, :), frameMatrix1(2, :), frameMatrix1(3, :)), xyz - origin1) - uvw, inf) < tol)

directions1 = matfun.unit([x(:), y(:), z(:)] - origin1, 2);
frames = repmat(cat(3, frameMatrix1(1, :), frameMatrix1(2, :), frameMatrix1(3, :)), size(directions1, 1), 1, 1);
uvw = points.cart.global2local(frames, directions1);
[azimuth, inclination] = specfun.cart2sphi(uvw(:, 1), uvw(:, 2), uvw(:, 3));
radius = gain1(azimuth, inclination);
points.plot(origin1 + radius.*directions1, 'r.')

%%
points.quiver(ax, zero, origin2, 0, 'Color', 'black')
points.quiver(ax, origin2, frameMatrix2(1, :), 0, 'Color', 'red')
points.quiver(ax, origin2, frameMatrix2(2, :), 0, 'Color', 'green')
points.quiver(ax, origin2, frameMatrix2(3, :), 0, 'Color', 'blue')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

points.text(ax, origin2 + frameMatrix2(1, :), 'e_1')
points.text(ax, origin2 + frameMatrix2(2, :), 'e_2')
points.text(ax, origin2 + frameMatrix2(3, :), 'e_3')

[x, y, z] = elmat.local2global(origin2, frameMatrix2, u2, v2, w2);
mesh(ax, x, y, z)

uvw = [u2(:), v2(:), w2(:)];
xyz = origin2 + points.cart.local2global(cat(3, frameMatrix2(1, :), frameMatrix2(2, :), frameMatrix2(3, :)), uvw);
%points.plot(xyz, '.')

[uu, vv, ww] = elmat.global2local(origin2, frameMatrix2, x, y, z);

assert(norm([x(:), y(:), z(:)] - xyz, inf) < tol)
assert(norm([uu(:), vv(:), ww(:)] - uvw, inf) < tol)
assert(norm(points.cart.global2local(cat(3, frameMatrix2(1, :), frameMatrix2(2, :), frameMatrix2(3, :)), xyz - origin2) - uvw, inf) < tol)

directions2 = matfun.unit([x(:), y(:), z(:)] - origin2, 2);
frames = repmat(cat(3, frameMatrix2(1, :), frameMatrix2(2, :), frameMatrix2(3, :)), size(directions2, 1), 1, 1);
uvw = points.cart.global2local(frames, directions2);
[azimuth, inclination] = specfun.cart2sphi(uvw(:, 1), uvw(:, 2), uvw(:, 3));
radius = gain2(azimuth, inclination);
points.plot(origin2 + radius.*directions2, 'k.')

scale = 2; % directions needn't be unit vectors
directions = scale*[
    directions1;
    directions2;
    ];
indices = [
    repmat(1, size(directions1, 1), 1);
    repmat(2, size(directions2, 1), 1);
    ]; %#ok<REPMAT>

permutation = randperm(numel(indices));
indices = indices(permutation, :);
directions = directions(permutation, :);

%%
origins = cat(1, origin1, origin2);
frames = cat(1, frame1, frame2); % frame for each entity
context = antennae.orthocontext( ...
    frames, ...
    @specfun.cart2usphi); % "local Cartesian to local spherical"
multigain = antennae.dispatch( ...
    {gain1, gain2}, ...
    1 : 2, ... % trivial mapping as each entity has its own pattern
    context);

radii = multigain(indices, directions);
xyznew = origins(indices, :) + radii.*matfun.unit(directions, 2);
points.plot(ax, xyznew, 'ro')

%% Steps to emphasize:
%
% * Saving an empirical antenna pattern
% * Loading an empirical antanna pattern
% * One pattern in local coordinates
% * One pattern in global coordinates
% * In the extreme case, a single pattern is shared by every facet of a given material
%
