function engtower_floor_filip(varargin)
%% Calculations from Yuen's IEEE TAP paper.

%%
parser = inputParser;
parser.addParameter('Arities', 0:2, @isvector)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('NumSamplesX', 120, @isscalar)
parser.addParameter('NumSamplesY', 60, @isscalar)
parser.addParameter('QuantileX', 0.1, @isscalar)
parser.addParameter('QuantileY', 0.9, @isscalar)
parser.addParameter('QuantileZ', 0.96, @isscalar)
parser.addParameter('Delta', 1e-3, @isscalar)
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfunction)
parser.addParameter('GainThreshold', -20, @isscalar)
parser.addParameter('StudHeight', 3.0, @isscalar)
parser.addParameter('CullDuplicateFaces', false, @islogical)
parser.addParameter('Plotting', true, @islogical)
parser.addParameter('ConcreteIndices', 0) %I added a 0 here so there is no concrete walls anywhere
parser.parse(varargin{:})
options = parser.Results;

close all;
%This controls how high is the sample plane where the sinks are placed
sample_plane = (1.0/3.0); 

%% Configuration
arities = options.Arities;
reporting = options.Reporting;
zquantile = options.QuantileZ;
numsamplesx = options.NumSamplesX;
numsamplesy = options.NumSamplesY;
delta = options.Delta; % spacing of sink points from exterior wall
gainthreshold = options.GainThreshold; % cut-off around sources

%%
t0 = tic;
tol = 1e-12;
%fontsize = 8;

newaxes = graphics.tabbedaxes( ...
    clf(figure(1), 'reset'), 'Name', mfilename, 'NumberTitle', 'off');
% This is a work-around to address mysteriously-appearing plot problem
newaxes = @(varargin) axes(figure);

%% Wall plan & materials set
[faces, vertices, wallmaterials] = data.engineeringtower8data3dnew;

%% Change to better format

if options.CullDuplicateFaces
    [~, select] = unique(sort(faces, 2), 'rows');
    fprintf('Removing %d redundant facet(s): %s\n', ...
        size(faces, 1) - numel(select), ...
        mat2str(setdiff(1 : size(faces, 1), select)))
    faces = faces(select, :);
else
    disp('WARNING: Duplicate faces exist')
    warning('off', 'embreescene:DuplicateFaces')
    warning('off', 'embreescene:DuplicateVertices')
end

%%
ax = axes(figure(1)); 
clf(ax, 'reset')
patch(ax, 'Faces', faces, 'Vertices', vertices)
points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
points.text(ax, vertices, 'FontSize', 7, 'Color', 'red')
axis('equal')

%%
% extruded = facevertex.extrude(faces, vertices, [0.0, options.StudHeight]);
% [faces, vertices] = facevertex.fv(extruded);

% % Add 3 floor panels
% floor = [
%     1 24 71 3;
%     25 72 39 71;
%     72 68 70 40;
%     ];
% numfloorpanels = size(floor, 1);
% 
% % Add 3 ceiling panels
% ceiling = floor + max(floor(:));
% 
% % Add ceiling **but not floor** onto original walls
% faces = [faces; ceiling];

