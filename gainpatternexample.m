%% Visualisation of gain patterns

%% Antenna patterns
present('isotropic_one.txt')

%%
present('halfwavedipole.txt')

%%
present('shortdipole.txt')

%%
% Radiation pattern of the patch antenna placed on a wall
% *NB* For reliable interpolation, the missing samples at
% $\phi = 360^\circ$ should be copied from $\phi = 0^\circ$.
present('farfield_patch_centre_cavitywall_timber_extract.txt')

%% Transmission coefficients
present('trans_TM_Wall_3.txt')
%%
present('trans_TE_Wall_3.txt')

%% Reflection coefficients
present('refl_TM_Wall_3.txt')
%%
% This dataset no longer exists
%present('refl_TE_Wall_3.txt')

%%
% NB: This is a work-around to force capture of plot above - 
% do not delete this line.
disp('Finished')

%%
function present(filename)

opacity = {'EdgeAlpha', 0.1, 'FaceAlpha', 1.0};

filepath = fullfile('.', '+data', filename);
columndata = data.loadcolumns(filepath, '%f %f %f');

polar = deg2rad(columndata.theta);
azimuth = deg2rad(columndata.phi);

% data = loadpattern(filepath);
% polar = resample(data.Theta);
% azimuth = resample(data.Phi);
% interpolant = griddedInterpolant( ...
%     {data.Theta, data.Phi}, data.Gain);
% radius = interpolant({polar, azimuth});

interpolant1 = data.loadpattern(filepath);
[polar1, azimuth1] = ndgrid(resample(polar), resample(azimuth));
radius1 = interpolant1(polar1, azimuth1);
% assert(norm(radius(:) - radius1(:), inf) < 1e-12)


interpolant2 = @(theta, phi) ...
    interpolant1(specfun.wrapquadrant(theta), specfun.wrapquadrant(phi));
[polar2, azimuth2] = ndgrid( ...
    linspace(0.0, pi, 360), ... % polar angles
    linspace(0.0, pi, 360)); % azimuthal angles
radius2 = reshape(interpolant2(polar2, azimuth2), size(polar2));

subplot(2, 1, 1)
plotspherical(radius1, azimuth1, polar1, opacity{:})
title('Sub-sampled every 1 degree')
graphics.axislabels('x', 'y', 'z')
minradius = min(columndata.gain(:));
maxradius = max(columndata.gain(:));
if abs(minradius - maxradius) <= eps*(abs(maxradius) + 1)
    minradius = minradius - 0.5;
    maxradius = maxradius + 0.5;
end
caxis([minradius, maxradius])
colormap(jet)
colorbar('Location', 'east')
axis equal
rotate3d on
view(3)

subplot(2, 1, 2)
plotspherical(radius2, azimuth2, polar2, opacity{:})
title('Wrapped through quadrants')
graphics.axislabels('x', 'y', 'z')
axis equal
rotate3d on
view(3)

% input('Press enter to continue', 's');

end

function x = resample(x)
x = linspace(min(x), max(x), 361);
end

% -------------------------------------------------------------------------
function varargout = plotspherical(varargin)

[ax, radius, azimuth, inclination, varargin] = parse(varargin{:});

if mod(numel(varargin), 2) == 1
    units = varargin{1};
    assert(ischar(units))
else
    units = 'radians';
end

switch validatestring(units, {'degrees', 'radians'})
    case 'degrees'
        azimuth = deg2rad(azimuth);
        inclination = deg2rad(inclination);
end
elevation = 0.5*pi - inclination;
[x, y, z] = sph2cart(azimuth, elevation, ones(size(radius)));

[varargout{1 : nargout}] = surf( ...
    x, y, z, 'CData', radius, 'Parent', ax, varargin{:});

end

% -------------------------------------------------------------------------
function [ax, radius, inclination, azimuth, varargin] = parse(varargin)

narginchk(1, nargin)

last = find(cellfun(@ischar, varargin), 1, 'first') - 1;
if isempty(last)
    last = numel(varargin);
end
[ax, arrays] = arguments.parsefirst(@datatypes.isaxes, gca, 0, varargin{1 : last});
varargin = varargin(last + 1 : end);

assert(ismember(numel(arrays), [1, 3]))
switch numel(arrays)
    case 1
        radius = arrays{1};
        inclination = linspace(0, pi, size(radius, 1));
        azimuth = linspace(0, 2*pi, size(radius, 2));
    case 3
        [radius, inclination, azimuth] = arrays{:};
end

equalsize = @(a, b) isequal(size(a), size(b));
assert( ...
    equalsize(azimuth, radius) ...
    || numel(azimuth) == size(radius, 1))
assert( ...
    equalsize(inclination, radius) ...
    || numel(inclination) == size(radius, 2))

end
