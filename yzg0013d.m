%% Analysis of Building 903, Level 4, Newmarket Campus
function yzg0013d(varargin)

parser = inputParser;
parser.addParameter('LargeScale', true, @islogical)
parser.addParameter('MultiSource', false, @islogical)
parser.addParameter('Arities', 0 : 2, @isrow)
parser.addParameter('Fraction', 1.0, @isnumeric)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Plotting', false, @islogical)
parser.addParameter('Printing', false, @islogical)
parser.addParameter('Scene', @completescene, @isfunction)
parser.addParameter('Serialize', false, @islogical)
parser.addParameter('SPMD', isscalar(currentpool), @islogical)
parser.addParameter('StudHeight', 3.0, @isscalar)
parser.addParameter('Verbosity', 0, @isscalar)
parser.addParameter('XGrid', [], @isvector)
parser.addParameter('YGrid', [], @isvector)
parser.addParameter('CullDuplicateFaces', false, @islogical)
parser.parse(varargin{:})
options = parser.Results;

%% Introduction
% This script mirrors the |nelib| program implemented in |yzg001.f90|.

%% Constants
t0 = tic;
format compact
fprintf('NDEBUG = %u\n', ndebug)

%%
disabletimer
disablegpu % enablegpu | disablegpu
resetgpu

global UNIQUEFACES
UNIQUEFACES = options.CullDuplicateFaces;

%% Wall plan & materials set
[linevertices, materialsdata, wallmaterials] = building903level4;
[faces, vertices] = linestofacevertex(linevertices);
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
[faces, vertices] = extrudeplan(faces, vertices, 0.0, options.StudHeight);
scene = options.Scene(faces, vertices);
%scene = axisalignedmultifacet(fvtoaxisalignedbounds(faces, vertices));
z0 = (0.0 + options.StudHeight)/2;

%%
materials.TransmissionGain = materialsdata(wallmaterials, 1);
materials.ReflectionGain = materialsdata(wallmaterials, 2);
%%
if options.Plotting
    figure(1), clf('reset'), hold on
    plan = patch( ...
        'Faces', faces, ...
        'Vertices', vertices, ...
        'FaceColor', 'blue', ...
        'FaceAlpha', 0.2, ...
        'EdgeColor', rgbgray, ...
        'LineWidth', 1);
    labelfacets(plan, 'FontSize', 7, 'Color', 'black')
    labelpoints(vertices, 'FontSize', 7)
    set(gca, 'XTick', [0, 30.5], 'YTick', [0, 7.5])
    axis tight, axis equal, grid on
    plotframes(scene.Origin, scene.Frame, 0, 'Color', 'red')
    %view(3)
end

%% Access point
origin = [13.0, 6.0, z0]; % [m]
direction = angulartocartesian(deg2rad(200));
codirection = perp(direction(1 : 2)); % (**) to guarantee consistency with 2D case
[direction(3), codirection(3)] = deal(0.0);
if options.MultiSource
    origin(end + 1, :) = [20, 4];
    direction(end + 1, :) = angulartocartesian(deg2rad(45));
end
source = accesspointtable( ...
    origin, ...
    'Frame', cat(3, direction, codirection, [0, 0, 1]), ... % (**)
    'Frequency', 2.45d9); % [Hz]

%%
% Access point's antenna gain functions
zeniths = source.Frame(:, :, 1);
% antennapatternfilename = fullfile('data', 'yuen1b3d.txt');
% sourcepattern = loadpattern(antennapatternfilename, @todb);
% antennapatternfilename = fullfile('data', 'yuen1b.txt');
% sourcepattern = embeddedpattern(loadpattern(antennapatternfilename, @todb));
sourcepattern = embeddedpattern(loadpattern(fullfile('data', 'yuen1b.txt'), @todb));
if options.Plotting
    allangles = gridpoints(pi/2, linspace(0, 2*pi, 1000));
    inclination = allangles(:, 1);
    azimuth = allangles(:, 2);
    assert(all(inclination == pi/2))
    radius = fromdb(sourcepattern(allangles));
    figure(2), clf('reset'), hold on
    polar(azimuth, radius, 'b.')
    
    figure(1), hold on
    sourceangle = cartesiantoangular(source.Frame(:, 1 : 2, 1));
    for i = 1 : size(source.Position, 1)
        origin = source.Position(i, 1 : 2);
        pattern = bsxfun(@plus, origin, ...
            angulartocartesian(azimuth + sourceangle(i), radius(:)));
        circular = bsxfun(@plus, origin, ...
            angulartocartesian(azimuth, 0.5*max(radius(:))));
        pattern(:, 3) = z0;
        circular(:, 3) = z0;
        plotpoints(pattern, 'Color', 'magenta')
        plotpoints(circular, 'Color', 'black')
    end
    axis equal
    grid on
    ax = gca;
    plotradialintensity(ax, ...
        framefunctionnew(sourcepattern, frame(zeniths)), ...
        source.Position, ...
        source.Frame, ...
        'EdgeAlpha', 0.1)
    labelaxes('x', 'y', 'z', 'Parent', ax)
    colormap(ax, jet)
    colorbar(ax) % ('Location', 'southoutside')
    axis(ax, 'equal')
    grid(ax, 'on')
    rotate3d(ax, 'on')
    view(ax, 3)
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
[sinkorigins, gridx, gridy] = gridpoints(x, y, z0);
sink = mobiletable(sinkorigins);