% Make a struct of faces & vertices only for use in the "clone" function,
% below
% Be wary of the distinction between these two objects!
scene = options.Scene(faces, vertices);
% fv = struct('Faces', faces, 'Vertices', vertices);
% 
% %%
% numFloors = 1;
% elevate = @(x, level) x + level*[0, 0, options.StudHeight];
% storeys = arrayfun( ...
%     facevertex.clone(elevate, fv), 0 : numFloors - 1, ...
%     'UniformOutput', false);
% combinedStoreys = facevertex.cat(storeys{:});
% faces = combinedStoreys.Faces;
% vertices = combinedStoreys.Vertices;
% 
% % Completely artibrary transmission & reflection coefficients
% % for a floor/ceiling panel
% materialsdata(end + 1, :) = [-12, -15];
% floorceilingmaterialtype = size(materialsdata, 1); % after appending/resizing
% floorceilingmaterials = repmat(floorceilingmaterialtype, numfloorpanels, 1);
% wallmaterials = [
%     wallmaterials;
%     floorceilingmaterials;
%     ];
% 
% wallmaterials = repmat(wallmaterials, numFloors, 1);
% % At this point, we have a single scene with material properties that
% % is missing only the definition of the floor on the ground storey.
% 
% % Add the ground storey's floor
% faces = [faces; floor];
% wallmaterials = [wallmaterials; floorceilingmaterials];
%%
if options.Plotting
    ax = axes(figure(1));
    clf(ax, 'reset')
    hold(ax, 'on')
    patch(ax, ...
        'Faces', faces, ...
        'Vertices', vertices, ...
        'FaceAlpha', 0.2, ...
        'FaceColor', graphics.rgb.blue, ...
        'EdgeColor', graphics.rgb.gray, ...
        'LineWidth', 1);
    patch(ax, ...
        'Faces', faces(wallmaterials == 9, :), ...
        'Vertices', vertices, ...
        'FaceAlpha', 0.5, ...
        'FaceColor', graphics.rgb.white, ...
        'EdgeColor', graphics.rgb.gray, ...
        'LineWidth', 1);
    points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
    points.text(ax, vertices, 'FontSize', 10, 'Color', 'red')
    set(ax, 'XTick', [0, 30.5], 'YTick', [0, 7.5])
    axis(ax, 'tight')
    axis(ax, 'equal')
    grid(ax, 'on')
    rotate3d('on')
end

%% Sinks
[xmin, ymin, zmin] = elmat.cols(min(vertices, [], 1));
[xmax, ymax, zmax] = elmat.cols(max(vertices, [], 1));
x = linspace(xmin + delta, xmax - delta, numsamplesx);
y = linspace(ymin + delta, ymax - delta, numsamplesy);
z = specfun.affine(zmin, zmax, sample_plane);
[sink.Origin, gridx, gridy] = points.meshpoints({x, y, z});

%% Sources
inplanepoint = @(s, t) [
    specfun.affine(xmin, xmax, s), ...
    specfun.affine(ymin, ymax, t), ... % NB: With respect to *first* room
    specfun.affine(zmin, zmax, zquantile)
    ];
source.Origin = [ % [m]
    inplanepoint((10/30.5),(3/7.5));    %3
    inplanepoint((5.8/30.5),(6/7.5));   %1
    inplanepoint((10.2/30.5),(6/7.5));  %2
    inplanepoint((15.2/30.5),(6/7.5));  %1
    inplanepoint((20/30.5),(3/7.5));    %2
    inplanepoint((29/30.5),(3/7.5));    %1
    inplanepoint((24/30.5),(6/7.5));    %3
    ];

source.Origin = source.Origin + 1e-2*randn(size(source.Origin));

source.Gain = [ % [dBW]
    1.0d0;
    1.0d0;
    1.0d0;
    1.0d0;
    1.0d0;
    1.0d0;
    1.0d0;
    ];
source.Frequency = [ % [Hz]
    2.4d9;
    2.4d9;
    2.4d9;
    2.4d9;
    2.4d9;
    2.4d9;
    2.4d9;
    ];
source.Channel = [
    3;
    1;
    2;
    1;
    2;
    1;
    3;
    ];

%%
points.plot(source.Origin, '.', 'Color', 'red', 'MarkerSize', 20)
rotate3d on

%% Gain functions

%sourcegain = examples.patternDemo_Filip();
% ===== New code =====>
    function result = sourcePattern(phi, theta)
        % This is taken from patternDemo_Filip.m
        c = 3d8;
        f = 2.45d9;
        Lambda = c/f;
        L = 0.49*(Lambda/sqrt(2.2));
        W = 2.7*L;
        k = (2*pi)/Lambda;
        sinsin = 0.5*k*W*sin(theta).*sin(phi);
        sincos = 0.5*k*L*sin(theta).*cos(phi);
        result = (sin(sinsin)./sinsin) .* cos(sincos);
    end
sourceFrame = cat(3, ...
    [1  1  0], ... % local x-axis
    [1 -1  0], ... % local y-axis
    [0  0  1]);    % local z-axis
