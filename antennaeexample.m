function antennaeexample
%% ANTENNAEXAMPLE Demonstrates visualization of antennae patterns.
import elmat.ncols
import elmat.nrows

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

fig = figure(1);
clf(fig, 'reset')
fig.Name = mfilename;
fig.NumberTitle = 'off';
fig.Visible = 'off'; % hide figure...
newtab = graphics.tabbedfigure(fig, 'Visible', 'on'); % ... until first use
    function ax = newaxes(tabtitle)
        ax = axes(newtab(tabtitle));
    end

%% Sampling angles
% Use open intervals to avoid coordinate singularities
delta = 1e-3;
openlinspace = @(a, b, varargin) ...
    linspace(a + delta, b - delta, varargin{:});
theta = openlinspace(0, pi, 20);
phi = openlinspace(0, 2*pi)';

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
frames = cat(3, zenith, matfun.perp(zenith, 2));

%%
% Associates the antenna pattern with each frame
pattern1 = @(phi) phi/(2*pi);
pattern2 = @(phi) 1 - phi/(2*pi);
unitcircle = power.isofunction(1.0);
gainpattern = power.framefunctionnew({ ...
    power.polarpattern(pattern1) ...
    power.polarpattern(pattern2) ...
    }, frames, ...
    [1, 2]);

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
    gainpattern, origins, frames, ...
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
frames = cat(3, zenith, cozenith, matfun.cross(zenith, cozenith));

%%
% Sanity check
pattern1 = @(phi, theta) sx.expand(phi, theta)/(2*pi);
pattern2 = @(phi, theta) sx.expand(theta, phi)/pi;
gainpattern = power.framefunctionnew({ ...
    power.sphericalpattern(pattern1) ...
    power.sphericalpattern(pattern2) ...
    ... loadpattern('refl_TE_Wall_3_1GHz.txt', @todb, @wrapquadrant) ...
    ... loadpattern('trans_TE_Wall_3_1GHz.txt', @todb, @wrapquadrant) ...
    }, ...
    frames, ...
    facetofunction);

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
    gainpattern, origins, frames, ...
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
    gainpattern, origins, frames, ...
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
    gainpattern, origins, frames, ...
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
