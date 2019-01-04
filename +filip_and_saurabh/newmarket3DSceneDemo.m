%% Analysis of Building 903, Level 4, Newmarket Campus
function newmarket2xDDemo(varargin)
%% Introduction
% This script mirrors the |nelib| program implemented in |yzg001.f90|.

%% Optional arguments
parser = inputParser;
parser.addParameter('LargeScale', true, @islogical)
parser.addParameter('Arities', 0, @isrow)
parser.addParameter('Fraction', 1.0, @isnumeric)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Plotting', true, @islogical)
parser.addParameter('Printing', false, @islogical)
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfunction)
parser.addParameter('Serialize', false, @islogical)
parser.addParameter('StudHeight', 3.0, @isscalar)
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
%% Change to better format

% Extra vertices **after** facevertex.compress!
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

%%
ax = axes(figure(1)); 
clf(ax, 'reset')
patch(ax, 'Faces', faces, 'Vertices', vertices)
points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
points.text(ax, vertices, 'FontSize', 10, 'Color', 'red')
axis('equal')

%%
extruded = facevertex.extrude(faces, vertices, [0.0, options.StudHeight]);
[faces, vertices] = facevertex.fv(extruded);

% Add 3 floor panels
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
scene = options.Scene(faces, vertices);
fv = struct('Faces', faces, 'Vertices', vertices);

%%
numFloors =3;
elevate = @(x, level) x + level*[0, 0, options.StudHeight];
storeys = arrayfun( ...
    facevertex.clone(elevate, fv), 0 : numFloors - 1, ...
    'UniformOutput', false);
combinedStoreys = facevertex.cat(storeys{:});
faces = combinedStoreys.Faces;
vertices = combinedStoreys.Vertices;

% Completely artibrary transmission & reflection coefficients
% for a floor/ceiling panel
materialsdata(end + 1, :) = [-12, -15];
floorceilingmaterialtype = size(materialsdata, 1); % after appending/resizing
floorceilingmaterials = repmat(floorceilingmaterialtype, numfloorpanels, 1);
wallmaterials = [
    wallmaterials;
    floorceilingmaterials;
    ];

wallmaterials = repmat(wallmaterials, numFloors, 1);
% At this point, we have a single scene with material properties that
% is missing only the definition of the floor on the ground storey.

% Add the ground storey's floor
faces = [faces; floor];
wallmaterials = [wallmaterials; floorceilingmaterials];
%%

z0 = [1.5,4.5,7.5];
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
    patch(ax, ...
        'Faces', faces(wallmaterials == 9, :), ...
        'Vertices', vertices, ...
        'FaceAlpha', 0.5, ...
        'FaceColor', graphics.rgb.magenta, ...
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

%% Access point
% THis is needlessly complex implementation.
%new code
% axis1 = matfun.unit([1  -1  0]);
% axis2 = matfun.unit([1  1  1]);
% axis3 = specfun.cross(axis1, axis2);
% frame1 = cat(3, axis1, axis2, axis3);
% frameMatrix1 = [axis1; axis2; axis3];
% origin1 = [0 2 1]; % "local origin"
% 
% axis1 = matfun.unit([1  0 -1]);
% axis2 = matfun.unit([1  1  1]);
% axis3 = specfun.cross(axis1, axis2);
% frame2 = cat(3, axis1, axis2, axis3);
% frameMatrix2 = [axis1; axis2; axis3];
% origin2 = [2 1 0]; % "local origin"

%old code
apangle = deg2rad(-120); % [rad]
aporigin1 = [5, 3, 1.5]; % [m]
aporigin3=[12,3,1.5];
aporigin4 = [22,3, 1.5];
aporigin5 = [5, 3, 4.5]; % [m]
aporigin6=[12,3,4.5];
aporigin7 = [22,3, 4.5];
aporigin8 = [5, 3, 7.5]; % [m]
aporigin9=[12,3,7.5];
aporigin10 = [22,3,7.5];
source.Position = [
    aporigin1;
    %aporigin2; % same as "cat(1, aporigin1, aporigin2)"
    aporigin3;
    aporigin4;
    aporigin5;
    aporigin6;
    aporigin7;
  aporigin8; 
  aporigin9;
  aporigin10; 
    ];
%  source.Position = aporigin1;
%  source.Positiion=aporigin3;
%  source.Positiion=aporigin4;
frame1= cat(3, ... % 1x3x3
    [funfun.pipe(@horzcat, 2, @specfun.upol2cart, apangle), 0.0], ... %local x axis
    [funfun.pipe(@horzcat, 2, @specfun.upol2cart, apangle + pi/2), 0.0], ... %local y axis
    [0, 0, 1]); %local z axis
apanglesample = 75;
frame3=cat(3, ... % 1x3x3
    [funfun.pipe(@horzcat, 2, @specfun.upol2cart, apanglesample), 0.0], ... %local x axis
    [funfun.pipe(@horzcat, 2, @specfun.upol2cart, apanglesample + pi/2), 0.0], ... %local y axis
    [0, 0, 1]);
az = 180;
el = -45;
r = 1; % unit sphere
[x,y,z] = sph2cart(az, el, r);
axis1 = [x, y, z];

[x,y,z] = sph2cart(az, el + pi/2, r);
axis2 = [x, y, z];

axis3 = cross(axis1, axis2);

frame4 = cat(3, axis1, axis2, axis3);
frame1=frame1;

frame2 = frame1;
frame3=frame1;
frame4=frame1;
frame5=frame1;
frame6=frame1;
frame7=frame1;
frame8=frame1;
frame9=frame1;
frame10=frame1;
source.Frame = cat(1, frame1,frame3, frame4,frame5,frame6,frame7,frame8,frame9,frame10); %joining 2 frames along 1st dimension(rows)

% source.Frame = cat(3,aporigin,aporigin1,aporigin2);
frequency = 2.45d9; % [Hz]

%%
% Access point's antenna gain functions
antennafilename = fullfile('+data', 'yuen1b.txt');
dbtype(antennafilename, '1:5')
%%
columns = data.loadcolumns(antennafilename, '%f %f');
source.Pattern = antennae.isopattern(0.0);
source.Gain = antennae.dispatch( ...
    {%source.Pattern, source.Pattern}, [1 2], ...
    source.Pattern source.Pattern}, [1 1 1 1 1 1 1 1 1 1], ...
    antennae.orthocontext(source.Frame, @specfun.cart2sphi, 1));

