function butterworthDemo(varargin)
% Optimization of anchor calcuations to correct angle-dependent attenuation
% coefficients (calculated from plane waves in CST Studio) with constant
% offsets to reduce mismatch with a small numbe rof empirical measurements.

%%
allrx = 1 : 53;
missingrx = [14 36 37 38]; % receivers for which measurements are not available
availablerx = setdiff(allrx, missingrx);
cornerrx = [16, 28, 42, 46]; %#ok<NASGU> % ':' | 1:53 | [a, b, c]

allrooms = 1 : 16;
availablerooms = setdiff(allrooms, 6); %#ok<NASGU>
cornerrooms = [1, 4, 7, 11];

%% Fixed parameters
parser = inputParser;
% Transmitter/receiver configuration
parser.addParameter('FloorIndex', 8, @(n) n == 8) % do not change
parser.addParameter('MaxNumReflections', 1, @(n) isscalar(n) && 0 <= n)
parser.addParameter('RxIndices', availablerx, @isnumeric)
parser.addParameter('TxIndices', [9, 12], @(a) isequal(sort(a(:)), [9; 12])) % do not change
parser.addParameter('Polarity', 'TM', @(s) ismember(s, {'TE', 'TM'}))
parser.addParameter('NumPoints', 3, @(n) isscalar(n) && 0 < n)
parser.addParameter('RoomIndices', cornerrooms, @isnumeric)
% Scene geometry
parser.addParameter('CommonHeight', 11, @isscalar) % [m]
parser.addParameter('VerticalGap', 1, @isscalar) % [m]
parser.addParameter('ThreeDimensional', true, @islogical)
parser.addParameter('DoorHeight', 2.2, @isscalar) % [m]
parser.addParameter('StudHeight', 3.0, @isscalar) % [m]
parser.addParameter('WithCeiling', true, @islogical)
parser.addParameter('WithDoors', true, @islogical)
parser.addParameter('WithFloor', true, @islogical)
% Optimization
parser.addParameter('BFOEpsilon', 1e-1, @isscalar) % BFO stopping tolerance
parser.addParameter('BFOMaxEval', 1, @isscalar) % BFO iteration limit
% Image method
parser.addParameter('Verbosity', 0, @isscalar) 
% Visualization
parser.addParameter('Figure', 1, @isscalar) % integer
parser.addParameter('GridPlot', false, @islogical) % true | false
parser.addParameter('GridPlotDensity', 80, @(n) isscalar(n) && 2 <= n)
parser.addParameter('FigFileName', '', @ischar)
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfunction)
parser.parse(varargin{:})

%%
settings = parser.Results;
if isempty(settings.FigFileName)
	settings.FigFileName = sprintf( ...
        '%s-x%d-%s.fig', ...
        mfilename, ...
        settings.MaxNumReflections, ...
        datestr(now, 'dd.mmm.yy-HH.MM.SS'));    
end

%% Prepare tabbed graphics window
settings.Figure = figure(settings.Figure);
if ~isempty(settings.FigFileName)
    cleaner = onCleanup(@() ...
        savefig(settings.Figure, settings.FigFileName, 'compact'));
end
clf(settings.Figure, 'reset')
set(settings.Figure, ...
    'Name', sprintf('%d-reflected rays', settings.MaxNumReflections), ...
    'NumberTitle', 'on', ...
    'Visible', 'off') % suppress in published output until...
newtab = graphics.tabbedfigure(settings.Figure, 'Visible', 'on'); % ... first use

%% Load propagation measurement campaign data

% Receiver (RX) and transmitter (TX) coordinates
rxpositions = data.butterworth.butterworthrxpositions;
txpositions = data.butterworth.butterworthtxpositions;

% The given points are only two dimensional (apply to all floors)
rxpositions(:, 3) = settings.CommonHeight;
txpositions(:, 3) = settings.CommonHeight;

% If necessary, replaces ':' with an explicit list
settings.RxIndices = colon2sub(settings.RxIndices, size(rxpositions, 1));
settings.TxIndices = colon2sub(settings.TxIndices, size(txpositions, 1));

% % Retain only the combinations specified by the analyst
% rxpositions = rxpositions(settings.RxIndices, :);
txpositions = txpositions(settings.TxIndices, :);
assert(~any(isnan(txpositions(:))))

