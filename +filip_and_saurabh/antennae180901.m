function antennae180901
%% Demonstation of antennae configuration and visualization

%% Prepare workspace and figure
clear % workspace
currentId = 0;
    function ax = newAxes(name) 
        currentId = currentId + 1;
        fig = figure(currentId);
        clf(fig)
        set(fig, 'Name', name)
        ax = axes(fig);
    end
% newAxes = graphics.tabbedaxes( ...
%     clf(figure(1), 'reset'), ... 
%     'Name', mfilename, ...
%     'NumberTitle', 'on');
tol = 1e-14;
zero = [0 0 0]; % "global origin"

%% Two dimensional scene
fv2D.Faces= [1,6;7,12;1,7;2,8;3,9;4,10;5,11;6,12;1,2;7,8;13,14;15,16;17,18;19,20;1,19;2,20;21,22;21,23];
fv2D.Vertices = [0,0;0,3.2;0,6.4;0,9.6;0,12.8;0,16;3.2,0;3.2,3.2;3.2,6.4;3.2,9.6;3.2,12.8;3.2,16;6.4,0;6.4,3.2;9.6,0;9.6,3.2;12.8,0;12.8,3.2;16,0;16,3.2;4.8,4.8;4.8,11.2;11.2,4.800];
fv2D.Vertices(end + 1, :) = [16.0, 16.0]; % corner vertex required by "cap()"
ax = newAxes('Scene 2D');
hold(ax, 'on')
patch(ax, ...
    'Faces', fv2D.Faces, ...
    'Vertices', fv2D.Vertices, ...
    'FaceColor', 'blue', ...
    'FaceAlpha', 0.2, ...
    'EdgeColor', 'black');
points.text(ax, facevertex.reduce(@mean, fv2D), 'Color', 'red')
points.text(ax, fv2D.Vertices, 'Color', 'blue')
axis(ax, 'equal', 'tight')
view(ax, 2)

%% Three dimensional scene
studheight = 3.0;
fv3D = facevertex.extrude(fv2D, [0.0, studheight]);
scene = scenes.Scene(fv3D.Faces, fv3D.Vertices);
ax = newAxes('Scene 3D');
hold(ax, 'on')
patch(ax, ...
    'Faces', fv3D.Faces, ...
    'Vertices', fv3D.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
points.text(ax, facevertex.reduce(@mean, fv2D), 'Color', 'red')
points.text(ax, fv2D.Vertices, 'Color', 'blue')
axis(ax, 'equal', 'tight')
view(ax, 3)

%% Gain pattern
    function radius = MyPattern(phi, theta, ~)
        radius = 10*(cos(theta/2) .* (0.01 + abs(cos(2*phi)))); 
    end
    
%% Define two local coordinate systems
% The local coordinate axes and origin are expressed in global Cartesian
% coordinates
axis1 = matfun.unit([-1  +1  0]);
% 3rd axis is "main lobe" for MyPattern
%axis3 = matfun.unit([0 0 1]); % CASE #1
axis3 = matfun.unit([-1  -1  0]); % CASE #2
axis2 = specfun.cross(axis1, axis3); 
frame1 = cat(3, axis1, axis2, axis3);
frameMatrix1 = [axis1; axis2; axis3];
origin1 = mid(fv3D.Vertices, 1); % "local origin"

%% Patterns in local coordinates
delta = 1e-2;
[az, inc] = sx.meshgrid( ...
    linspace(0, 2*pi, 30), ...
    linspace(delta, pi - delta, 30)); % avoid singularity at "0 == pi"
radius = MyPattern(az, inc);
[u1, v1, w1] = specfun.sphi2cart(az, inc, radius);

scale = 1.4*max(radius(:)); % Ensure that axes protrude from gain surface
frameMatrixScaled = scale*frameMatrix1; % for plotting only

ax = newAxes('Gain 1 (local)');
hold(ax, 'on')
surf(ax, u1, v1, w1, 'EdgeAlpha', 0.1, 'FaceAlpha', 1.0)
points.quiver(ax, zero, [scale 0 0], 0, 'Color', 'red')
points.quiver(ax, zero, [0 scale 0], 0, 'Color', 'green')
points.quiver(ax, zero, [0 0 scale], 0, 'Color', 'blue')
graphics.axislabels(ax, 'u', 'v', 'w')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 35, 35)

%% Gain patterns in global coordinates
ax = newAxes('Global coordinates');
hold(ax, 'on')
rotate3d(ax, 'on')

