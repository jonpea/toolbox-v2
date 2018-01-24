%% Simplest 2.5D test case with "n" rooms
function Lrooms2dconcrete(numrooms, varargin)

if nargin < 1 || isempty(numrooms)
    numrooms = 4;
end
assert(isscalar(numrooms) && isnumeric(numrooms))

%%
parser = inputParser;
parser.addParameter('Arities', 0 : 2, @isvector)
parser.addParameter('MultiSource', false, @islogical)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('NumSamplesX', 200, @isscalar)
parser.addParameter('NumSamplesY', 400, @isscalar)
parser.addParameter('QuantileX', 0.1, @isscalar)
parser.addParameter('QuantileY', 0.9, @isscalar)
parser.addParameter('QuantileZ', 0.0, @isscalar)
parser.addParameter('Delta', 1e-3, @isscalar)
parser.addParameter('GainThreshold', -20, @isscalar)
parser.parse(varargin{:})
options = parser.Results;

%% Configuration
arities = options.Arities;
multisource = options.MultiSource;
reporting = options.Reporting;
xquantile = options.QuantileX;
yquantile = options.QuantileY;
zquantile = options.QuantileZ;
numsamplesx = options.NumSamplesX;
numsamplesy = options.NumSamplesY;
delta = options.Delta; % spacing of sink points from exterior wall
gainthreshold = options.GainThreshold; % cut-off around sources

%%
t0 = tic;
tol = 1e-12;
fontsize = 8;

%% Two dimensional model
mm2m = @(x) x/1000;
studheight = mm2m(3300);
model2d.Faces= [1,6;7,12;1,7;2,8;3,9;4,10;5,11;6,12;1,2;7,8;13,14;15,16;17,18;19,20;1,19;2,20;21,22;21,23];
model2d.Vertices= [0,0;0,3.2;0,6.4;0,9.6;0,12.8;0,16;3.2,0;3.2,3.2;3.2,6.4;3.2,9.6;3.2,12.8;3.2,16;6.4,0;6.4,3.2;9.6,0;9.6,3.2;12.8,0;12.8,3.2;16,0;16,3.2;4.8,4.8;4.8,11.2;11.2,4.800];
% Additional "orphan" index for floor and ceiling
model2d.Vertices(end + 1, :) = [16, 16];

%%
figure(1), clf
patch( ...
    'Faces', model2d.Faces, ...
    'Vertices', model2d.Vertices, ...
    'FaceColor', 'blue', ...
    'FaceAlpha', 0.2, ...
    'EdgeColor', 'black');
points.text(facevertex.reduce(@mean, model2d), 'Color', 'blue')
points.text(model2d.Vertices, 'Color', 'red')
view(2)
axis tight, axis equal


%% Three dimensional model
wallmodel3d = facevertex.extrude(model2d, [0, studheight]);
% wallmodel3d.Faces(end + 1, :) = facevertex.cap(@min, 3, wallmodel3d);
% wallmodel3d.Faces(end + 1, :) = facevertex.cap(@max, 3, wallmodel3d);
scene = scenes.Scene(wallmodel3d.Faces, wallmodel3d.Vertices);

facetofunctionmap = [ones(size(scene.Frame, 1) - 2, 1); 2; 2];

%%
figure(1), clf, hold on
patch( ...
    'Faces', wallmodel3d.Faces(facetofunctionmap == 1, :), ...
    'Vertices', wallmodel3d.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'LineWidth', 2, ...
    'EdgeColor', 'blue', ...
    'FaceColor', 'blue');
patch( ...
    'Faces', wallmodel3d.Faces(facetofunctionmap == 2, :), ...
    'Vertices', wallmodel3d.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'LineWidth', 5, ...
    'EdgeColor', 'red', ...
    'FaceColor', 'red');
