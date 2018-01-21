function antennaeexample
%% ANTENNAEXAMPLE Demonstrates visualization of antennae patterns.

    function size = fontsize
        size = 15;
    end

    function labelaxis(ax, origins, frames, direction, local)
        local.axisscale = 1.5;
        local.labelscale = 1.6;
        local.format = graphics.untex('$\mathbf{e}_{%u,%u}$');
        points.quiver(ax, ...
            origins, local.axisscale*frames(:, :, direction), ...
            0, ... % no scaling
            'Color', graphics.rgb.gray(0.5), ...
            'LineWidth', 2)
        points.text(ax, ...
            origins + local.labelscale*frames(:, :, direction), ...
            compose(local.format, elmat.index(origins, 1), direction), ...
            'Interpreter', 'latex', ...
            'FontSize', fontsize);
    end

    function plotaxes(ax, origins, frames)
        points.text(ax, ...
            origins, ...
            compose( ...
            graphics.untex('$\mathbf{o}_%d$'), elmat.index(origins, 1)), ...
            'Interpreter', 'latex', 'FontSize', fontsize)
        for i = 1 : elmat.ncols(origins)
            labelaxis(ax, origins, frames, i);
        end
    end

[newaxes, fig] = graphics.tabbedaxes( ...
    clf(figure(1), 'reset'), 'Name', mfilename, 'NumberTitle', 'off');

%% Sampling angles
theta = linspace(0, pi, 20);
phi = linspace(0, 2*pi)';

%% 2D examples
% Specify location and orientation for two frames
origins = [
    0,  0;
    1, -1;
    ];
zenith = matfun.unit([
    +1,  1;
    -1, -1;
    ], 2);
frames = cat(3, zenith, specfun.perp(zenith, 2));

%%
% Associates the antenna pattern with each frame
pattern1 = @(phi) phi/(2*pi);
pattern2 = @(phi) 1 - phi/(2*pi);
unitcircle = power.isofunction(1.0);

gainpatterns = antennae.dispatch( ...
    {pattern1 pattern2}, ...
    1 : 2, ...
    antennae.orthocontext(frames, @specfun.cart2circ));

%%
ax = newaxes('2D contour');
hold(ax, 'on')
grid(ax, 'on')
axis(ax, 'equal')
graphics.axislabels(ax, 'x', 'y')
plotaxes(ax, origins, frames)
graphics.polar(ax, ...
    unitcircle, origins, frames, ...
    'Azimuth', phi, ...
    'Color', graphics.rgb.gray(0.5))
graphics.polar(ax, ...
    gainpatterns, origins, frames, ...
    'Azimuth', phi, ...
    'Color', 'red')

%% 3D examples
origins = [
    0, 0, 0;
    0, 3, 0;
    ];
zenith = matfun.unit([
    0,  1,  1;
    0, -1,  1;
    ], 2);
cozenith = matfun.unit([
    0,  1, -1;
    0,  1,  1;
    ], 2);
facetofunction = [
    1;
    2;
    ];
frames = cat(3, zenith, cozenith, specfun.cross(zenith, cozenith));

%%
% Sanity check
pattern1 = @(phi, theta) sx.expand(phi, theta)/(2*pi);
pattern2 = @(phi, theta) sx.expand(theta, phi)/pi;

gainpatterns = antennae.dispatch( ...
    {pattern1 pattern2}, ...
    facetofunction, ...
    antennae.orthocontext(frames, @specfun.cart2usphi));

%% 3D intensity plot
ax = newaxes('3D intensities');
hold(ax, 'on')
axis(ax, 'equal')
grid(ax, 'on')
graphics.axislabels(ax, 'x', 'y', 'z')
colormap(ax, jet)
colorbar(ax)
rotate3d(ax, 'on')
plotaxes(ax, origins, frames)
graphics.spherical(ax, ...
    gainpatterns, origins, frames, ...
    'Azimuth', phi, ...
    'Inclination', theta, ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
view(ax, 70, 40)

%% 3D contour plot
ax = newaxes('3D contours');
hold(ax, 'on')
axis(ax, 'equal')
grid(ax, 'on')
rotate3d(ax, 'on')
graphics.axislabels(ax, 'x', 'y', 'z')
colormap(ax, jet)
colorbar(ax)
plotaxes(ax, origins, frames)
graphics.polar( ...
    gainpatterns, origins, frames, ...
    'Azimuth', phi, ...
    'Inclination', theta)
view(ax, -80, 40)

%% 3D lobe plot
patterns = {pattern1, pattern2};
    function r = radius(id, varargin)
        r = patterns{id}(varargin{:});
    end
ax = newaxes('3D lobes');
hold(ax, 'on')
axis(ax, 'equal')
grid(ax, 'on')
graphics.axislabels(ax, 'x', 'y', 'z')
colormap(ax, jet)
colorbar(ax)
rotate3d(ax, 'on')
plotaxes(ax, origins, frames)
graphics.spherical(ax, ...
    gainpatterns, origins, frames, ...
    'Azimuth', phi, ...
    'Inclination', theta, ...
    'Radius', @radius, ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
view(ax, 70, 40)


%%
savefig(fig, fig.Name, 'compact')
fprintf('Saved figure in "%s.fig"\n', fig.Name)
% fig.Visible = 'off';

end