% Load gain data from disk
datapath = fullfile( ...
    '.', '+data', '+butterworth', 'narrowband', ...
    'engineeringtower', '12 Transmitter Retest');
filenames = sort(cellstr(ls(fullfile(datapath, '*.txt'))));
rxidentifiers = cellfun(@(s) sscanf(s, '%d.txt'), filenames);
[pairings, ~, txfrequencies] = data.pmcfloordata( ...
    filenames, ...
    'FilePath', datapath, ...
    'TransmitterIndices', settings.TxIndices, ...
    'ReceiverIdentifiers', rxidentifiers, ...
    'NumDimensions', 3);

% Sort un-ordered pairing data so that rows and columns of
% resulting array correspond to (base-1) TX/RX indices
measured = accumarray( ...
    [pairings.ReceiverIdentifier + 1, pairings.TransmitterOffset], ...
    pairings.Mean, ...
    [], [], nan);

% Averages of measured gains from Keith Butterworth's own spreadsheet
gaindata = data.butterworth.butterworthgain;
% Note that the seemingly large tolerance is employed because
% the spreadsheet data are literal values (as opposed to values
% calcuated from formulae) and are quoted only to ~5 decimal places
assert(isequalfp(measured, [gaindata.TX9, gaindata.TX12], 1e-6))
assert(all(min(gaindata.Identifier) <= rxidentifiers))
assert(all(max(gaindata.Identifier) >= rxidentifiers))
clear datapath filenames gaindata pairings rxidentifiers

% Sanity checks, essential for "2.5D" configuration
if settings.ThreeDimensional
    txheight = unique(txpositions(:, 3));
    rxheight = unique(rxpositions(:, 3));
    assert(isscalar(txheight)) % sanity check
    assert(isscalar(rxheight)) % sanity check
    assert(rxheight == txheight)
    % Insert vertical offset between transmitters & receivers
    rxpositions = rxpositions - [0, 0, settings.VerticalGap];
    clear rxheight txheight
end

%% Scene geometry
[scene.Faces, scene.Vertices, scene.PanelType] = ...
    data.engineeringtower8data3dnew( ...
    'Convention', 'butterworth', ...
    'FloorHeight', (settings.FloorIndex - 5)*settings.StudHeight, ...
    'DoorHeight', settings.DoorHeight, ... % "closed door" if doors are used
    'StudHeight', settings.StudHeight, ...
    'WithDoors', settings.WithDoors, ...
    'WithFloor', settings.WithFloor, ...
    'WithCeiling', settings.WithCeiling);

assert( ... % sanity checks
    min(scene.Vertices(:, 3)) <= settings.CommonHeight && ...
    max(scene.Vertices(:, 3)) >= settings.CommonHeight)

scene.Model = settings.Scene(scene.Faces, scene.Vertices);

%%
lower = min(scene.Vertices, [], 1);
upper = max(scene.Vertices, [], 1);
widths = upper - lower;
delta = 0.0;
lower = lower + delta*widths;
upper = upper - delta*widths;
numpoints = ceil(widths./min(widths)*settings.NumPoints);
rxgridpoints = gridpoints( ...
    linspace(lower(1), upper(1), numpoints(1)), ...
    linspace(lower(2), upper(2), numpoints(2)), ...
    linspace(lower(3), upper(3), numpoints(3)));

%%
rxdata = struct( ...
    'Index', settings.RxIndices(:), ...
    'Position', rxpositions, ...
    'Grid', rxgridpoints);
txdata = struct( ...
    'Index', settings.TxIndices(:), ...
    'Position', txpositions, ...
    'Frequency', txfrequencies(:));
clear rxpositions txpositions txfrequencies

%%
ax = axes(newtab('Configuration'));
hold(ax, 'on')
drawentities(ax)
points.plot(ax, rxdata.Position, 'bx', 'MarkerSize', 10, 'LineWidth', 2)
points.plot(ax, rxdata.Position(settings.RxIndices, :), 'rs', 'MarkerSize', 10, 'LineWidth', 2)
points.plot(ax, txdata.Position, 'r.', 'MarkerSize', 20)
points.text(ax, rxdata.Position)
points.plot(rxgridpoints, 'x')
rotate3d(ax, 'on')
%view(ax, -50, 70)
view(ax, -30, 75)
%view(2)

