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

%%
figure(1), clf
patch( ...
    'Faces', model2d.Faces, ...
    'Vertices', model2d.Vertices, ...
    'FaceColor', 'blue', ...
    'FaceAlpha', 0.2, ...
    'EdgeColor', 'black');
points.text(facevertex.reduce(@mean, model2d), 'Color', 'red')
points.text(model2d.Vertices, 'Color', 'blue')
% xticks(faces)
% yticks(vertices)
view(2)
axis tight, axis equal


%% Three dimensional model
floor = true;
ceiling = true;
wallmodel3d = capfacevertex( ...
    extrudeplan(model2d.Faces, model2d.Vertices, 0.0, studheight), ...
    floor, ceiling);
scene = scenes.scene(wallmodel3d.Faces, wallmodel3d.Vertices);
%%
figure(1), clf, hold on
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
points.text(wallmodel3d.Vertices, 'FontSize', fontsize, 'Color', 'red')
points.text(facevertex.reduce(@mean, wallmodel3d), 'FontSize', fontsize, 'Color', 'blue')
graphics.axislabels('x', 'y', 'z')
axis equal
rotate3d on
points.quiver(scene.Origin, scene.Frame(:, :, 1), 0.2, 'Color', 'red')
points.quiver(scene.Origin, scene.Frame(:, :, 2), 0.2, 'Color', 'green')
points.quiver(scene.Origin, scene.Frame(:, :, 3), 0.2, 'Color', 'blue')
view(60, 5)

%% Sinks
[xmin, ymin, zmin] = elmat.cols(min(wallmodel3d.Vertices, [], 1));
[xmax, ymax, zmax] = elmat.cols(max(wallmodel3d.Vertices, [], 1));
x = linspace(xmin + delta, xmax - delta, numsamplesx);
y = linspace(ymin + delta, ymax - delta, numsamplesy);
z = specfun.affine(zmin, zmax, zquantile);
[sink.Origin, gridx, gridy, ~] = gridpoints(x, y, z);
sink.Gain = 0.0;
%sink = tabularnormalize(sink);
%assert(istabular(sink))

%% Sources
inplanepoint = @(s, t) [
    specfun.affine(xmin, xmax, s), ...
    specfun.affine(ymin, ymax, t), ... % NB: With respect to *first* room
    specfun.affine(zmin, zmax, zquantile)
    ];
source.Origin = inplanepoint(xquantile, yquantile); % [m]
source.Frame = frame([1, 1, 0], [1, -1, 0]);
if multisource
    source.Origin(2, :) = inplanepoint(1 - xquantile, 1 - yquantile);
    source.Origin(3, :) = inplanepoint(1 - xquantile, 0.8*yquantile);
    source.Frame(2, :, :) = frame([1, -1, 0], [1, 1, 0]);
    source.Frame(3, :, :) = frame([-1, 1, 0], [1, 1, 0]);
end
source.Gain = 1.0d0; % [dBW]
source.Frequency = 1d9; % [Hz]
% source = tabularnormalize(source);
% assert(istabular(source))

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
    makepattern('isotropic_one.txt', @elfun.todb);
%makepattern('farfield_patch_centre_cavitywall_timber_extract.txt', @elfun.todb);
[pattern.reflection, interpolant.reflection] = ...
    makepattern('Wall1_TM_refl_1GHz.txt', @elfun.todb, @specfun.wrapquadrant);
%     makepattern('isotropic_tiny.txt', @elfun.todb, @specfun.wrapquadrant);
    
[pattern.transmission, interpolant.transmission] = ...
    makepattern('Wall1_TM_trans_1GHz.txt', @elfun.todb, @specfun.wrapquadrant);
%     makepattern('isotropic_one.txt', @elfun.todb, @specfun.wrapquadrant);

[pattern.concretereflection, interpolant.concretereflection] = ...
    makepattern('concrete_TE_refl_1GHz.txt', @elfun.todb, @specfun.wrapquadrant);

