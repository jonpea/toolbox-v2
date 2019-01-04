function filip_new_room_modified(varargin)
%% Calculations from Yuen's IEEE TAP paper.

%%
parser = inputParser;
parser.addParameter('Arities', 0, @isvector)
parser.addParameter('Reporting', true, @islogical)
parser.addParameter('NumSamplesX', 4, @isscalar)
parser.addParameter('NumSamplesY', 5, @isscalar)
parser.addParameter('QuantileX', 0.1, @isscalar)
parser.addParameter('QuantileY', 0.9, @isscalar)
parser.addParameter('QuantileZ', 1.0, @isscalar)
parser.addParameter('Delta', 1e-3, @isscalar)
parser.addParameter('GainThreshold', -20, @isscalar)
parser.addParameter('ConcreteIndices', 0) %I added a 0 here so there is no concrete walls anywhere
parser.parse(varargin{:})
options = parser.Results;

%This controls how high is the sample plane where the sinks are placed
sample_plane = 1.0/3.3; 

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

%% Two dimensional model
mm2m = @(x) x/1000;
studheight = mm2m(3300);
fv2D.Faces= [1,2; %1
             1,3; %2
             2,4; %3
             3,4; %4
             5,6; %5
             ];
         
fv2D.Vertices= [0.0,0.0;    %1
                0.0,8.0;    %2
                15.0,0.0;   %3
                15.0,8.0;   %4
                7.5,8.0;    %5
                7.5,0.0;   %6
                ];
%fv2D.Vertices(end + 1, :) = [16.0, 16.0]; % corner vertex required by "cap()"

%This if statement exists to control whether the scene has concrete walls
%or not. So 0 is no concrete wall anything else is.
if (options.ConcreteIndices~=0)    
    concreteIndices = options.ConcreteIndices;
    gibIndices = setdiff(1 : size(fv2D.Faces, 1), concreteIndices);
else
    gibIndices = 1 : size(fv2D.Faces, 1);
end
%%
ax = newaxes('Scene 2D');
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

%% Three dimensional model
[fv3Dold.Faces, fv3Dold.Vertices] = ...
    extrudeplan(fv2D.Faces, fv2D.Vertices, 0.0, studheight);
fv3D = facevertex.extrude(fv2D, [0.0, studheight]);
fv3Dold = capfacevertex(fv3Dold, true, true);
% fv3D.Faces(end + 1, :) = facevertex.cap(@min, 3, fv3D);
% fv3D.Faces(end + 1, :) = facevertex.cap(@max, 3, fv3D);
gibIndices(end + (1 : 2)) = 6:7;

assert(isequal(fv3Dold.Vertices, fv3D.Vertices))
assert(isequal(fv3Dold.Faces(1 : 5, :), fv3D.Faces(1 : 5, :)))

%fv3Dold.Faces = fv3D.Faces; % <<<<<<<<<<<<<<< CHECK!!!

scene = scenes.Scene(fv3Dold.Faces, fv3D.Vertices);
%%
ax = newaxes('Scene 3D');
ax3d = ax;
hold(ax, 'on')
patch(ax, ...
    'Faces', fv3Dold.Faces(gibIndices, :), ...
    'Vertices', fv3D.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
if (options.ConcreteIndices~=0)
patch(ax, ...
    'Faces', fv3Dold.Faces(concreteIndices, :), ...
    'Vertices', fv3D.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'red');
end
points.text(ax, fv3D.Vertices, 'FontSize', fontsize, 'Color', 'red')
points.text(ax, facevertex.reduce(@mean, fv3Dold), 'FontSize', fontsize, 'Color', 'blue')
graphics.axislabels(ax, 'x', 'y', 'z')
axis(ax, 'equal')
rotate3d(ax, 'on')
points.quiver(ax, scene.Origin, scene.Frame(:, :, 1), 0.2, 'Color', 'red')
points.quiver(ax, scene.Origin, scene.Frame(:, :, 2), 0.2, 'Color', 'green')
points.quiver(ax, scene.Origin, scene.Frame(:, :, 3), 0.2, 'Color', 'blue')
view(ax, 30, 65)

%% Sinks
[xmin, ymin, zmin] = elmat.cols(min(fv3D.Vertices, [], 1));
[xmax, ymax, zmax] = elmat.cols(max(fv3D.Vertices, [], 1));
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
    inplanepoint(0.68,0.5); % access point #1
 %   inplanepoint(0.1,0.5); % access point #2
    ];