%% Remove any receivers for which measured data is unavailable
nanrows = find(all(isnan(measured), 2));
points.plot(ax, rxdata.Position(nanrows, :), 'bo', 'MarkerSize', 10, 'LineWidth', 2)
% measured(nanrows, :) = [];
assert(~any(ismember(rxdata.Index, nanrows)))
% rxdata.Position(nanrows, :) = [];
% rxdata.Index(ismember(rxdata.Index, nanrows)) = [];
fprintf('Measurements not recorded @ rx: %s\n', mat2str(nanrows))

%% Attenuation coefficients
% NB: Uniform initital values of -5.0 with TM coefficients 
% to produce the most interesting/plausible fitted corrections
bfosettings = datatypes.cell2table({
    'Description',           'XLower',  'XUpper',  'X0';
    'GibReflection',            -inf,      0.0,    -1.0; %-4.6;
    'ConcreteReflection',       -inf,      0.0,    -1.0; %-4.8;
    'GibTransmission',          -inf,      0.0,    -1.0; %-3.3;
    'ConcreteTransmission',     -inf,      0.0,    -1.0; %-0.0;
    });
disp(bfosettings)

%%
facetofunctionmap = arrayfun(@paneltofunctionindex, scene.PanelType);
    function index = paneltofunctionindex(type)
        switch type
            case {'GibWall', 'GlassWindow', 'SteelDoor', 'WoodenDoor'}
                index = 1;
            case {'Ceiling', 'ConcreteWall', 'Floor' }
                index = 2;
            otherwise
                error('Unexpected type: %s', char(type))
        end
    end

    function pattern = loadquadpattern(filename)
        pattern = data.loadpatternnew(fullfile('+data', filename), ...
            'OutputTransform', @specfun.todb, ...
            'InputTransform', @specfun.wrapquadrant);
    end

    function fun = makegainfunctions(patterns, offsets)
        offsetpatterns = cellfun(@(pattern, offset) ...
            @(varargin) pattern(varargin{:}) + offset, ...
            patterns(:), num2cell(offsets(:)), ...
            'UniformOutput', false);
        fun = framefunctionnew(offsetpatterns, ...
            scene.Model.Frame, facetofunctionmap);
    end

polarity = @(s) sprintf(s, settings.Polarity);
reflectionfiles = {
    polarity('gib_eng_tower_%s_refl_1.8GHz.txt')
    polarity('concrete_lossy_%s_refl_1.8GHz.txt')
    };
transmissionfiles = {
    polarity('gib_eng_tower_%s_trans_1.8GHz.txt')
    polarity('concrete_lossy_%s_trans_1.8GHz.txt')
    };
reflectionpatterns = cellfun(@loadquadpattern, reflectionfiles, 'UniformOutput', false);
transmissionpatterns = cellfun(@loadquadpattern, transmissionfiles, 'UniformOutput', false);

    function showpattern(tabname, name1, name2, local)
        function decorate(ax, patternname, local)
            local.standardorigin = zeros(1, 3);
            local.standardframe = reshape(eye(3), 1, 3, 3);
            local.framefunction = framefunctionnew( ...
                loadquadpattern(patternname), ...
                local.standardframe);
            plotradialintensity(ax, ...
                local.framefunction, ...
                local.standardorigin, ...
                local.standardframe, ...
                'EdgeAlpha', 0.1)
            title(ax, patternname, ...
                'Interpreter', 'none') % ignores underscore
            graphics.axislabels(ax, 'x', 'y', 'z')
            colormap(ax, jet)
            colorbar(ax, 'Location', 'southoutside')
            axis(ax, 'equal')
            grid(ax, 'on')
            rotate3d(ax, 'on')
            view(ax, 3)
        end
        local.tab = newtab(tabname);
        decorate(subplot(1, 2, 1, 'Parent', local.tab), name1)
        decorate(subplot(1, 2, 2, 'Parent', local.tab), name2)
    end

showpattern('Reflection', reflectionfiles{:})
showpattern('Transmission', transmissionfiles{:})

%%
plan.Rooms = data.engineeringtower8rooms; % relative to 2D (not 3D) plan
[plan.Faces, plan.Vertices] = data.engineeringtower8data2dnew;
    function id = partition(positions)
        id = polygonpartition(plan.Rooms, plan.Vertices, positions(:, 1 : 2));
    end
    function result = averageof(positions, values, local)
        assert(size(positions, 1) == size(values, 1))
        assert(size(positions, 2) == 3)
        local.partitionid = partition(positions);
        % Use "cell2mat(..)" rather than "UnformOutput" so as 
        % to accommodate column-wise averages (with multiple columns)
        local.means = cellfun( ...
            @(indices) mean(values(indices, :), 1, 'omitnan'), ...
            local.partitionid, 'UniformOutput', false);
        result = cell2mat(local.means);
    end