[pattern.concretetransmission, interpolant.concretetransmission] = ...
    makepattern('concrete_TE_trans_1GHz.txt', @elfun.todb, @specfun.wrapquadrant);

%%
figure(2), clf
phi = [0, 0.25, 0.75]*pi/2;
cosphi = cos(phi);
cophi = pi/2 - phi;
numphi = numel(phi);
sourceframe = source.Frame(1, :, :);
for i = 1 : numphi
    
    % A complete circle in the x-y plane
    theta = linspace(0, 2*pi, 5000);
    %theta = paren(cartesiantoangular(sourceframe(:, :, 3)), 2);
    
    dx = cos(theta);
    dy = sin(theta);
    dz = repmat(tan(phi(i)), size(dx));
    dglobal = [dx(:), dy(:), dz(:)];
    [globalangles, globalradii] = cartesiantoangular(dglobal);
    assert(norm(globalangles(:, 1) - cophi(i)) < tol)
    assert(std(globalradii) < tol)
    
    dlocal = applytranspose(sourceframe, dglobal);
    [localangles, ~] = cartesiantoangular(dlocal);
    
    sourceradii = elfun.fromdb(pattern.source(localangles));
    reflectionradii = elfun.fromdb(pattern.reflection(localangles));
    transmissionradii = elfun.fromdb(pattern.transmission(localangles));
    
    
    concretereflectionradii = elfun.fromdb(pattern.concretereflection(localangles));
    concretetransmissionradii = elfun.fromdb(pattern.concretetransmission(localangles));
    
    makeplot = @(row, radii, name) {
        subplot(5, numphi, (row - 1)*numphi + i);
        void(@() hold('on'));
        points.plot(angulartocartesian(globalangles, radii));
        points.plot(angulartocartesian(globalangles, 1.0)); % slice through unit sphere at current elevation
        points.quiver([0 0 0], cosphi(i)*sourceframe(:, :, 3), 0, 'r'); % "zenith" = lobe direction
        points.quiver([0 0 0], cosphi(i)*sourceframe(:, :, 1), 0, 'b'); % complement in xy-plane
        title(sprintf('%s/%.2g^\\circ', name, rad2deg(phi(i))));
        view(2);
        void(@() grid('on'));
        void(@() axis('equal'));
        void(@() drawnow);
        };
    makeplot(1, sourceradii, 's');
    makeplot(2, reflectionradii, 'r');
    makeplot(3, transmissionradii, 't');
    makeplot(4, concretereflectionradii, 'crr');
    makeplot(5, concretetransmissionradii, 'crt');
    
    
    
end

% %% Gain patterns
% gainfunctions = struct( ...
%     'Source', framefunction(pattern.source, source.Frame), ...
%     'Reflection', framefunction(pattern.reflection, scene.Frame), ...
%     'Transmission', framefunction(pattern.transmission, scene.Frame), ...
%     'Sink', power.isofunction(sink.Gain), ...
%     'Free', power.friisfunction(source.Frequency));

%% Trace reflection paths
starttime = tic;
facetofunctionmap = [ones(size(scene.Frame, 1) - 2, 1); 2; 2];
reflectiongains = framefunction( ...
    {pattern.reflection, pattern.concretereflection}, ...
    scene.Frame, ...
    facetofunctionmap);
transmissiongains = framefunction( ...
    {pattern.transmission, pattern.concretetransmission}, ...
    scene.Frame, ...
    facetofunctionmap);