source.Gain = [ % [dBW]
    1.0d0; % access point #1
%    1.0d0; % access point #2
    ];
source.Frequency = [ % [Hz]
    2.4d9; % access point #1
%    2.4d9; % access point #2
    ];
source.Channel = [
    1;
%    1;
    ];


%%
points.plot(source.Origin, '.', 'Color', 'red', 'MarkerSize', 20)
points.text(source.Origin)
points.plot(sink.Origin, '.', 'Color', 'black', 'MarkerSize', 20)
points.text(sink.Origin)
rotate3d on

%% Gain functions
sourcegain = antennae.isopattern(0.0);
facetofunctionmap = zeros(size(scene.Frame, 1), 1);
facetofunctionmap(gibIndices) = 1;

if (options.ConcreteIndices~=0)
    facetofunctionmap(concreteIndices) = 2;
end

makepattern = @(name) loadpattern(fullfile('+data', name), @specfun.todb);

reflectiongains = antennae.dispatch({
    makepattern('Wall1_TM_refl_1GHz.txt') ... % gib/reflection
    makepattern('concrete_TE_refl_1GHz.txt') ... % concrete/reflection
    }, ...
    facetofunctionmap, ...
    antennae.orthocontext(scene.Frame, @specfun.cart2uqsphi));

transmissiongains = antennae.dispatch({
    antennae.isopattern(0.0) ... makepattern('Wall1_TM_trans_1GHz.txt') ... % gib/transmission
    antennae.isopattern(0.0) ... makepattern('concrete_TE_trans_1GHz.txt') ... % concrete/transmission
    }, ...
    facetofunctionmap, ...
    antennae.orthocontext(scene.Frame, @specfun.cart2uqsphi));

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
%%
% Reflection gain patterns for gib and concrete:
show('Reflection', origins, frames, reflectiongains)
%%
% Transmission gain patterns for gib and concrete:
show('Transmission', origins, frames, transmissiongains)

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
    'ReflectionGain', reflectiongains, ...
    'TransmissionGain', transmissiongains, ...
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
    ax = newaxes(sprintf('AP #%i Gain (dBw)', ap));
    numarities = numel(arities);
    for i = 1 : numarities + 1
        ax = subplot(1, 1 + numarities, i); hold on
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
            'Faces', fv3Dold.Faces(1 : end - 2, :), ...
            'Vertices', fv3D.Vertices, ...
            'FaceAlpha', 0.05, ...
            'EdgeAlpha', 0.3, ...
            'FaceColor', 'blue');
        patch(ax, ...
            'Faces', fv3Dold.Faces(end - 1 : end, :), ...
            'Vertices', fv3D.Vertices, ...
            'FaceAlpha', 0.05, ...
            'EdgeAlpha', 0.3, ...
            'FaceColor', 'red');
        view(ax, 2)
        axis(ax, 'equal', 'off', 'tight')
        xlabel('dbW')
        rotate3d(ax, 'on')
        colormap(ax, jet)
        colorbar(ax, 'Location', 'southoutside')
    end
end

%% Plot signal-to-noise ratio
ax = newaxes('SINR'); hold on
sinr = reshape(downlinks.SINRatio, size(gridx));
surf(ax, gridx, gridy, sinr, ...
    'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
title(ax, 'SINR')
patch(ax, ...
    'Faces', fv3Dold.Faces(1 : end - 2, :), ...
    'Vertices', fv3D.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
patch(ax, ...
    'Faces', fv3Dold.Faces(end - 1 : end, :), ...
    'Vertices', fv3D.Vertices, ...
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


%%
data = struct2table(trace.Data);
axes(ax3d)
%points.plot(ax3d, data.Position, 'o', 'Color', 'magenta')
points.quiver(ax3d, data.Position, data.Direction)
view([-25, -15])

import rayoptics.NodeTypes
freq = 2.45e9;
friis = @(distance) ...
    rayoptics.friisdb(distance, elmat.lightspeed./source.Frequency);
extract = @(type) data(data.InteractionType == type, :);
sinks = extract(NodeTypes.Sink)
sources = extract(NodeTypes.Source)
assert(isequal(sources.FreeDistance, sinks.FinalDistance))
assert(isequal(friis(sinks.FinalDistance), trace.Functions.Free(1, sinks.FinalDistance)))
points.scatter(sinks.Position, sinks.FinalDistance)

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
