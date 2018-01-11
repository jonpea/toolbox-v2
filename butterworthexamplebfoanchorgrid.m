function butterworthexamplebfoanchorgrid(varargin)
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
parser.addParameter('Scene', @scenes.completescene, @isfunction)
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
% % if ~isempty(settings.FigFileName)
% %     cleaner = onCleanup(@() ...
% %         savefig(settings.Figure, settings.FigFileName, 'compact'));
% % end
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
[gridx, gridy, gridz] = meshgrid( ...
    linspace(lower(1), upper(1), numpoints(1)), ...
    linspace(lower(2), upper(2), numpoints(2)), ...
    linspace(lower(3), upper(3), numpoints(3)));
rxgridpoints = points.meshpoints(gridx, gridy, gridz);

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
    'Description',          'XLower', 'XUpper',  'X0';
    'GibReflection',            -inf,      0.0,  -1.0; %-4.6;
    'ConcreteReflection',       -inf,      0.0,  -1.0; %-4.8;
    'GibTransmission',          -inf,      0.0,  -1.0; %-3.3;
    'ConcreteTransmission',     -inf,      0.0,  -1.0; %-0.0;
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
            'OutputTransform', @elfun.todb, ...
            'InputTransform', @specfun.wrapquadrant);
    end

    function fun = makegainfunctions(patterns, offsets)
        offsetpatterns = cellfun(@(pattern, offset) ...
            @(varargin) pattern(varargin{:}) + offset, ...
            patterns(:), num2cell(offsets(:)), ...
            'UniformOutput', false);
        fun = power.framefunctionnew(offsetpatterns, ...
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
            local.framefunction = power.framefunctionnew( ...
                loadquadpattern(patternname), ...
                local.standardframe);
            graphics.spherical(ax, ...
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
meangain = @(positions, db) elfun.todb(averageof(positions, elfun.fromdb(db)));
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
    end

    function [gain, components] = compute(x, rxpositions, local)
        assert(numel(x) == 4)
        local.xreflection = x(1 : 2); % "[gib, concrete]" reflection
        local.xtransmission = x(3 : 4); % "[gib, concrete]" transmission
        local.downlinks = power.analyze( ...
            txdata.Position, rxpositions, scene.Model, ...
            'ReflectionArities', 0 : settings.MaxNumReflections, ...
            'FreeGain', power.friisfunction(txdata.Frequency), ...
            'ReflectionGain', makegainfunctions(reflectionpatterns, local.xreflection), ...
            'TransmissionGain', makegainfunctions(transmissionpatterns, local.xtransmission));
        gain = local.downlinks.PowerDBW;
        components = elfun.todb(local.downlinks.PowerComponentsWatts);
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
colorscale = minmax([meanmeasured(:); meancomputed(:)]);
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
        import data.panel
        drawwalls(panel.ConcreteWall, 'red', 2)
        drawwalls(panel.GibWall, 'magenta', 1)
        drawwalls(panel.GlassWindow, 'cyan', 2)
        drawwalls(panel.WoodenDoor, 'yellow', 1)
        drawwalls(panel.SteelDoor, 'black', 1)
        drawwalls(panel.Floor, 'green', 1, 0.0)
        drawwalls(panel.Ceiling, 'blue', 1, 0.0)
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
result = elfun.todb(median(local.gain)); % sum before conversion to dB
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