centroids = averageof(rxdata.Position, rxdata.Position);
meangain = @(positions, db) specfun.todb(averageof(positions, specfun.fromdb(db)));
meanmeasured = meangain(rxdata.Position, measured);

assert(~any(ops.vec(isnan(meanmeasured(settings.RoomIndices, :)))), ...
    'Some selected rooms contain no measured data')

%%
cache = struct('FBest', realmax);
    function value = objective(x, local)
        local.computed = compute(x, rxdata.Grid);
        local.meancomputed = meangain(rxdata.Grid, local.computed);
        local.difference = local.meancomputed - meanmeasured;
        local.discrepancies = local.difference(settings.RoomIndices, :);
        value = norm(local.discrepancies(:), 2);
        if value < cache.FBest
            cache.Gain = local.computed;
            cache.MeanGain = local.meancomputed;
            cache.FBest = value;
            cache.XBest = x;
        end
        save('..\objective.mat', 'x', 'local', 'value', 'rxdata')
    end

    function [gain, components] = compute(x, rxpositions, local)
        assert(numel(x) == 4)
        local.xreflection = x(1 : 2); % "[gib, concrete]" reflection
        local.xtransmission = x(3 : 4); % "[gib, concrete]" transmission
        % local.downlinks = analyze( ...
        %     txdata.Position, rxpositions, scene.Model, ...
        temp = scene.Model; % necessary work-around: MATLAB doesn't like "@scene.Model.reflections"
        local.downlinks = rayoptics.analyze( ...
            @temp.reflections, ...
            @temp.transmissions, ...
            scene.Model.NumFacets, ...
            txdata.Position, ...
            rxpositions, ...
            'ReflectionArities', 0 : settings.MaxNumReflections, ...
            'FreeGain', antennae.friisfunction(txdata.Frequency), ...
            'ReflectionGain', makegainfunctions(reflectionpatterns, local.xreflection), ...
            'TransmissionGain', makegainfunctions(transmissionpatterns, local.xtransmission));
            ... 'NDEBUG', true, ...
            ... 'SPMD', isscalar(parallel.currentpool), ...
            ... 'Verbosity', settings.Verbosity);
        gain = local.downlinks.GainDBW;
        components = specfun.todb(local.downlinks.GainComponents);
        save('..\compute.mat', 'local', 'gain', 'components', 'scene')
    end

% Note Well: BFO doesn't like @"mfilename"/objective, so there
% must exist an M-file "objective.m" (whose contents are irrelevant)
t0 = tic;
[xbest, fbest, msg, wrn, neval, fhist, ~] = bfo( ...
    @(x) objective(x), bfosettings.X0, ...
    'max-or-min', 'min', ...
    'xtype', repmat('c', size(bfosettings.X0)), ...
    'xlower', bfosettings.XLower, ...
    'xupper', bfosettings.XUpper, ...
    'epsilon', settings.BFOEpsilon, ...
    'maxeval', settings.BFOMaxEval); %#ok<ASGLU>
fprintf('[Elapsed time is %g seconds]\n', toc(t0))
clear quiet t0 xlower xupper xtype

%%
assert(isequal(cache.FBest, fbest))
assert(isequal(cache.XBest, xbest))
meancomputed = cache.MeanGain;
signederror = meancomputed - meanmeasured;
relabserror = abs(signederror)./abs(meanmeasured);

%%
% meancomputed = meangain(computed);

%%
% tabulardisp(struct( ...
%     'Receiver', rxdata.Index, ...
%     'MeasuredDB', measured, ...
%     'ComputedDB', computed, ...
%     'SignedErrorDB', signederror, ...
%     'RelativeErrorPerCent', 100*relabserror))

%%
fprintf('F0 = %g, FBest = %g\n', fhist(1), fbest)
disp(setfield(bfosettings, 'XBest', xbest)) %#ok<SFLD>
clear msg wrn neval fbest fhist
%%
infnorm = @(a) max(abs(a), [], 1, 'omitnan');
decimalplaces = @(a) ceil(log10(max(a(:)))) + 3; 
mat2strfp = @(a) mat2str(a, decimalplaces(a));
fprintf('max. absolute error = %s\n', mat2strfp(infnorm(signederror)))
fprintf('max. relative error = %s\n', mat2strfp(infnorm(relabserror)))