dlinks = power.analyze( ...
    @scene.reflections, ...
    @scene.intersections, ...
    scene.NumFacets, ...
    source.Origin, ...
    sink.Origin, ...    
    'ReflectionArities', arities, ...
    'FreeGain', power.friisfunction(source.Frequency), ...
    'SourceGain', framefunction(pattern.source, source.Frame), ...
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
%     'SourceGain', framefunction(pattern.source, source.Frame), ...
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
%     'SourceGain', framefunction(pattern.source, source.Frame), ...
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
        elfun.fromdb(interactiongains.TotalGain(issink)), ...
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
%     powerdb = elfun.todb(power);
%     powerdbscale = max(powerdb(:)) - min(powerdb(:));
%     
%     % if ~inputyesno('Plot gain surface?') %#ok<UNRCH>
%     %     return
%     % end
%     
%     %%
%     figure(1)
%     %contour(gridx, gridy, elfun.todb(power), 25, 'Fill', 'off', 'ShowText', 'off')
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
powersdb = elfun.todb(powers);
for i = 1 : numarities + 1
    subplot(1, 1 + numarities, i), hold on
    if i <= numarities
        temp = powersdb(:, 1, i);
        titlestring = sprintf('arity %d', arities(i));
    else
        temp = elfun.todb(sum(powers, 3));
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
function varargout = dealarray(x, varargin)
%DEALARRAY Deal elements/slices of an array to individual outputs.
% Examples:
%     >> [a, b, c] = dealarray(triu(ones(3)), 1)
%     a =
%          1
%          0
%          0
%     b =
%          1
%          1
%          0
%     c =
%          1
%          1
%          1
%
%     >> [a, b, c] = dealarray(triu(ones(3)), 2)
%     a =
%          1     1     1
%     b =
%          0     1     1
%     c =
%          0     0     1
%
% See also DEAL, DEALOUT, VARARGOUT.
narginchk(1, 3)
if nargin == 3
    squeezeresult = varargin{end};
else
    squeezeresult = true;
end
assert(islogical(squeezeresult))
shape = size(x);
shape([varargin{:}]) = [];
assert(max(1, nargout) == prod(shape))
varargout = num2cell(x, varargin{:});
varargout = cellfun(@squeeze, varargout, 'UniformOutput', false);

end

% -------------------------------------------------------------------------
function [points, varargout] = gridpoints(varargin)
%GRIDPOINTS Matrix of grid points from grid vectors.
% See also NDGRID.

narginchk(1, nargin)

% Unless at least one of the arguments is already a matrix...
if all(cellfun(@isvector, varargin))
    % ... for grid matrices from the grid vectors
    [varargin{:}] = meshgrid(varargin{:});
end

% Pack grid matrices into the columns of the the points matrix
% i.e. containing the coordinates of one point per row
points = cell2mat(cellfun(@(x) x(:), varargin, 'UniformOutput', false));

assert(size(points, 2) == nargin) % invariant

if 1 < nargout
    % Return grid matrices if requested
    varargout = varargin;
end

end

% -------------------------------------------------------------------------
function abc = frame(a, b)

narginchk(1, 2)

switch size(a, 2)
    
    case 2
        assert(nargin == 1)
        a = matfun.unit(a, 2);
        % Align zenith with x-axis
        abc = cat(3, a, perp(a)); 

    case 3
        % if nargin == 1
        %     % Default is suitable for "2.5-dimensional" frames
        %     assert(a(3) == 0, 'The single argument must lie in the plane')
        %     b = repmat([0, 0, 1], size(a, 1), 1);
        % end
        % assert(isequal(size(a), size(b)))
        % a = unit(a, 2);
        % b = unit(b, 2);
        % % "a is [1 0 0]" ==> "frame is standard frame"
        % abc = cat(3, a, perp(b, a), b);
        if nargin == 1
            b = perp(a);
        end
        assert(isequal(size(a), size(b)))
        a = matfun.unit(a, 2);
        b = matfun.unit(b, 2);
        % "a is [1 0 0]" ==> "frame is standard frame"
        abc = cat(3, a, b, perp(b, a));
        
    otherwise
        error('Argument(s) must have 2 or 3 columns')
        
end

end

% -------------------------------------------------------------------------
function varargout = perp(v, u)
%PERP Orthogonal complements of a matrix of 2-vectors or 3-vectors.
% V=PERP(U) satisfies, in the absence of rounding error,
%     DOT(U(K,:),V(K,:),2) == 0
% and NORM(U(K,:)) == NORM(V(K,:)) for all rows K.
%
% Example in 2D:
% >> perp(2*[1 0; 0 1; 1 1])
% ans =
%      0     2
%     -2     0
%     -2     2
%
% Examples in 3D:
% >> a = rand(5, 3); % an arbitrary set of five 3-vectors
% >> norm(dot(perp(a), a, 2))
% ans =
%    2.0770e-16
%
% >> norm(dot(perp(a, perp(a)), a, 2))
% ans =
%    6.2063e-17
%
% >> norm(dot(perp(a, perp(a)), perp(a), 2))
% ans =
%    8.7771e-17
%
% See also CROSS.

narginchk(1, 2)

if size(v, 2) == 2
    % Special Case: 2D, unary
    % Arbitrary element of orthogonal complement of first argument.
    % The 2D implementation, based on cross(), is faster than
    % the general implementation used, below, for the 3D case.
    assert(nargin == 1 && nargout <= 1)
    assert(ismatrix(v))
    assert(size(v, 2) == 2)
    v(:, 3) = 0;
    u = repmat([0 0 1], size(v, 1), 1);
    w = cross(u, v, 2);
    w(:, 3) = [];
    varargout = {w};
    return
end

if nargin == 2
    % Special Case: 3D, binary
    % Cross product of two input arguments
    assert(nargout <= 1)
    assert(ismatrix(v) && size(v, 2) == 3)
    assert(isequal(size(u), size(v)))
    varargout = {cross(v, u, 2)};
    return
end

assert(nargin == 1)

% Basis for orthogonal complement of 1st argument
% This applies in any number of dimensions
nonuniform = {'UniformOutput', false};
[varargout{1 : max(1, nargout)}] = ...
    cellfun(@perp3row, num2cell(v, 2), nonuniform{:});
varargout = cellfun(@cell2mat, varargout, nonuniform{:});

end

function varargout = perp3row(row)
assert(isrow(row))
varargout = num2cell(null(row)', 2);
end

% -------------------------------------------------------------------------
function varargout = cartesiantoangular(xyz)
%CARTESIANTOANGULAR Transform Cartesian to spherical coordinates.
% See also CART2SPH, SPH2CART

narginchk(1, 1)
nargoutchk(0, 2)

numdimensions = size(xyz, 2);
assert(ismember(numdimensions, 2 : 3))
callbacks = {@convert2d, @convert3d};
convert = callbacks{numdimensions - 1};
[varargout{1 : max(1, nargout)}] = convert(xyz);

end

% -------------------------------------------------------------------------
function [angle, radius] = convert2d(xy)
[x, y] = dealout(num2cell(xy, 1));
angle = atan2(y, x); % azimuth
if nargout == 2
    radius = hypot(x, y);
end
end

% -------------------------------------------------------------------------
function [angles, radius] = convert3d(xyz)
[x, y, z] = elmat.cols(xyz);
hypotxy = hypot(x, y);
angles = [
    0.5*pi - atan2(z, hypotxy), ... % inclination
    atan2(y, x) % azimuth
    ];
if nargout == 2
    radius = hypot(hypotxy, z);
end
end

% -------------------------------------------------------------------------
function y = applytranspose(a, x)
%APPLYTRANSPOSE Apply transpose of square matrices to vectors.
% APPLYTRANSPOSE(A,X) computes SQUEEZE(A(K,:,:))'*SQUEEZE(X(K,:))'
% for each K in 1:SIZE(X,1).
% Note that A(K,I,J) contains the "row I, column J".

narginchk(2, 2)

if size(a, 1) == 1
    % Explicit singleton expansion on first dimension
    a = repmat(a, size(x, 1), 1);
end

shape = size(a);
assert(shape(1) == size(x, 1))
assert(shape(2) == size(x, 2))

% NB: Specification of the second dimension is essential 
% because e.g. 
%     >> size(reshape(zeros(0, 1, 2), 0, []))
%     ans =
%          0     0
% i.e. "0x0" rather than "0x2".
y = reshape(sum(bsxfun(@times, a, x), 2), shape(1), shape(2));
%y = reshape(sum(a.*x, 2), shape(1), shape(2));

end

% -------------------------------------------------------------------------
function out = void(f, out)
if nargin == 1
    out = 1; 
end
f();
end

% -------------------------------------------------------------------------
function xyz = angulartocartesian(angles, radii)
%ANGULARTOCARTESIAN Transform spherical to Cartesian coordinates.
% See also CARTESIANTOSPHERICAL, SPH2CART, CART2SPH

narginchk(1, 2)
if nargin < 2 || isempty(radii)
    radii = 1.0;
end

numangles = size(angles, 2);
assert(ismember(numangles, 1 : 2))
callbacks = {@polartocartesian, @sphericaltocartesian};

convert = callbacks{numangles};
xyz = convert(angles, radii);

end

function xy = polartocartesian(phi, r)
xy = [
    r .* cos(phi), ...
    r .* sin(phi)
    ];

end

function xyz = sphericaltocartesian(angles, r)
[theta, phi] = elmat.cols(angles);
rsintheta = r .* sin(theta);
xyz = [
    rsintheta .* cos(phi), ...
    rsintheta .* sin(phi), ...
    r .* cos(theta)
    ];
end

% -------------------------------------------------------------------------
function evaluator = framefunction(functions, frames, facetofunction)

narginchk(2, 3)

if ~iscell(functions)
    functions = {functions};
end

if nargin < 3 || isempty(facetofunction)
    assert(isscalar(functions))
    facetofunction = ones(size(frames, 1), 1);
end

% Preconditions
assert(isfvframe(frames))
assert(iscell(functions))
assert(all(cellfun(@datatypes.isfunction, functions)))
assert(all(ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)

        %assert(size(directions, 2) == 2, ...
        %    'Jon: For 3D problems, you should probably use framefunctionnew!')
        
        assert(isvector(faceindices))
        assert(ismatrix(directions))
                
        % Transform global Cartesian coordinates
        % to those relative to faces' local frames
        localdirections = applytranspose( ...
            frames(faceindices, :, :), directions);
        
        % Angles relative to local frame
        angles = cartesiantoangular(localdirections);

        gain = indexedunary( ...
            functions, ...
            facetofunction(faceindices), ...
            angles);

    end

evaluator = @evaluate;

end

% -------------------------------------------------------------------------
function result = isfvframe(f)
%ISFVFRAME True for unit frames stored by rows.
% See also FVFRAMES.
unit = ones('like', f);
tol = eps(10*unit); % relative to 1.0
result = ...
    isnumeric(f) ...
    && ndims(f) == 3 ...
    && ismember(size(f, 2), 2 : 3) ...
    && size(f, 2) == size(f, 3) ...
    && all(ops.vec(abs(matfun.norm(f, 2, 2) - unit)) < tol);
end

% -------------------------------------------------------------------------
function result = indexedunary(functions, funofrow, x, varargin)
%INDEXEDUNARY Evaluate functionals of one row-indexed argument.

narginchk(3, nargin)
assert(iscell(functions))
if isscalar(funofrow)
    funofrow = repmat(funofrow, size(x, 1), 1);
end
assert(size(x, 1) == numel(funofrow))
assert(ndims(x) <= 4)

result = zeros(size(x, 1), 1);
    function apply(fun, rows)
        result(rows, :) = fun(x(rows, :, :, :), varargin{:});
    end
rowsoffun = invertindices(funofrow, numel(functions));
cellfun(@apply, functions(:), rowsoffun(:));

end

% -------------------------------------------------------------------------
function inverted = invertindices(indices, numgroups)
narginchk(1, 2)
if nargin == 2
    shape = [numgroups, 1];
else
    shape = [];
end
indexrange = 1 : numel(indices);
inverted = accumarray(indices(:), indexrange(:), shape, @(a) {a(:)});
if isempty(indices)
    % Corner case: If the input list is empty, then accumarray 
    % doesn't realize that the result should be a cell array (of empties)
    inverted = repmat({zeros(0, 1)}, size(inverted));
end
end