points.text(ax, zero, '0')
%points.quiver(ax, zero, origin1, 0, 'Color', 'black')
points.quiver(ax, origin1, frameMatrixScaled(1, :), 0, 'Color', 'red')
points.quiver(ax, origin1, frameMatrixScaled(2, :), 0, 'Color', 'green')
points.quiver(ax, origin1, frameMatrixScaled(3, :), 0, 'Color', 'blue')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
grid(ax, 'on')
view(ax, 3)

points.text(ax, origin1 + frameMatrixScaled(1, :), 'e_1')
points.text(ax, origin1 + frameMatrixScaled(2, :), 'e_2')
points.text(ax, origin1 + frameMatrixScaled(3, :), 'e_3')

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
radius = MyPattern(azimuth, inclination);
% points.plot(origin1 + radius.*directions1, 'r.')

scale = 2; % directions needn't be unit vectors
directions = scale*directions1;
indices = repmat(1, size(directions1, 1), 1);

permutation = randperm(numel(indices));
indices = indices(permutation, :);
directions = directions(permutation, :);

%%
origins = cat(1, origin1);
frames = cat(1, frame1); % frame for each entity
context = antennae.orthocontext( ...
    frames, ...
    @specfun.cart2usphi); % "local Cartesian to local spherical"
sourcegain = antennae.dispatch({@MyPattern}, 1, context);

radii = sourcegain(indices, directions);
xyznew = origins(indices, :) + radii.*matfun.unit(directions, 2);
points.plot(ax, xyznew, 'ro')

%%
source.Origin = origin1;

%% Sampling points
x = linspace(min(fv2D.Vertices(:, 1)), max(fv2D.Vertices(:, 1)), 100);
y = linspace(min(fv2D.Vertices(:, 2)), max(fv2D.Vertices(:, 2)), 100);
z = 1.0;
[sink.Origin, gridx, gridy] = points.meshpoints({x, y, z});


%% Trace reflection paths
arities = 0;
starttime = tic;
[downlinks, ~, ~] = rayoptics.analyze( ...
    ... @scene.reflections, ...
    ... @scene.transmissions, ...
    ... scene.NumFacets, ...
    scene, ...
    source.Origin, ...
    sink.Origin, ...
    'ReflectionArities', arities, ...
    'SourceGain', sourcegain); % [dB]
gains = downlinks.GainComponents;
fprintf('Ray tracing required %.2g seconds\n', toc(starttime))

%%
gainthreshold = inf;
numarities = numel(arities);
ap = 1; % access point index
for i = 1 : numarities + 1
    ax = newAxes(sprintf('Gain/%d', i - 1));
    hold on
    if i <= numarities
        temp = gains(:, ap, i);
        titlestring = sprintf('arity %d', arities(i));
    else
        temp = sum(gains(:, ap, :), 3);
        titlestring = 'total';
    end
    temp = reshape(specfun.todb(temp), size(gridx));
    surf(ax, gridx, gridy, temp, ...
        'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
    caxis(ax, [min(temp(:)), min(max(temp(:)), gainthreshold)])
    contour(ax, gridx, gridy, temp, 10, 'Color', 'white', 'LineWidth', 1)
    title(ax, titlestring)
    patch(ax, ...
        'Faces', fv3D.Faces, ...
        'Vertices', fv3D.Vertices, ...
        'FaceAlpha', 0.05, ...
        'EdgeAlpha', 0.3, ...
        'FaceColor', 'blue');
    view(ax, 2)
    axis(ax, 'equal', 'tight')
    xlabel('dbW')
    points.plot(source.Origin, 'o')
    rotate3d(ax, 'on')
    colormap(ax, jet)
    colorbar(ax, 'Location', 'southoutside')
end

%% Plot signal-to-noise ratio
ax = newAxes('SINR'); 
hold on
sinr = reshape(downlinks.SINRatio, size(gridx));
surf(ax, gridx, gridy, sinr, ...
    'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
title(ax, 'SINR')
patch(ax, ...
    'Faces', fv3D.Faces, ...
    'Vertices', fv3D.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
contour(ax, gridx, gridy, sinr, 10, 'Color', 'black', 'LineWidth', 2)
points.plot(source.Origin, 'o')
view(ax, 2)
axis(ax, 'equal', 'tight')
rotate3d(ax, 'on')
colormap(ax, jet)
colorbar(ax, 'Location', 'southoutside')
hBar1 = colorbar;
ylabel(hBar1,'SINR(dB)');

end

function mid = mid(x, varargin)
low = min(x, [], varargin{:});
high = max(x, [], varargin{:});
mid = (high - low)/2;
end