sourcegain = antennae.dispatch( ...
    @sourcePattern, ...
    [1, 1, 1, 1, 1, 1, 1], ... % "maps Antenna #1 to Gain Pattern #1"
    antennae.orthocontext( ...
        cat(1, sourceFrame, sourceFrame, sourceFrame, sourceFrame, sourceFrame, sourceFrame, sourceFrame), ...
        @specfun.cart2usphi)); % "Cartesian to spherical on unit sphere"
% <===== New code =====


% makepattern = @(name) loadpattern(fullfile('+data', name), @specfun.todb);

% reflectiongains = antennae.dispatch({
%     makepattern('Wall1_TM_refl_1GHz.txt') ... % gib/reflection
%     makepattern('concrete_TE_refl_1GHz.txt') ... % concrete/reflection
%     }, ...
%     facetofunctionmap, ...
%     antennae.orthocontext(scene.Frame, @specfun.cart2uqsphi));
% 
% transmissiongains = antennae.dispatch({
%     makepattern('Wall1_TM_trans_1GHz.txt') ... % gib/transmission
%     makepattern('concrete_TE_trans_1GHz.txt') ... % concrete/transmission
%     }, ...
%     facetofunctionmap, ...
%     antennae.orthocontext(scene.Frame, @specfun.cart2uqsphi));

%% Visualization
origin = [0 0 0];
origins = [-2 0 0; 2 0 0];
frame = cat(3, [1 0 0], [0 1 0], [0 0 1]);
frames = [frame; frame];

    function show(title, origin, frame, gain)
        ax = newaxes(title);
        axis(ax, 'equal')
        grid(ax, 'on')
        graphics.axislabels(ax, 'x', 'y', 'z')
        colormap(ax, jet)
        colorbar(ax)
        rotate3d(ax, 'on')
        plotaxes(ax, origin, frame)
        ax = subplot(1, 2, 1);
        graphics.spherical(ax, ...
            funfun.comp(@specfun.fromdb, 1, gain), ...
            origin, frame, ...
            'Azimuth', linspace(0, 2*pi), ...
            'Inclination', linspace(0, pi), ...
            'EdgeAlpha', 0.1, ...
            'FaceAlpha', 1.0)
        view(ax, 70, 40)
        ax = subplot(1, 2, 2);
        graphics.polar(ax, ...
            funfun.comp(@specfun.fromdb, 1, gain), ...
            origin, frame, ...
            'Inclination', linspace(0, pi, 100), ...
            'LineWidth', 1.0);
        view(3)
    end

%%
% Antenna gain pattern:
show('Source', origin, frame, sourcegain)
% %%
% % Reflection gain patterns for gib and concrete:
% show('Reflection', origins, frames, reflectiongains)
% %%
% % Transmission gain patterns for gib and concrete:
% show('Transmission', origins, frames, transmissiongains)
% %%
materials = struct( ...
    'TransmissionGain', materialsdata(wallmaterials, 1), ...
    'ReflectionGain', materialsdata(wallmaterials, 2));

%% Trace reflection paths
starttime = tic;

[downlinks, ~, trace] = rayoptics.analyze( ...
    ... @scene.reflections, ...
    ... @scene.transmissions, ...
    ... scene.NumFacets, ...
    scene, ...
    source.Origin, ...
    sink.Origin, ...
    'ReflectionArities', arities, ...
    'FreeGain', antennae.friisfunction(source.Frequency), ...
    'SourceGain', sourcegain, ... % [dB]
    'ReflectionGain', antennae.isopattern(materials.ReflectionGain), ...
    'TransmissionGain', antennae.isopattern(materials.TransmissionGain), ...
    'SinkGain', antennae.isopattern(0.0), ... % [dB]
    'Reporting', reporting, ...
    'AccessPointChannel', source.Channel);

gains = downlinks.GainComponents;

traceTime = toc(starttime);

fprintf('============== tracescene: %g sec ==============\n', traceTime)