%%
if options.Plotting
    
    azimuth = linspace(0, 2*pi, 1000);
    radius = source.Gain( ...
        ones(size(azimuth)), ...
        [cos(azimuth(:)), sin(azimuth(:)), zeros(size(azimuth(:)))]);
    figure(2), clf('reset')
    polarplot(azimuth, specfun.fromdb(radius), 'LineWidth', 2.0)
    title('Antenna gain in global coordinates')
    
    figure(1)
    ax = gca;
    hold(ax, 'on')
    graphics.spherical(ax, ...
        @(varargin) specfun.fromdb(source.Gain(varargin{:})), ...
        source.Position, ...
        source.Frame, ...
        'EdgeAlpha', 0.1)
    
    graphics.axislabels(ax, 'x', 'y', 'z')
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
[gridx, gridy, gridz] = meshgrid(x, y, z0);
sink.Position = points.meshpoints(gridx, gridy, gridz);

%%
if options.Plotting
    points.plot(source.Position, 'x', 'Color', graphics.rgb.red, 'MarkerSize', 10)
    if isscalar(sink.Position)
        points.plot(sink.Position, '.', 'Color', graphics.rgb.gray, 'MarkerSize', 1)
    end
end

%% Trace reflection paths
argumentlist = { % saved to file for later reference
    ... @scene.reflections ...
    ... @scene.transmissions ...
    ... scene.NumFacets ...
    scene ...
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
gridp = reshape(gains, [size(gridx), size(gains, 2), size(gains, 3)]); %#ok<NASGU>
save([mfilename, 'powers.mat'], ...
    'gridx', 'gridy', 'gridp', 'scene', ...
    'argumentlist', 'source')
iofun.savebig([mfilename, 'trace.mat'], 'trace')
powersum = reshape(sum(gains, 3), [size(gridx), size(gains, 2)]);

%% Aggregate power at each receiver (field point)
if options.Reporting
    sinkindices = find(interactionGains.InteractionType == rayoptics.NodeTypes.Sink);
    reportpower = accumarray( ...
        trace.Data.ObjectIndex(sinkindices), ...
        interactionGains.TotalGain(sinkindices));
    reportpower = reshape(reportpower, size(gridx));
    assert(isequalfp(reportpower, sum(powersum, 4)))
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
powersumOverAntennae = sum(powersum, 4);

figure(10), clf
for i = 1 : size(gridx, 3) % number of slices in z
    subplot(1, size(gridx, 3), i)
    surfc(gridx(:,:,i), gridy(:,:,i), specfun.todb(powersumOverAntennae(:, :, i)), 'EdgeAlpha', 0.1)
    set(gca, 'DataAspectRatio', [1.0, 1.0, 25])
    title(sprintf('Gain at Receivers (dBW) - floor %d', i))
    rotate3d on
    caxis('auto')
    colorbar
    set(gcf, 'PaperOrientation', 'landscape')
    view(-35, 25)
    
    caxis('auto')
end

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
