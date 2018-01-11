%% Analysis of Building 903, Level 4, Newmarket Campus
function yzg0012d(varargin)
%% Introduction
% This script mirrors the |nelib| program implemented in |yzg001.f90|.

%% Optional arguments
parser = inputParser;
parser.addParameter('LargeScale', true, @islogical)
parser.addParameter('Arities', 0 : 2, @isrow)
parser.addParameter('Fraction', 1.0, @isnumeric)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Plotting', false, @islogical)
parser.addParameter('Printing', false, @islogical)
parser.addParameter('Scene', @scenes.completescene, @datatypes.isfunction)
parser.addParameter('Serialize', false, @islogical)
parser.addParameter('XGrid', [], @isvector)
parser.addParameter('YGrid', [], @isvector)
parser.addParameter('CullDuplicateFaces', false, @islogical)
parser.parse(varargin{:})
options = parser.Results;

%% Wall plan & materials set
[linevertices, materialsdata, wallmaterials] = data.building903level4;

[faces, vertices] = facevertex.compress(facevertex.xy2fv( ...
    linevertices(:, [1 3])', ...
    linevertices(:, [2 4])'));

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

scene = options.Scene(faces, vertices);

materials = struct( ...
    'TransmissionGain', materialsdata(wallmaterials, 1), ...
    'ReflectionGain', materialsdata(wallmaterials, 2));

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
    points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
    points.text(ax, vertices, 'FontSize', 7)
    set(ax, 'XTick', [0, 30.5], 'YTick', [0, 7.5])
    axis(ax, 'tight')
    axis(ax, 'equal')
    grid(ax, 'on')
end

%% Access point
apangle = deg2rad(200); % [rad]
aporigin = [13.0, 6.0]; % [m]
radius = 1.0; % [m]
direction = funfun.pipe(@horzcat, 2, @pol2cart, apangle, radius);
codirection = funfun.pipe(@horzcat, 2, @pol2cart, apangle + pi/2, radius);
source = scenes.accesspointtable( ...
    aporigin, ...
    'Frame', cat(3, direction, codirection), ...
    'Frequency', 2.45d9); % [Hz]

%%
% Access point's antenna gain functions
sourcepattern = data.loadpattern(fullfile('+data', 'yuen1b.txt'), @elfun.todb);
if options.Plotting
    
    allangles = linspace(0, 2*pi, 100);
    radius = elfun.fromdb(sourcepattern(allangles));
    
    figure(2), clf('reset')
    polarplot(allangles, radius, 'b.'), title('AP gain (dBW)')
    
    figure(1), hold on
    temp = power.framefunctionnew(sourcepattern, source.Frame);
    graphics.polar( ...
        @(varargin) elfun.fromdb(temp(varargin{:})), ...
        source.Position, ...
        source.Frame, ...
        'Azimuth', allangles, ...
        'Color', 'red')
    
    axis equal
    grid on
    
end

%% Mobiles / receive points
if ~isempty(options.XGrid)
    assert(~isempty(options.YGrid))
    x = options.XGrid;
    y = options.YGrid;
elseif options.LargeScale
    x = linspace(0.1, 30.4, max(fix(options.Fraction*305), 2));
    y = linspace(0.1, 7.4, max(fix(options.Fraction*75), 2));
else
    assert(options.Fraction == 1.0, ...
        'Only one grid point is used if LargeScale is false')
    x = 4.0;
    y = 4.0;
end
[gridx, gridy] = meshgrid(x, y);
sinkorigins = points.meshpoints(gridx, gridy);
sink = mobiletable(sinkorigins);

%%
if options.Plotting
    points.plot(source.Position, 'x', 'Color', graphics.rgb.red, 'MarkerSize', 10)
    if isscalar(sink.Position)
        points.plot(sink.Position, '.', 'Color', graphics.rgb.gray, 'MarkerSize', 1)
    end
end

%% Trace reflection paths
argumentlist = { % saved to file for later reference
    imagemethod.reflectionPoints(scene) ...
    scene.Intersect ...
    scene.NumFacets ...
    source.Position ...
    sink.Position ...
    ... %scene ...
    'ReflectionArities', options.Arities ...
    'FreeGain', power.friisfunction(source.Frequency) ...
    'SourceGain', power.framefunctionnew(sourcepattern, source.Frame) ...
    'TransmissionGain', power.isofunction(materials.TransmissionGain) ...
    'ReflectionGain', power.isofunction(materials.ReflectionGain) ...
    'SinkGain', power.isofunction(0.0) ...
    'Reporting', options.Reporting ...
    };
starttime = tic;
[downlinks, ~, interactions] = power.analyze(argumentlist{:});
tracetime = toc(starttime);
fprintf('============== analyze: %g sec ==============\n', tracetime)

%% Compute gains and display table of interactions
if options.Reporting
    
    fprintf('\nComputed %u paths\n\n', ...
        numel(unique(interactions.Data.Identifier)))
    
    starttime = tic;
    interactiongains = power.computegain(interactions);
    powertime = toc(starttime);
    fprintf('============== computegain: %g sec ==============\n', powertime)
    
    assert(datatypes.struct.tabular.istabular(interactiongains))
    
    %% Distribution of interaction nodes
    disp('From stored interaction table')
    disp(struct2table(imagemethod.interactionstatistics(interactions.Data.InteractionType)))
    
    %% Distribution of received power
    [gainstats, powertable] = power.gainstatistics(interactiongains);
    disp(struct2table(gainstats))
    
    %%
    issink = interactiongains.InteractionType == imagemethod.interaction.Sink;
    assert(isequalfp( ...
        elfun.fromdb(interactiongains.TotalGain(issink)), ...
        interactiongains.Power(issink)))
    
    missingarities = setdiff(0 : max(options.Arities), options.Arities);
    assert(all(ops.vec(powertable(:, :, missingarities + 1) == 0)))
    assert(isequalfp(downlinks.PowerComponentsWatts, powertable(:, :, options.Arities + 1)))
    disp('calculated powers do match :-)')
    
    %%
    fprintf('Timing\n')
    fprintf('______\n')
    fprintf(' computing nodes: %g sec\n', tracetime)
    fprintf(' computing gains: %g sec\n', powertime)
end

%% Power distributions
powers = downlinks.PowerComponentsWatts;
distribution = power.reflectionstatistics(powers);
disp(struct2table(distribution))

%%
if options.Reporting && options.Serialize
    numinteractions = datatypes.struct.tabular.height(interactiongains);
    if 1e6 < numinteractions
        prompt = sprintf( ...
            'Proceed to save %d rows to .mat file? {yes | no} ', ...
            numinteractions);
        response = input(prompt, 's');
        switch validatestring(lower(response), {'yes', 'no'})
            case 'yes'
                fprintf('saving results to %s.mat\n', mfilename)
                savebig(mfilename, 'interactiongains', 'distribution')
            case 'no'
                fprintf('skipped serialization\n');
        end
    end
end

%%
gridp = reshape(powers, [size(gridx), size(powers, 3)]); %#ok<NASGU>
save([mfilename, 'powers.mat'], ...
    'gridx', 'gridy', 'gridp', 'scene', ...
    'argumentlist', 'sourcepattern', 'source')
iofun.savebig([mfilename, 'interactions.mat'], 'interactions')
powersum = reshape(sum(powers, 3), size(gridx));

%% Aggregate power at each receiver
if options.Reporting
    sinkindices = find(interactiongains.InteractionType == imagemethod.interaction.Sink);
    reportpower = accumarray( ...
        interactions.Data.ObjectIndex(sinkindices), ...
        interactiongains.Power(sinkindices));
    reportpower = reshape(reportpower, size(gridx));
    assert(isequalfp(reportpower, powersum))
    disp('calculated powers do match :-)')
end

if ~options.Plotting
    return
end

if min(size(gridx)) == 1
    fprintf('Ignoring ''Plotting'' for grid of size %s\n', mat2str(size(gridx)))
    return
end

%%
surfc(gridx, gridy, elfun.todb(powersum), 'EdgeAlpha', 0.1)
set(gca, 'DataAspectRatio', [1.0, 1.0, 25])
title('Gain at Receivers (dBW)')
rotate3d on
colorbar
set(gcf, 'PaperOrientation', 'landscape')
view(-35, 25)

%%
if ~options.Printing
    % Printing to file is *very* time-consuming
    printnow = @(prefix) ...
        print('-dpdf', '-bestfit', ...
        sprintf('%s_%dx%d', prefix, size(gridx, 1), size(gridx, 2)));
    printnow('surf_front')
    view(-125, 15)
    printnow('surf_back')
end

% -------------------------------------------------------------------------
function tf = isequalfp(a, b, tol)
if nargin < 3
    tol = 1e-12;
end
a = a(:);
b = b(:);
tf = max(abs(a - b) ./ (0.5*(abs(a) + abs(b)) + 1)) < tol;