%% Compute gains and display table of interactions
if reporting
    
    %% Distribution of interaction nodes
    disp('From stored interaction table')
    disp(struct2table(rayoptics.trace.frequencies(trace)))
    
    %% Distribution of received power
    [gainStats, gainsFromTrace] = rayoptics.trace.process(trace);
    disp(struct2table(gainStats))
    
    %% Sanity check
    assert(isequalfp(gains, gainsFromTrace, tol))
    disp('calculated powers do match :-)')
    
end

%% Power distributions
arityGains = squeeze(sum(sum(gains, 1), 2)); % total power at each arity
totalGain = sum(arityGains);
relativeGains = arityGains ./ totalGain;
select = arities(:) + 1;
disp(array2table( ...
    [arities(:), arityGains(select), 100*relativeGains(select)], ...
    'VariableNames', {'Arity', 'Power', 'RelativePower'}))

%% Aggregate power at each receiver
if isvector(gridx) || isvector(gridy)
    return
end

%%
fprintf('============ total elapsed time: %g sec ============\n', toc(t0))

for ap = 1 : size(source.Origin, 1) % for each access point
    ax = newaxes(sprintf('AP #%i Gain (dBw)', ap)); hold on
    numarities = numel(arities);
    for i = 1 : numarities + 1
        subplot(1, 1 + numarities, i); hold on
        if i <= numarities
            temp = gains(:, ap, i);
            titlestring = sprintf('arity %d', arities(i));
        else
            temp = sum(gains(:, ap, :), 3);
            titlestring = 'total';
        end
        temp = reshape(specfun.todb(temp), size(gridx));
        surf(gridx, gridy, temp, ...
            'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
        caxis([min(temp(:)), min(max(temp(:)), gainthreshold)])
        contour(gridx, gridy, temp, 10, 'Color', 'white', 'LineWidth', 1)
        title(titlestring)
        patch( ...
            'Faces', faces(1 : end - 2, :), ...
            'Vertices', vertices, ...
            'FaceAlpha', 0.05, ...
            'EdgeAlpha', 0.3, ...
            'FaceColor', 'blue');
        patch( ...
            'Faces', faces(end - 1 : end, :), ...
            'Vertices', vertices, ...
            'FaceAlpha', 0.05, ...
            'EdgeAlpha', 0.3, ...
            'FaceColor', 'red');
        view(2)
        axis('equal', 'off', 'tight')
        xlabel('dbW')
        rotate3d('on')
        colormap(jet)
        colorbar('Location', 'southoutside')
    end
end

%% Plot signal-to-noise ratio
ax = newaxes('SINR'); hold on
sinr = reshape(downlinks.SINRatio, size(gridx));
surf(ax, gridx, gridy, sinr, ...
    'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
title(ax, 'SINR')
patch(ax, ...
    'Faces', faces(1 : end - 2, :), ...
    'Vertices', vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
patch(ax, ...
    'Faces', faces(end - 1 : end, :), ...
    'Vertices', vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'red');
contour(ax, gridx, gridy, sinr, 10, 'Color', 'black', 'LineWidth', 2)
view(ax, 2)
axis(ax, 'equal', 'off', 'tight')
rotate3d(ax, 'on')
colormap(ax, jet)
colorbar(ax, 'Location', 'southoutside')

%% Save multi-tabbed figure 
% Opening the figure from file is much less expensive than re-computing it
% from scratch. (One can use 'openfig' to open the figure programmatically 
% in MATLAB.)
savefig(mfilename)

end

% -------------------------------------------------------------------------
function [model, vertices] = capfacevertex(model, floor, ceiling, axisaligned)

narginchk(1, 4)
if nargin < 2 || isempty(floor)
    floor = true;
end
if nargin < 3 || isempty(ceiling)
    ceiling = false;
end
if nargin < 4 || isempty(axisaligned)
    axisaligned = false;
end
assert(ismember('Faces', fieldnames(model)))
assert(ismember('Vertices', fieldnames(model)))
assert(size(model.Vertices, 2) == 3)
assert(isscalarlogical(floor))
assert(isscalarlogical(ceiling))

columns = num2cell(model.Vertices, 1);
extremes = num2cell([
    cellfun(@min, columns);
    cellfun(@max, columns);
    ], 1);
[temp{1 : 3}] = ndgrid(extremes{:});
temp = cellfun(@(x) x(:), temp, 'UniformOutput', false);
temp = cell2mat(temp);
lowervertices = temp([1 3 4 2], :); % anticlockwise from lower south-west corner
uppervertices = temp([5 6 8 7], :); % clockwise from upper south-west corner
[lowerfound, lowerfacevertices] = ismember(lowervertices, model.Vertices, 'rows');
[upperfound, upperfacevertices] = ismember(uppervertices, model.Vertices, 'rows');
assert(~axisaligned || (all(lowerfound) && all(upperfound)), ...
    'Plan does not appear to be axis-aligned and rectangular.')
if floor
    newlowervertexids = size(model.Vertices, 1) + (1 : sum(~lowerfound));
    lowerfacevertices(~lowerfound) = newlowervertexids;
    model.Faces(end + 1, :) = lowerfacevertices(:)';
    model.Vertices(newlowervertexids, :) = lowervertices(~lowerfound, :);
end
if ceiling
    newuppervertexids = size(model.Vertices, 1) + (1 : sum(~upperfound));
    upperfacevertices(~upperfound) = newuppervertexids;
    model.Faces(end + 1, :) = upperfacevertices(:)';
    model.Vertices(newuppervertexids, :) = uppervertices(~upperfound, :);
end

if nargout == 2
    % Return individual fields
    vertices = model.Vertices;
    model = model.Faces;
end

end

function result = isscalarlogical(x)
result = isscalar(x) && islogical(x);
end

% -------------------------------------------------------------------------
function [faces, vertices] = extrudeplan(faces, vertices, lower, upper)
%EXTRUDEPLAN Extruison of a 2D plan in face-vertex repsentation.
% [FF,VV]=EXTRUDEPLAN(F,V,LOWER,UPPER) extrudes a set of 2D line segments
% with face-vertex representation F-V into a set of 3D quadrilaterals with
% representation FF-VV spanning the range from LOWER to UPPER in the
% vertical direction.
% EXTRUDEPLAN(F,V,HEIGHT) with non-zero scalar HEIGHT is equivalent
% to EXTRUDEPLAN(F,V,0.0,HEIGHT).
% See also EXTRUDEPATCH

narginchk(2, 4)

switch nargin
    case 2 % default span
        lower = 0.0;
        upper = 1.0;
    case 3 % given height
        assert(lower ~= 0)
        upper = lower;
        lower = 0.0;
end

assert(size(faces, 2) == 2)
assert(isscalar(lower))
assert(isscalar(upper))
assert(lower ~= upper)

if upper < lower
    [lower, upper] = deal(upper, lower);
end

numvertices = size(vertices, 1);

vertices = [
    vertices, repmat(lower, numvertices, 1);
    vertices, repmat(upper, numvertices, 1);
    ];

faces = [
    faces, ...
    fliplr(faces) + numvertices
    ];

if nargout == 1
    faces = struct('Faces', faces, 'Vertices', vertices);
end

end

% -------------------------------------------------------------------------
function interpolant = loadpattern(filename, transform)
assert(ischar(filename))
numcolumns = numel(data.scanheader(filename));
assert(ismember(numcolumns, 2 : 3))
columns = data.loadcolumns(filename, '%f %f %f');
[phi, theta, gain] = points.fullgrid.ungrid( ...
    columns.phi, columns.theta, columns.gain);
interpolant = griddedInterpolant({
    deg2rad(phi), ... % azimuthal angle from x-axis
    deg2rad(theta) ... % inclination from the z-axis
    }, ...
    transform(gain));
end

% -------------------------------------------------------------------------
function size = fontsize
size = 15;
end

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
function tf = isequalfp(a, b, tol)
if nargin < 3
    tol = 1e-12;
end
a = a(:);
b = b(:);
tf = max(abs(a - b) ./ (0.5*(abs(a) + abs(b)) + 1)) < tol;
end