%%
    function comparepoints(positions, data, tabtitle, cscale, markersize, local)
        if nargin < 5
            markersize = 80;
        end
        local.tab = newtab(tabtitle);
        local.numtx = numel(txdata.Index);
        for k = 1 : local.numtx
            local.ax = subplot(1, local.numtx, k, 'Parent', local.tab);
            hold(local.ax, 'on')
            title(local.ax, sprintf('TX%d', txdata.Index(k)))
            drawentities(local.ax)
            points.plot(local.ax, txdata.Position(k, :), 'r+', 'MarkerSize', 20)
            points.scatter(local.ax, positions, ...
                markersize, data(:, k), 'MarkerFaceColor', 'flat')
            colormap(local.ax, jet)
            if 4 <= nargin && ~isempty(cscale)
                caxis(local.ax, cscale)
            end
            colorbar(local.ax, 'Location', 'southoutside')
            view(local.ax, 2)
        end
    end

%%
colorscale = minmax([meanmeasured(:); meancomputed(:)])';
comparepoints(centroids, meanmeasured, 'Gain (dB)', colorscale)
%%
comparepoints(centroids, meancomputed, 'GainRT (dB)', colorscale)
%%
comparepoints(centroids, signederror, 'GainRT - Gain (dB)');
%%
comparepoints(centroids, 100*relabserror, 'Rel |Error| (%)');
%%
if settings.GridPlot
    extents = minmax(scene.Vertices, 1);
    makepoints = @(i) linspace(extents(1, i), extents(2, i), settings.GridPlotDensity);
    points3d = gridpoints(makepoints(1), makepoints(2), settings.CommonHeight);
    [~, components] = compute(xbest, points3d);
    colorscale = minmax(components(:))';
    for i = 0 : settings.MaxNumReflections
        comparepoints( ...
            points3d, components(:, :, 1 + i), ...
            sprintf('Component %d', i), colorscale, 5);
    end
end

%%
    function drawrooms(ax, colors, local)
        local.height = settings.CommonHeight - settings.VerticalGap - 0.5;
        local.embed = @(x) [x, repmat(local.height, size(x(:, 1)))];
        local.handle = patch(ax, ...
            'Faces', fvfaces(plan.Rooms), ...
            'Vertices', local.embed(plan.Vertices), ...
            'FaceColor', 'flat', ...
            'FaceVertexCData', colors, ...
            'FaceAlpha', 0.75);
        cellfun(@(mask, color) ...
            points.scatter(rxdata.Grid(mask, :), [], repmat(color, sum(mask), 1), 'filled'), ...
            partition(rxdata.Grid), ...
            num2cell(colors(:)))
    end
