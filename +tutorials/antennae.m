

%% Prepare workspace and figure
clear % workspace
newAxes = graphics.tabbedaxes( ...
    clf(figure(1), 'reset'), ...
    'Name', mfilename, ...
    'NumberTitle', 'off');

%% Define a local coordinate system
% The local coordinate axes and origin are expressed in global Cartesian
% coordinates
axis1 = matfun.unit([ 1  1  1]);
axis2 = matfun.unit([-1  1  0]);
axis3 = specfun.cross(axis1, axis2);
frame = [axis1; axis2; axis3];
origin = [1 -1 1]; % "local origin"
zero = [0 0 0]; % "global origin"

%% Gain patterns
gain = @(az, inc) sin(inc).*exp(cos(3*az))/3;

%% Patterns in local coordinates
[az, inc] = sx.meshgrid( ...
    linspace(0, 1.5*pi), ...
    linspace(0, pi));
[u, v, w] = specfun.sphi2cart(az, inc, gain(az, inc));

ax = newAxes('Local coordinates');
hold(ax, 'on')
surf(ax, u, v, w, 'EdgeAlpha', 0.1, 'FaceAlpha', 1.0)
points.quiver(ax, zero, [1 0 0], 0, 'Color', 'red')
points.quiver(ax, zero, [0 1 0], 0, 'Color', 'green')
points.quiver(ax, zero, [0 0 1], 0, 'Color', 'blue')
graphics.axislabels(ax, 'u', 'v', 'w')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 35, 35)

%%
ax = newAxes('Global coordinates');
hold(ax, 'on')


% points.quiver(ax, zero, origin, 'Color', graphics.rgb.magenta)
% points.quiver(ax, origin, xyz, 'Color', graphics.rgb.gray)
% return
points.quiver(ax, zero, origin, 0, 'Color', 'black')
points.quiver(ax, origin, axis1, 0, 'Color', 'red')
points.quiver(ax, origin, axis2, 0, 'Color', 'green')
points.quiver(ax, origin, axis3, 0, 'Color', 'blue')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

points.text(ax, origin + axis1, 'e_1')
points.text(ax, origin + axis2, 'e_2')
points.text(ax, origin + axis3, 'e_3')

[x, y, z] = elmat.local2global(origin, frame, u, v, w);
mesh(ax, x, y, z)

