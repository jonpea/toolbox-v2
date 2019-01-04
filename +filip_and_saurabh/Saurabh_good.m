%% Analysis of Building 903, Level 4, Newmarket Campus
function Saurabh_good(varargin)
%% Introduction
% This script mirrors the |nelib| program implemented in |yzg001.f90|.
close all
%% Optional arguments
parser = inputParser;
parser.addParameter('LargeScale', true, @islogical)
parser.addParameter('Arities', 0, @isrow)
parser.addParameter('Fraction', 1.0, @isnumeric)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Plotting', true, @islogical)
parser.addParameter('Printing', false, @islogical)
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfzunction)
parser.addParameter('Serialize', false, @islogical)
parser.addParameter('StudHeight', 3.0, @isscalar)
parser.addParameter('XGrid', [], @isvector)
parser.addParameter('YGrid', [], @isvector)
parser.addParameter('CullDuplicateFaces', false, @islogical)
parser.parse(varargin{:})
options = parser.Results;

fontsize = 10;
markersize = 10;
dB = -2;
transmissiongain = repelem(dB,192);
transmissiongain(187:189) = -20;
transmissiongain(124:126) = -20;
transmissiongain(61:63) = -20;
transmissiongain(190:192) = -20;

reflectiongain = -6.0; % [dB]
frequency = 2.45e9; % [Hz]
reflectionarities = [0, 1];

