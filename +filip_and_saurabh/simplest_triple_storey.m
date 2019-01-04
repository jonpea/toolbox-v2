clear
fontsize = 10;
markersize = 10;
transmissiongain = -6.0; % [dBw]
reflectiongain = -6.0; % [dBw]
frequency = 2.45e9; % [Hz]
reflectionarities = [0, 1];

% Vertices on regular grid
xvertexgrid = [0.0, 1.0];
yvertexgrid = [0.0, 1.0];
zvertexgrid = [0.0, 1.0, 2.0, 3.0];
[xvertex, tvertex, zvertex] = meshgrid(xvertexgrid, yvertexgrid, zvertexgrid);
vertices = points.meshpoints(xvertex, tvertex, zvertex);
figure(1), clf
set(gcf, 'Name', 'Vertex labelling')
points.plot(vertices, 'r.', 'MarkerSize', markersize)
points.text(vertices, 'FontSize', fontsize)
graphics.axislabels('x', 'y', 'z')
grid('on')

% These indices have been determined manually;
% note that order is important e.g. "1 2 4 3" rather than "1 2 3 4".
walls = [
    1 2 14 13; % lower x wall
    3 4 16 15; % upper x wall
    1 3 15 13; % lower y wall
    2 4 16 14; % upper y wall
    ];
floors = [
    1 2 4 3; % ground floor
    5 6 8 7; % first floor
    9 10 12 11; % second floor
    13 14 16 15; % top ceiling/roof
    ];
faces = [
    walls; 
    floors;
    ];

% Access points 
zfraction = 0.75; % bias towards ceiling
zsourceticks = ...
    zvertexgrid(1 : end - 1)*(1 - zfraction) + ...
    zvertexgrid(2 : end)*zfraction;
sourceposition = [
    [ % first two columns
    0.25, 0.25;
    0.50, 0.50;
    0.75, 0.75;
    ], ...
    zsourceticks(:) % third column
    ];

% Sampling points 
xsinkticks = linspace(xvertexgrid(1), xvertexgrid(end), 40);
ysinkticks = linspace(yvertexgrid(1), yvertexgrid(end), 40);
zfraction = 0.5; % midway between floor and ceiling
zsinkticks = ...
    zvertexgrid(1 : end - 1)*(1 - zfraction) + ...
    zvertexgrid(2 : end)*zfraction;
[xsink, ysink, zsink] = meshgrid(xsinkticks, ysinkticks, zsinkticks);
sinkposition = points.meshpoints(xsink, ysink, zsink);

% Visualize scene
figure(2), clf, hold('on')
set(gcf, 'Name', 'Scene geometry')
patch('Faces', walls, 'Vertices', vertices, 'FaceColor', 'blue', 'FaceAlpha', 0.1)
patch('Faces', floors, 'Vertices', vertices, 'FaceColor', 'red', 'FaceAlpha', 0.1)
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
    'SourceGain', antennae.isopattern(0.0), ...
    'TransmissionGain', antennae.isopattern(transmissiongain), ...
    'ReflectionGain', antennae.isopattern(reflectiongain), ...
    'SinkGain', antennae.isopattern(0.0), ...
    'Reporting', true);
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

figure(3), clf
set(gcf, 'Name', 'Gain at receivers (dBW)')
for i = 1 : length(zsinkticks) % number of slices in z
    subplot(1, size(xsink, 3), i), hold on
    surfc(xsink(:,:,i), ysink(:,:,i), powersumdb(:, :, i), 'EdgeAlpha', 0.1, 'FaceAlpha', 0.7)
    set(gca, 'DataAspectRatio', [1.0, 1.0, 5.0])
    points.plot(sourceposition, 'r.', 'MarkerSize', markersize)
    points.text(sourceposition, 'FontSize', fontsize)
    title(sprintf('Floor %d', i))
    rotate3d on
    caxis([min(powersumdb(:)), max(powersumdb(:))])
    colorbar('Location', 'SouthOutside')
    set(gcf, 'PaperOrientation', 'landscape')
    %view(-35, 25) 
    view(2)
end