%%
if options.Plotting
    plotpoints(source.Position, 'x', 'Color', 'red', 'MarkerSize', 10)
    if isscalar(sink.Position) || true
        plotpoints(sink.Position, '.', 'Color', 'blue', 'MarkerSize', 2)
    end
end

%% Trace reflection paths
arguments = {
    source.Position, sink.Position, scene ...
    'ReflectionArities', options.Arities ...
    'FreeGain', friisfunction(source.Frequency) ...
    'SourceGain', framefunctionnew(sourcepattern, source.Frame) ...
    'TransmissionGain', isofunction(materials.TransmissionGain) ...
    'ReflectionGain', isofunction(materials.ReflectionGain) ...
    'SinkGain', isofunction(0.0) ...
    'Reporting', options.Reporting ... 
    'Verbosity', options.Verbosity ...
    'SPMD', options.SPMD ...
    };

starttime = tic;
[downlinks, ~, interactions] = analyze(arguments{:});
tracetime = toc(starttime);
fprintf('============== analyze: %g sec ==============\n', tracetime)

%% Compute gains and display table of interactions
if options.Reporting 

    starttime = tic;
    interactiongains = computegain(interactions);
    powertime = toc(starttime);
    fprintf('============== computegain: %g sec ==============\n', powertime)
    
    assert(istabular(interactiongains))
    
    %% Distribution of interaction nodes
    disp('From stored interaction table')
    tabulardisp(interactionstatistics(interactions.Data.InteractionType))
    
    %% Distribution of received power
    [gainstats, powertable] = gainstatistics(interactiongains);
    tabulardisp(gainstats)
    
    %%
    issink = interactiongains.InteractionType == interaction.Sink;
    assert(isequalfp( ...
        fromdb(interactiongains.TotalGain(issink)), ...
        interactiongains.Power(issink)))
    
    missingarities = setdiff(0 : max(options.Arities), options.Arities);
    assert(all(vec(powertable(:, :, missingarities + 1) == 0)))
    assert(isequalfp(downlinks.PowerComponentsWatts, powertable(:, :, options.Arities + 1)))
    disp('calculated powers do match :-)')
    
    %%
    fprintf('\nTiming\n______\n')
    fprintf(' computing nodes: %g sec\n', tracetime)
    fprintf(' computing gains: %g sec\n', powertime)
    fprintf('   all processes: %g sec\n', toc(t0))
    
end

%% Power distributions
powers = downlinks.PowerComponentsWatts;
distribution = reflectionstatistics(powers);
tabulardisp(distribution)

%%
if options.Reporting && options.Serialize
    numinteractions = tabularsize(interactiongains);
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
if options.MultiSource
    disp('Aborting: Subsequent code is not intended for MultiSource')
    return
end
gridp = reshape(powers, [size(gridx), size(powers, 3)]); %#ok<NASGU>
save([mfilename 'powers.mat'], 'gridx', 'gridy', 'gridp', ...
    'scene', 'arguments', 'sourcepattern', 'source')
% savebig([mfilename 'interactions.mat'], 'interactions')
power = reshape(sum(powers, 3), size(gridx));

%% Aggregate power at each receiver
if options.Reporting
    sinkindices = find(interactiongains.InteractionType == interaction.Sink);
    reportpower = accumarray( ...
        interactions.Data.ObjectIndex(sinkindices), ...
        interactiongains.Power(sinkindices));
    reportpower = reshape(reportpower, size(gridx));
    assert(isequalfp(reportpower, power))
    disp('calculated powers do match :-)')
end

if ~options.Plotting
    return
end

%%
surfc(gridx, gridy, todb(power), 'EdgeAlpha', 0.1)
set(gca, 'DataAspectRatio', [1.0, 1.0, 25])
title('Gain at Receivers (dBW)')
rotate3d on
colorbar
set(gcf, 'PaperOrientation', 'landscape')
view(-35, 25)

if ~options.Printing
    % Printing to file consumes a *lot* of time
    return
end

%%
printnow = @(prefix) ...
    print('-dpdf', '-bestfit', ...
    sprintf('%s_%dx%d', prefix, size(gridx, 1), size(gridx, 2)));
printnow('surf_front')
view(-125, 15)
printnow('surf_back')

end