%% Wall plan & materials set
[linevertices, materialsdata, wallmaterials] = data.building903level4;
[faces, vertices] = facevertex.compress(facevertex.xy2fv( ...
    linevertices(:, [1 3])', ...
    linevertices(:, [2 4])'));

vertices = [
    vertices;
    vertices(24, 1), vertices(3, 2); % (x24, y3)
    vertices(39, 1), vertices(25, 2); % (x39, y25)
];

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

ax = axes(figure(1)); 
clf(ax, 'reset')
patch(ax, 'Faces', faces, 'Vertices', vertices)
points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'white')
points.text(ax, vertices, 'FontSize', 10, 'Color', 'white')
axis('equal')

%Vertices on regular grid
xvertexgrid = [0.0, 15, 30];
yvertexgrid = [0.0, 8];
zvertexgrid = [0.0, 3.0, 6.0, 9.0];

extruded = facevertex.extrude(faces, vertices, [0.0, options.StudHeight]);
[faces, vertices] = facevertex.fv(extruded);
floor = [
  1 24 71 3;
    25 72 39 71;
    72 68 70 40;
    ];
numfloorpanels = size(floor, 1);

% Add 3 ceiling panels
ceiling = floor + max(floor(:));

% Add ceiling **but not floor** onto original walls
faces = [faces; ceiling];

% Make a struct of faces & vertices only for use in the "clone" function,
% below
% Be wary of the distinction between these two objects!
scene = scenes.Scene(faces, vertices);
fv = struct('Faces', faces, 'Vertices', vertices);

%%
numFloors =3;
elevate = @(x, level) x + level*[0, 0, 3];
storeys = arrayfun( ...
    facevertex.clone(elevate, fv), 0 : numFloors - 1, ...
    'UniformOutput', false);
combinedStoreys = facevertex.cat(storeys{:});
faces = combinedStoreys.Faces;
vertices = combinedStoreys.Vertices;
faces = [faces; floor];

zfraction = 0.5; % bias towards ceiling
zsourceticks = ...
    zvertexgrid(1 : end - 1)*(1 - zfraction) + ...
    zvertexgrid(2 : end)*zfraction;

sourceposition = [ 1, 3, 1.5;
                   11, 3, 1.5;
                   1, 3, 4.5;
                   11, 3, 4.5;
                   1, 3, 7.5;
                   11, 3, 7.5;
];

% Sampling points 



%This needs to be in here to avoid getting nan or inf
sourceposition = sourceposition + 0.001;

% Sampling points 
xsinkticks = linspace(xvertexgrid(1), xvertexgrid(end), 10);
ysinkticks = linspace(yvertexgrid(1), yvertexgrid(end), 10);
zfraction = 0.5; % midway between floor and ceiling
zsinkticks = ...
    zvertexgrid(1 : end - 1)*(1 - zfraction) + ...
    zvertexgrid(2 : end)*zfraction;
[xsink, ysink, zsink] = meshgrid(xsinkticks, ysinkticks, zsinkticks);
sinkposition = points.meshpoints(xsink, ysink, zsink);

%% Patch Antenna Implementation

%Orientations for the antennas
SourceFrame_up = cat(3, ...
    [1 0 0], ... % local x-axis
    [0 1 0], ... % local y-axis
    [0 0 1]);    % local z-axis
SourceFrame_down = cat(3, ...
    [-1 0 0], ... % local x-axis
    [0 1 0], ... % local y-axis
    specfun.cross([-1 0 0], [0 1 0]));    % local z-axis
SourceFrame_south = cat(3, ...
    [1 0 0], ... % local x-axis
    [0 0 1], ... % local y-axis
    [0 -1 0]);    % local z-axis
SourceFrame_north = cat(3, ...
    [1 0 0], ... % local x-axis
    [0 0 -1], ... % local y-axis
    [0 1 0]);    % local z-axis
SourceFrame_east = cat(3, ...
    [0 1 0], ... % local x-axis
    [0 0 1], ... % local y-axis
    specfun.cross([0 1 0],[0 0 1]));    % local z-axis
SourceFrame_west = cat(3, ... %left
    [0 -1 0], ... % local x-axis
    [0 0 1], ... % local y-axis
    specfun.cross([0 -1 0], [0 0 1]));    % local z-axis
SourceFrame_north_east = cat(3, ...
    [-1 1 0], ... % local x-axis
    [0 0 1], ... % local y-axis
    specfun.cross([-1 1 0],[0 0 1]));    % local z-axis
SourceFrame_south_west = cat(3, ... %left
    [1 -1 0], ... % local x-axis
    [0 0 1], ... % local y-axis
    specfun.cross([1 -1 0], [0 0 1]));    % local z-axis

%sourcegain = antennae.isopattern(0.0);

sourcegain = antennae.dispatch( ...
    @sourcepattern, ...
    [1, 1, 1, 1, 1, 1], ... % "maps Antenna #1 to Gain Pattern #1 and Antenna #2 to Gainr Pattern #1"
    antennae.orthocontext( ...
    cat(1, SourceFrame_east, SourceFrame_east, SourceFrame_east, SourceFrame_east, SourceFrame_east, SourceFrame_east), ...
    @specfun.cart2usphi)); % "Cartesian to spherical on unit sphere"

%%
figure(2), clf, hold('on')
set(gcf, 'Name', 'Scene geometry')
patch('Faces', faces, 'Vertices', vertices, 'FaceColor', 'blue', 'FaceAlpha', 0.1)
%patch('Faces', floors, 'Vertices', vertices, 'FaceColor', 'red', 'FaceAlpha', 0.1)
points.text(facevertex.reduce(@mean, faces, vertices), 'FontSize', fontsize, 'Color', 'blue')
points.plot(sourceposition, 'r.', 'MarkerSize', markersize)
points.text(sourceposition, 'FontSize', fontsize)
graphics.axislabels('x', 'y', 'z')
view(3)
rotate3d('on')
% Ray tracing
scene = scenes.Scene(faces, vertices);
startTime = tic;
[downlinks, ~, trace] = rayoptics.analyze( ...
    scene, ...
    sourceposition, ...
    sinkposition, ...
    'ReflectionArities', reflectionarities, ...
    'FreeGain', antennae.friisfunction(frequency), ...
    'SourceGain', sourcegain, ...
    'TransmissionGain', antennae.isopattern(transmissiongain), ...
    'ReflectionGain', antennae.isopattern(reflectiongain), ...
    'SinkGain', antennae.isopattern(0.0), ...
    'Reporting', true, ...
    'AccessPointChannel', [1, 2, 2, 1, 1, 2]);
traceTime = toc(startTime);
fprintf('============== analyze: %g sec ==============\n', traceTime)

% NB: downlinks.GainComponents has three indices with sizes
%["num sink points", "num source points", num reflection arities"].
% Here, for each sink point, we sum (in watts) over source points and 
% reflection arities to determine gain at each sink/sampling point 
% (assuming that summing over source gains is sensible). 
powersumdb = specfun.todb(sum(sum(downlinks.GainComponents, 2), 3));
% Reshape so that gains fit onto our sampling grid
powersumdb = reshape(powersumdb, size(xsink));
sinr = reshape(downlinks.SINRatio, size(xsink));
figure(3), clf
set(gcf, 'Name', 'Gain at receivers (dBW)')
for i = 1 : length(zsinkticks) % number of slices in z
    subplot(size(xsink, 3), 1, i), hold on
    surfc(xsink(:,:,i), ysink(:,:,i), powersumdb(:, :, i), 'EdgeAlpha', 0.0, 'FaceAlpha', 0.7)
    set(gca, 'DataAspectRatio', [1.0, 1.0, 5.0])
    points.plot(sourceposition, 'r.', 'MarkerSize', markersize)
    points.text(sourceposition, 'FontSize', fontsize)
    title(sprintf('Floor %d', i))
    rotate3d on
    caxis([-60, -20])
    colorbar('Location', 'SouthOutside')
    set(gcf, 'PaperOrientation', 'landscape')
    %view(-35, 25) 
    view(2)
end

figure(4), clf
set(gcf, 'Name', 'SINR')
for i = 1 : length(zsinkticks) % number of slices in z
    subplot(size(xsink, 3), 1, i), hold on
    surfc(xsink(:,:,i), ysink(:,:,i), sinr(:, :, i), 'EdgeAlpha', 0.0, 'FaceAlpha', 0.7)
    set(gca, 'DataAspectRatio', [1.0, 1.0, 5.0])
    points.plot(sourceposition, 'r.', 'MarkerSize', markersize)
    points.text(sourceposition, 'FontSize', fontsize)
    title(sprintf('Floor %d', i))
    rotate3d on
    caxis([0, 30])
    colorbar('Location', 'SouthOutside')
    set(gcf, 'PaperOrientation', 'landscape')
    %view(-35, 25) 
    view(2)
end

function result = sourcepattern(phi, theta)
        % This is taken from patternDemo_Filip.m
        mask = theta > pi/2;
        %result = cos(theta).*(phi./phi);
        %result(mask) = 0 * result(mask);
        scaling = -90;
        c = 3d8;
        f = 2.45d9;
        Lambda = c/f;
        L = 0.49*(Lambda/sqrt(2.2));
        W = 2.7*L;
        k = (2*pi)/Lambda;
        sinsin = 0.5*k*W*sin(theta).*sin(phi);
        sincos = 0.5*k*L*sin(theta).*cos(phi);
        result = 20.*(sin(sinsin)./sinsin) .* cos(sincos);
        result(mask) = scaling+result(mask);
end
end