points.text(wallmodel3d.Vertices, 'FontSize', fontsize, 'Color', 'red')
points.text(facevertex.reduce(@mean, wallmodel3d), 'FontSize', fontsize, 'Color', 'blue')
graphics.axislabels('x', 'y', 'z')
axis equal
rotate3d on
points.quiver(scene.Origin, scene.Frame(:, :, 1), 0.2, 'Color', 'red')
points.quiver(scene.Origin, scene.Frame(:, :, 2), 0.2, 'Color', 'blue')
points.quiver(scene.Origin, scene.Frame(:, :, 3), 0.2, 'Color', 'green')
view(60, 5)

%% Sinks
[xmin, ymin, zmin] = elmat.cols(min(wallmodel3d.Vertices, [], 1));
[xmax, ymax, zmax] = elmat.cols(max(wallmodel3d.Vertices, [], 1));
x = linspace(xmin + delta, xmax - delta, numsamplesx);
y = linspace(ymin + delta, ymax - delta, numsamplesy);
z = specfun.affine(zmin, zmax, zquantile);
% [gridx, gridy, gridz] = meshgrid(x, y, z);
% sink.Origin = [gridx(:), gridy(:), gridz(:)];
[gridx, gridy, gridz] = meshgrid(x, y, z);
sink.Origin = [gridx(:), gridy(:), gridz(:)];
sink.Gain = 0.0;

%% Sources
inplanepoint = @(s, t) [
    specfun.affine(xmin, xmax, s), ...
    specfun.affine(ymin, ymax, t), ... % NB: With respect to *first* room
    specfun.affine(zmin, zmax, zquantile)
    ];
source.Origin = inplanepoint(xquantile, yquantile); % [m]
v1 = [1, 1, 0];
v2 = [1, -1, 0];
source.Frame = cat(3, matfun.unit(v1), matfun.unit(v2), matfun.unit(cross(v1, v2)));
if multisource
    source.Origin(2, :) = inplanepoint(1 - xquantile, 1 - yquantile);
    source.Origin(3, :) = inplanepoint(1 - xquantile, 0.8*yquantile);
    source.Frame(2, :, :) = frame([1, -1, 0], [1, 1, 0]);
    source.Frame(3, :, :) = frame([-1, 1, 0], [1, 1, 0]);
end
source.Gain = 1.0d0; % [dBW]
source.Frequency = 1d9; % [Hz]

%%
points.plot(source.Origin, '.', 'Color', 'red', 'MarkerSize', 20)
points.quiver(source.Origin, source.Frame(:, :, 1), 0, 'Color', 'green') % out-of-plane
points.quiver(source.Origin, source.Frame(:, :, 2), 0, 'Color', 'blue')
points.quiver(source.Origin, source.Frame(:, :, 3), 0, 'Color', 'red') % "zenith" (in-plane)
if size(sink.Origin, 1) < 100
    points.plot(sink.Origin, '.', 'Color', rgbgray, 'MarkerSize', 10)
end
rotate3d on

%% Source antennae gain functions
makepattern = @(name, varargin) ...
    data.loadpattern(fullfile('+data', name), varargin{:});
[pattern.source, interpolant.source] = ...
    makepattern('isotropic_one.txt', @specfun.todb);
[pattern.reflection, interpolant.reflection] = ...
    makepattern('Wall1_TM_refl_1GHz.txt', @specfun.todb, @specfun.wrapquadrant);
[pattern.transmission, interpolant.transmission] = ...
    makepattern('Wall1_TM_trans_1GHz.txt', @specfun.todb, @specfun.wrapquadrant);
[pattern.concretereflection, interpolant.concretereflection] = ...
    makepattern('concrete_TE_refl_1GHz.txt', @specfun.todb, @specfun.wrapquadrant);
[pattern.concretetransmission, interpolant.concretetransmission] = ...
    makepattern('concrete_TE_trans_1GHz.txt', @specfun.todb, @specfun.wrapquadrant);