ax = axes(newtab('Rooms'));
hold(ax, 'on')
drawentities(ax)
colormap(ax, jet(numel(plan.Rooms)))
drawrooms(ax, (1 : numel(plan.Rooms))')
points.plot(ax, rxdata.Position, 'x')
points.plot(ax, centroids, 'o', 'MarkerFaceColor', 'red')
points.text(ax, centroids, 'FontSize', 20)
view(ax, 3)
colorbar(ax)

%%
    function comparemeans(positions, data, tabtitle, cscale, markersize, local)
        if nargin < 5
            markersize = 80;
        end
        local.tab = newtab(tabtitle);
        local.numtx = numel(txdata.Index);
        for k = 1 : local.numtx
            local.ax = subplot(1, local.numtx, k, 'Parent', local.tab);
            hold(local.ax, 'on')
            title(local.ax, sprintf('TX%d', txdata.Index(k)))
            drawentities(local.ax)
            points.plot(local.ax, txdata.Position(k, :), 'r+', 'MarkerSize', 20)
            points.scatter(local.ax, positions, ...
                markersize, data(:, k), 'MarkerFaceColor', 'flat')
            colormap(local.ax, jet)
            if 4 <= nargin && ~isempty(cscale)
                caxis(local.ax, cscale)
            end
            colorbar(local.ax, 'Location', 'southoutside')
            drawrooms(local.ax, data(:, k))
            view(local.ax, 2)
        end
    end

colorscale = minmax([meanmeasured(:); meancomputed(:)])';
comparemeans(centroids, meanmeasured, 'Mean (dB)', colorscale)
%%
comparemeans(centroids, meancomputed, 'MeanRT (dB)', colorscale)
%%
comparemeans(centroids, meancomputed - meanmeasured, 'MeanRT - Mean (dB)')
%%
clear ax centroids colorscale
clear component downlinks extends makepoints points3d

%%
    function drawentities(ax, local)
        % Adds elements common to all plots
        local.shift = 0.3;
        local.labels = compose('TX%d', txdata.Index);
        function drawwalls(type, color, width, alpha)
            if nargin < 4
                alpha = 0.2;
            end
            patch(ax, ...
                'Faces', scene.Faces(scene.PanelType == type, :), ...
                'Vertices', scene.Vertices, ...
                'FaceAlpha', alpha, ...
                'FaceColor', color, ...
                'EdgeColor', color, ...
                'LineWidth', width)
        end
        drawwalls(data.panel.ConcreteWall, 'red', 2)
        drawwalls(data.panel.GibWall, 'magenta', 1)
        drawwalls(data.panel.GlassWindow, 'cyan', 2)
        drawwalls(data.panel.WoodenDoor, 'yellow', 1)
        drawwalls(data.panel.SteelDoor, 'black', 1)
        drawwalls(data.panel.Floor, 'green', 1, 0.0)
        drawwalls(data.panel.Ceiling, 'blue', 1, 0.0)
        points.text(rxdata.Position - local.shift, 'Color', graphics.rgb.gray)
        points.text(ax, txdata.Position - local.shift, local.labels)
        points.plot(ax, rxdata.Position(settings.RxIndices, :), 'kx', 'MarkerSize', 12, 'LineWidth', 2)
        axis(ax, 'equal')
        axis(ax, 'tight')
        camproj('perspective')
        rotate3d('on')
    end

end

% -------------------------------------------------------------------------
function result = aggregategaindb(filename, show, local) %#ok<DEFNU,INUSL>
% Average attenuation of given pattern at elevation zero
local.n = 100;
[~, ~, local.data] = loadpattern(filename);
local.mask = local.data.phi == 0;
local.theta = deg2rad(local.data.theta(local.mask));
local.gain = local.data.gain(local.mask); % linear scale (not dB)
[local.theta, local.permutation] = sort(local.theta);
local.gain = local.gain(local.permutation);
result = specfun.todb(median(local.gain)); % sum before conversion to dB
%clf, hist(local.gain), title('filename')
end

% -------------------------------------------------------------------------
function sub = colon2sub(sub, target, dim)
%COLON2SUB Convert ":" to explicit list of subscripts.
% COLON2SUB(SUB, N) returns 1:N if SUB is ':' and SUB otherwise.
% COLON2SUB(SUB, A, DIM) uses N = SIZE(A,DIM).
% Examples:
% >> colon2sub([1 2 4], 5)
% ans =
%      1     2     4
% >> colon2sub(':', 5)
% ans =
%      1     2     3     4     5
% >> colon2sub(':', eye(4, 5), 2)
% ans =
%      1     2     3     4     5
%
% See also SIZE, NDIMS, IND2SUB, SUB2IND.

narginchk(2, 3)

switch nargin
    case 2
        assert(isscalar(target))
        n = target;
    case 3
        assert(isscalar(dim))
        n = size(target, dim);
end

if strcmp(sub, ':')
    sub = 1 : n;
end
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
function evaluator = framefunctionnew(functions, frames, facetofunction)

narginchk(2, 3)

if ~iscell(functions)
    functions = {functions};
end

if nargin < 3 || isempty(facetofunction)
    assert(isscalar(functions))
    facetofunction = ones(size(frames, 1), 1);
end

% Preconditions
% assert(isfvframe(frames))
assert(iscell(functions))
assert(all(cellfun(@datatypes.isfunction, functions)))
assert(all(ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)

        assert(isvector(faceindices))
        assert(ismatrix(directions))
                
        % Transform global Cartesian coordinates
        % to those relative to faces' local frames
        localdirections = applytranspose( ...
            frames(faceindices, :, :), directions);
        
        % Angles relative to local frame
        angles = cartesiantoangularnew(localdirections);

        gain = indexedunary( ...
            functions, ...
            facetofunction(faceindices), ...
            angles);
        
%         try
%             s = load('..\evaluate.mat'); %#ok<NASGU>
%             return
%         catch
%         end
    end

evaluator = @evaluate;

end

% -------------------------------------------------------------------------
function varargout = plotradialintensity(varargin)

[ax, fun, origins, frames, varargin] = axisforplot(3, varargin{:});

% Preconditions
assert(isgraphics(ax))
assert(datatypes.isfunction(fun))
assert(ismatrix(origins))
assert(ndims(frames) == 3)
assert(ismember(size(origins, 2), 2 : 3))
assert(size(origins, 2) == size(frames, 2))
assert(size(origins, 2) == size(frames, 3))

[origins, frames] = unsingleton(origins, frames);
[numantennae, numdirections] = size(origins);

% Invariants
assert(numdirections == 3)
assert(size(frames, 1) == numantennae)
assert(size(frames, 2) == numdirections)
assert(size(frames, 3) == numdirections)

% Parse optional arguments
parser = inputParser;
parser.addParameter('Azimuth', linspace(0, 2*pi), @isvector) % default for 3D case only
parser.addParameter('Inclination', linspace(0, pi), @isvector)
parser.addParameter('Radius', @unitradius, @isfunction)
parser.KeepUnmatched = true;
parser.parse(varargin{:})
angles = parser.Results;
options = parser.Unmatched;
if ismember('CData', fieldnames(options))
    warning([mfilename, ':CDataIsSet'], ...
        'Field ''CData'' is set but will be over-ridden.')
end

% Sampling points in local spherical coordinates...
phi = angles.Azimuth(:); % m-by-1
theta = angles.Inclination(:)'; % 1-by-n
    function handle = display(id)
        r = angles.Radius(id, phi, theta); % m-by-n
        % ... expressed in global cartesian coordinates
        [x, y, z, c] = surfdata( ...
            @(direction) fun(id, direction), ...
            origins(id, :), ...
            frames(id, :, :), ...
            phi, theta, r);
        handle = surf(ax, x, y, z, setfield(options, 'CData', c)); %#ok<SFLD>
    end
handles = arrayfun(@display, 1 : numantennae, 'UniformOutput', false);

if 0 < nargout
    varargout = {handles};
end

end

function [x, y, z, c] = surfdata(fun, origins, frames, phi, theta, r)

% Elevation from xy-plane
thetabar = pi/2 - theta;

% Direction vectors from sampling surface to local
% origin expressed in local spherical coordinates
[dx0, dy0, dz0] = sph2cart(phi, thetabar, r);
dxyz0 = [dx0(:), dy0(:), dz0(:)];

% Directions expressed in global cartesian coordinates
dxyz = globalpoints(frames, dxyz0);

shape = [numel(phi), numel(theta)];
assert(isequal(size(dx0), shape)) % invariant

% Intensities (color) values
% NB: We choose not to normalize each row of the direction vector because
% the sampling surface may contain points at the origin (e.g. a 3D plot of
% antenna lobes is likely to have points of very small or zero length).
% Normalising would introduce NaNs in this benign case.
c = reshape(fun(dxyz), shape);

% Global cartesian coordinates
% i.e. "global axes at global origin"
xyz = origins + dxyz;
    function result = globalcartesian(i)
        result = reshape(xyz(:, i), shape);
    end
x = globalcartesian(1);
y = globalcartesian(2);
z = globalcartesian(3);

end

function r = unitradius(~, azimuth, inclination)
% First input argument (unused) corresponds to "index".
r = ones(sx.size(azimuth, inclination), 'like', azimuth);
end

% -------------------------------------------------------------------------
function varargout = axisforplot(n, varargin)
% See also AXESCHECK.

narginchk(1, nargin)
assert(isscalar(n) && 0 <= n && n <= numel(varargin))
nargoutchk(1 + n, nargout)

if 2 <= nargin && isequal(isaxes(varargin{1}), true) % scalar!
    assert(1 < nargin)
    ax = varargin{1};
    varargin(1) = [];
else
    ax = gca;    
end
first = varargin(1 : n);
rest = varargin(n + 1 : end);

varargout = {ax, first{:}, rest}; %#ok<CCAT>
end

% -------------------------------------------------------------------------
function result = isaxes(obj)
result = isgraphics(obj, 'axes');
end

% -------------------------------------------------------------------------
function [a, b] = unsingleton(a, b)
a = extend(a, b);
b = extend(b, a);
    function a = extend(a, b)
        if size(a, 1) == 1
            a = repmat(a, size(b, 1), 1);
        end
    end
end

% -------------------------------------------------------------------------
function xglobal = globalpoints(frames, xlocal)
xglobal = apply(frames, xlocal);

    function y = apply(a, x)
        % See also APPLYTRANSPOSE
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
        x = reshape(x, size(x, 1), 1, size(x, 2));
        y = reshape(sum(bsxfun(@times, a, x), 3), shape(1), shape(2));
        %y = reshape(sum(a.*x, 2), shape(1), shape(2));
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

% -------------------------------------------------------------------------
function [values, indices] = minmax(a, varargin)
%MINMAX Smallest and largest components.
% See also MIN, MAX.

narginchk(1, 2)

dim = sx.leaddim(a, varargin{:});
[vmin, imin] = min(a, [], dim);
[vmax, imax] = max(a, [], dim);

values = cat(dim, vmin, vmax);
indices = cat(dim, imin, imax);

end

% -------------------------------------------------------------------------
function c = fvfaces(c)
%FVFACES "Ragged" faces array for non-homogeneous polygonal patches.
% See also PATCH.

narginchk(1, 1)

if isnumeric(c) && ismatrix(c)
    return
end

assert(iscell(c) && isvector(c))
assert(~any(cellfun(@isempty, c)))
assert(all(cellfun(@isrow, c)))

maxnumcolumns = max(cellfun(@(a) size(a, 2), c));
    function a = pad(a)
        a(:, end + 1 : maxnumcolumns) = nan;
    end
c = cell2mat(cellfun(@pad, c(:), 'UniformOutput', false));

end

% -------------------------------------------------------------------------
function varargout = cartesiantoangularnew(xyz)
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
[x, y] = dealcell(num2cell(xy, 1));
angle = atan2(y, x); % azimuth
if nargout == 2
    radius = hypot(x, y);
end
end

% -------------------------------------------------------------------------
function [angles, radius] = convert3d(xyz)
[x, y, z] = dealcell(num2cell(xyz, 1));
hypotxy = hypot(x, y);
angles = [
    atan2(y, x), ... % azimuth
    0.5*pi - atan2(z, hypotxy) % inclination
    ];
if nargout == 2
    radius = hypot(hypotxy, z);
end
end

% -------------------------------------------------------------------------
function varargout = dealcell(c)
assert(iscell(c))
varargout = c;
end

% -------------------------------------------------------------------------
function result = isequalfp(actual, expected, tol)
%ISEQUALFP True if arrays are numerically equal in finite precision.
% ISEQUALFP(A,B,TOL) returns true if every element of
%     ABS(A - B) < TOL.*(ABS(B) + 1)
% is true. TOL may have the same size as A and B or it may be scalar.
%
% NB: Arrays A and B should have identical size and class; unlike
% ISEQUAL, ISEQUALFP will not silently return false if these differ.
%
% ISEQUALFP(A,B) uses 10*EPS(class(B)) for TOL.
%
% See also ISEQUAL, EPS.

narginchk(2, 3)

if nargin < 3 || isempty(tol)
    tol = 10*eps(class(expected));
end

assert(isequal(class(actual), class(expected)))
assert(isequal(size(actual), size(expected)))
assert(isscalar(tol) || isequal(size(tol), size(expected)))

% Ignore nan's common to both arrays
mask = isnan(actual) & isnan(expected);

scale = abs(expected) + ones('like', expected);
comparisons = abs(actual - expected) < tol.*scale;
result = all(comparisons(~mask));
end

% -------------------------------------------------------------------------
function [in, on] = polygonpartition(indices, vertices, points)

narginchk(3, nargin)
assert(iscell(indices))
assert(all(cellfun(@isnumeric, indices)))
assert(size(vertices, 2) == 2)
assert(size(points, 2) == 2)

    function [in, on] = query(indices)
        [in, on] = inpolygon( ...
            points(:, 1), ...
            points(:, 2), ...
            vertices(indices, 1), ...
            vertices(indices, 2));
    end

[in, on] = cellfun(@query, indices, 'UniformOutput', false);

in = flatten(in);
on = flatten(on);

end

function a = flatten(c)
a = cellfun(@(row) row(:)', c, 'UniformOutput', false);
end
