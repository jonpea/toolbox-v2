%% Analysis of Building 903, Level 4, Newmarket Campus
function newmarket2DDemo(varargin)
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
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfunction)
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
source.Position = aporigin;
source.Frame = cat(3, ...
    funfun.pipe(@horzcat, 2, @specfun.circ2cart, apangle), ...
    funfun.pipe(@horzcat, 2, @specfun.circ2cart, apangle + pi/2));
frequency = 2.45d9; % [Hz]

%%
% Access point's antenna gain functions
antennafilename = fullfile('+data', 'yuen1b.txt');
dbtype(antennafilename, '1:5')
%%
columns = data.loadcolumns(antennafilename, '%f %f');
source.Pattern = griddedInterpolant( ...
    deg2rad(columns.phi), specfun.todb(columns.gain));
source.Gain = antennae.dispatch( ...
    source.Pattern, 1, ...
    antennae.orthocontext(source.Frame, @specfun.cart2circ));

%%
if options.Plotting
    
    azimuth = linspace(0, 2*pi, 1000);
    radius = source.Gain( ...
        ones(size(azimuth)), ...
        [cos(azimuth(:)), sin(azimuth(:))]);
    figure(2), clf('reset')
    polarplot(azimuth, specfun.fromdb(radius), 'LineWidth', 2.0)
    title('Antenna gain in global coordinates')
    
    figure(1)
    ax = gca;
    hold(ax, 'on')
    graphics.polar(ax, ...
        @(varargin) specfun.fromdb(source.Gain(varargin{:})), ...
        source.Position, ...
        source.Frame, ...
        'Azimuth', azimuth, ...
        'Color', 'red')
    graphics.axislabels(ax, 'x', 'y')
    colormap(ax, jet)
    colorbar(ax)
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
[gridx, gridy] = meshgrid(x, y);
sink.Position = points.meshpoints(gridx, gridy);

%%
if options.Plotting
    points.plot(source.Position, 'x', 'Color', graphics.rgb.red, 'MarkerSize', 10)
    if isscalar(sink.Position)
        points.plot(sink.Position, '.', 'Color', graphics.rgb.gray, 'MarkerSize', 1)
    end
end

%% Trace reflection paths
argumentlist = { % saved to file for later reference
    @scene.reflections ...
    @scene.transmissions ...
    scene.NumFacets ...
    source.Position ...
    sink.Position ...
    'ReflectionArities', options.Arities ...
    'FreeGain', antennae.friisfunction(frequency) ...
    'SourceGain', source.Gain ...
    'TransmissionGain', antennae.isopattern(materials.TransmissionGain) ...
    'ReflectionGain', antennae.isopattern(materials.ReflectionGain) ...
    'SinkGain', antennae.isopattern(0.0) ...
    'Reporting', options.Reporting ...
    };
startTime = tic;
[downlinks, ~, trace] = rayoptics.analyze(argumentlist{:});
traceTime = toc(startTime);
fprintf('============== analyze: %g sec ==============\n', traceTime)

%% Power distributions
gains = downlinks.GainComponents;
distribution = rayoptics.distributionTable(gains);
disp(struct2table(distribution))

%% Compute gains and display table of interactions
if options.Reporting
    
    fprintf('\nComputed %u paths\n\n', rayoptics.trace.numpaths(trace))
    
    startTime = tic;
    interactionGains = rayoptics.trace.computegain(trace);
    powerTime = toc(startTime);
    fprintf('============== computegain: %g sec ==============\n', powerTime)
    
    %% Distribution of interaction nodes
    disp('From stored interaction table')
    disp(struct2table(rayoptics.trace.frequencies(trace)))
    
    %% Distribution of received power
    [gainStats, gainComponents] = rayoptics.trace.process(trace);
    disp(struct2table(gainStats))
    
    %% Sanity check
    import datatypes.struct.structsfun
    assert(max(structsfun( ...
        @(a,b) norm(a-b,inf), distribution, gainStats)) < tol)
    assert(isequalfp( ...
        downlinks.GainComponents, ....
        gainComponents(:, :, options.Arities + 1)))
    disp('calculated powers do match :-)')
    
    %%
    fprintf('Timing\n')
    fprintf('______\n')
    fprintf(' computing nodes: %g sec\n', traceTime)
    fprintf(' computing gains: %g sec\n', powerTime)
end

%%
if options.Reporting && options.Serialize
    numinteractions = datatypes.struct.tabular.height(interactionGains);
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
gridp = reshape(gains, [size(gridx), size(gains, 3)]); %#ok<NASGU>
save([mfilename, 'powers.mat'], ...
    'gridx', 'gridy', 'gridp', 'scene', ...
    'argumentlist', 'source')
iofun.savebig([mfilename, 'trace.mat'], 'trace')
powersum = reshape(sum(gains, 3), size(gridx));

%% Aggregate power at each receiver (field point)
if options.Reporting
    sinkindices = find(interactionGains.InteractionType == rayoptics.NodeTypes.Sink);
    reportpower = accumarray( ...
        trace.Data.ObjectIndex(sinkindices), ...
        interactionGains.TotalGain(sinkindices));
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
surfc(gridx, gridy, specfun.todb(powersum), 'EdgeAlpha', 0.1)
set(gca, 'DataAspectRatio', [1.0, 1.0, 25])
title('Gain at Receivers (dBW)')
rotate3d on
colorbar
set(gcf, 'PaperOrientation', 'landscape')
view(-35, 25)

%%
if options.Printing
    % Printing to file is *very* time-consuming
    printnow = @(prefix) ...
        print('-dpdf', '-bestfit', ...
        sprintf('%s_%dx%d', prefix, size(gridx, 1), size(gridx, 2)));
    printnow('surf_front')
    view(-125, 15)
    printnow('surf_back')
end

end

% -------------------------------------------------------------------------
function tf = isequalfp(a, b)
a = a(:);
b = b(:);
tf = max(abs(a - b) ./ (0.5*(abs(a) + abs(b)) + 1)) < tol;
end

% -------------------------------------------------------------------------
function tol = tol
tol = 1e-12;
end