%%
figure(2), clf
phi = [0, 0.25, 0.75]*pi/2;
cosphi = cos(phi);
cophi = pi/2 - phi;
numphi = numel(phi);
sourceframe = source.Frame(1, :, :);

% ----->>
subplot(2, 3, 1)
graphics.spherical( ...
    power.framefunction(pattern.source, source.Frame), ...
    source.Origin, ...
    source.Frame, ...
    'Azimuth', linspace(0, 2*pi, 200), ...
    'Inclination', linspace(0, pi, 100), ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
axis equal

subplot(2, 3, 2)
graphics.spherical( ...
    power.framefunction(pattern.reflection, source.Frame), ...
    source.Origin, ...
    source.Frame, ...
    'Azimuth', linspace(0, 2*pi, 200), ...
    'Inclination', linspace(0, pi, 100), ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
axis equal

subplot(2, 3, 3)
graphics.spherical( ...
    power.framefunction(pattern.transmission, source.Frame), ...
    source.Origin, ...
    source.Frame, ...
    'Azimuth', linspace(0, 2*pi, 200), ...
    'Inclination', linspace(0, pi, 100), ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
axis equal

subplot(2, 3, 4)
graphics.spherical( ...
    power.framefunction(pattern.concretetransmission, source.Frame), ...
    source.Origin, ...
    source.Frame, ...
    'Azimuth', linspace(0, 2*pi, 200), ...
    'Inclination', linspace(0, pi, 100), ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
axis equal

subplot(2, 3, 5)
graphics.spherical( ...
    power.framefunction(pattern.concretereflection, source.Frame), ...
    source.Origin, ...
    source.Frame, ...
    'Azimuth', linspace(0, 2*pi, 200), ...
    'Inclination', linspace(0, pi, 100), ...
    'EdgeAlpha', 0.1, ...
    'FaceAlpha', 1.0)
axis equal

% % <<-----
% for i = 1 : numphi
%     
%     % A complete circle in the x-y plane
%     theta = linspace(0, 2*pi, 5000);
%     %theta = paren(cartesiantoangular(sourceframe(:, :, 3)), 2);
%     
%     dx = cos(theta);
%     dy = sin(theta);
%     dz = repmat(tan(phi(i)), size(dx));
%     dglobal = [dx(:), dy(:), dz(:)];
%     [globalangles, globalradii] = cartesiantoangular(dglobal);
%     assert(norm(globalangles(:, 1) - cophi(i)) < tol)
%     assert(std(globalradii) < tol)
%     
%     dlocal = applytranspose(sourceframe, dglobal);
%     [localangles, ~] = cartesiantoangular(dlocal);
%     
%     sourceradii = fromdb(pattern.source(localangles));
%     reflectionradii = fromdb(pattern.reflection(localangles));
%     transmissionradii = fromdb(pattern.transmission(localangles));
%     
%     
%     concretereflectionradii = fromdb(pattern.concretereflection(localangles));
%     concretetransmissionradii = fromdb(pattern.concretetransmission(localangles));
%     
%     makeplot = @(row, radii, name) {
%         subplot(5, numphi, (row - 1)*numphi + i);
%         void(@() hold('on'));
%         points.plot(angulartocartesian(globalangles, radii));
%         points.plot(angulartocartesian(globalangles, 1.0)); % slice through unit sphere at current elevation
%         points.quiver([0 0 0], cosphi(i)*sourceframe(:, :, 3), 0, 'r'); % "zenith" = lobe direction
%         points.quiver([0 0 0], cosphi(i)*sourceframe(:, :, 1), 0, 'b'); % complement in xy-plane
%         title(sprintf('%s/%.2g^\\circ', name, rad2deg(phi(i))));
%         view(2);
%         void(@() grid('on'));
%         void(@() axis('equal'));
%         void(@() drawnow);
%         };
%     makeplot(1, sourceradii, 's');
%     makeplot(2, reflectionradii, 'r');
%     makeplot(3, transmissionradii, 't');
%     makeplot(4, concretereflectionradii, 'crr');
%     makeplot(5, concretetransmissionradii, 'crt');
%     
% end

% %% Gain patterns
% gainfunctions = struct( ...
%     'Source', framefunction(pattern.source, source.Frame), ...
%     'Reflection', framefunction(pattern.reflection, scene.Frame), ...
%     'Transmission', framefunction(pattern.transmission, scene.Frame), ...
%     'Sink', power.isofunction(sink.Gain), ...
%     'Free', power.friisfunction(source.Frequency));

%% Trace reflection paths
starttime = tic;
reflectiongains = power.framefunction( ...
    {pattern.reflection, pattern.concretereflection}, ...
    scene.Frame, ...
    facetofunctionmap);
transmissiongains = power.framefunction( ...
    {pattern.transmission, pattern.concretetransmission}, ...
    scene.Frame, ...
    facetofunctionmap);
dlinks = rayoptics.analyze( ...
    @scene.reflections, ...
    @scene.transmissions, ...
    scene.NumFacets, ...
    source.Origin, sink.Origin, ...
    'ReflectionArities', arities, ...
    'FreeGain', power.friisfunction(source.Frequency), ...
    'SourceGain', power.framefunction(pattern.source, source.Frame), ...
    'ReflectionGain', reflectiongains, ...
    'TransmissionGain', transmissiongains, ...
    'SinkGain', power.isofunction(sink.Gain), ...
    'Reporting', reporting); 
powers = dlinks.PowerComponentsWatts;
% %[powers, ~, tracestats, trace] = tracescenenew( ...
% [powers, ~, trace] = tracescenenew( ...
%     source.Origin, sink.Origin, scene, ...
%     'PathArities', arities, ...
%     'FreeGain', power.friisfunction(source.Frequency), ...
%     'SourceGain', power.framefunction(pattern.source, source.Frame), ...
%     'ReflectionGain', reflectiongains, ...
%     'TransmissionGain', transmissiongains, ...
%     'SinkGain', power.isofunction(sink.Gain), ...
%     'Reporting', reporting); 
tracetime = toc(starttime);
fprintf('============== tracescene: %g sec ==============\n', tracetime)

% powers2 = tracescenenew( ...
%     source.Origin, sink.Origin, scene, ...
%     'ReflectionArities', arities, ...
%     'FreeGain', power.friisfunction(source.Frequency), ...
%     'SourceGain', power.framefunction(pattern.source, source.Frame), ...
%     'ReflectionGain', reflectiongains, ...
%     'TransmissionGain', transmissiongains, ...
%     'SinkGain', power.isofunction(sink.Gain), ...
%     'Reporting', reporting);
% 
% compare(powers, powers2)




%% Compute gains and display table of interactions
if reporting
    starttime = tic;
    interactiongains = computegain(trace);
    powertime = toc(starttime);
    fprintf('============== computegain: %g sec ==============\n', powertime)
    
    assert(istabular(interactiongains))
    
    %% Distribution of interaction nodes
    disp('From stored interaction table')
    tabulardisp(interactionstatistics(trace.Data.InteractionType))
    
    %% Distribution of received power
    [gainstats, powertable] = gainstatistics(interactiongains);
    tabulardisp(gainstats)
    
    %%
    issink = interactiongains.InteractionType == interaction.Sink;
    assert(isequalfp( ...
        fromdb(interactiongains.TotalGain(issink)), ...
        interactiongains.Power(issink)))
    assert(isequalfp(powers, powertable, tol))
    disp('calculated powers do match :-)')
    
    %%
    fprintf('\nTiming\n______\n')
    fprintf(' computing nodes: %g sec\n', tracetime)
    fprintf(' computing gains: %g sec\n', powertime)
    fprintf('   all processes: %g sec\n', toc(t0))
    
end

% %% Elapsed times
% tabulardisp(tracestats)

%% Power distributions
aritypower = squeeze(sum(sum(powers, 1), 2)); % total power at each arity
totalpower = sum(aritypower);
relativepower = aritypower ./ totalpower;
select = arities(:) + 1;
disp(array2table( ...
    [arities(:), aritypower(select), 100*relativepower(select)], ...
    'VariableNames', {'Arity', 'Power', 'RelativePower'}))

%%

% if reporting
%     fprintf('saving results to %s.mat\n', mfilename)
%     savebig(mfilename, 'interactiongains', ...
%         'aritypower', 'totalpower', 'relativepower')
% end

%% Aggregate power at each receiver
if isvector(gridx) || isvector(gridy)
    return
end

% if reporting
%     sinkindices = find(interactiongains.InteractionType == interaction.Sink);
%     power = accumarray( ...
%         trace.Data.ObjectIndex(sinkindices), ...
%         interactiongains.Power(sinkindices));
%     power = reshape(power, size(gridx));
%     powerdb = specfun.todb(power);
%     powerdbscale = max(powerdb(:)) - min(powerdb(:));
%     
%     % if ~inputyesno('Plot gain surface?') %#ok<UNRCH>
%     %     return
%     % end
%     
%     %%
%     figure(1)
%     %contour(gridx, gridy, specfun.todb(power), 25, 'Fill', 'off', 'ShowText', 'off')
%     surf(gridx, gridy, powerdb, 'EdgeAlpha', 0.0, 'FaceAlpha', 1.0)
%     set(gca, 'DataAspectRatio', [1.0, 1.0, powerdbscale]) % ** for use with meshc **
%     %title('Gain at Receivers (dBW)')
%     colorbar('Location', 'eastoutside')
%     set(gcf, 'PaperOrientation', 'landscape')
%     view(2)
%     axis off, axis tight
%     rotate3d on
% end

%%
fprintf('============ total elapsed time: %g sec ============\n', toc(t0))

figure(3), clf, colormap(jet)
numarities = numel(arities);
powersdb = specfun.todb(powers);
for i = 1 : numarities + 1
    subplot(1, 1 + numarities, i), hold on
    if i <= numarities
        temp = powersdb(:, 1, i);
        titlestring = sprintf('arity %d', arities(i));
    else
        temp = specfun.todb(sum(powers, 3));
        titlestring = 'total';
    end
    temp = reshape(temp, size(gridx)); % 1st transmitter only
    surf(gridx, gridy, temp, ...
        'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
    caxis([min(temp(:)), min(max(temp(:)), gainthreshold)])
    contour(gridx, gridy, temp, 10, 'Color', 'white', 'LineWidth', 1)
    title(titlestring)
    patch( ...
        'Faces', wallmodel3d.Faces(1 : end - 2, :), ...
        'Vertices', wallmodel3d.Vertices, ...
        'FaceAlpha', 0.05, ...
        'EdgeAlpha', 0.3, ...
        'FaceColor', 'blue');
    patch( ...
        'Faces', wallmodel3d.Faces(end - 1 : end, :), ...
        'Vertices', wallmodel3d.Vertices, ...
        'FaceAlpha', 0.05, ...
        'EdgeAlpha', 0.3, ...
        'FaceColor', 'red');
    view(2)
    axis equal
    axis tight
    axis off
    rotate3d on
    colorbar('Location', 'southoutside')
    totalpower = reshape(sum(powers, 3), size(gridx));
    save totalpower.mat totalpower
end

save(mfilename)

return

% figure(1)
% print('-dpdf', '-bestfit', 'tworoom3d-profile.pdf')
% 
% figure(2)
% print('-dpdf', '-bestfit', 'tworoom3d-patterns.pdf')
% 
% return
% if ~inputyesno('Print plot?')
%     return
% end
% 
% %%
% printnow = @(prefix) ...
%     print('-dpdf', '-bestfit', sprintf('%s_%dx%d', prefix, nx, ny));
% printnow('surf_front')
% view(-125, 15)
% printnow('surf_back')

