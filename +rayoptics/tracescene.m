function [downlinks, uplinks, trace, elapsed] = ...
    tracescene(reflect, transmit, numfacets, origins, targets, varargin)
%TRACESCENE Tabulate ray interactions with a scene.

narginchk(5, nargin)
assert(datatypes.isfunction(reflect))
assert(datatypes.isfunction(transmit))
assert(isscalar(numfacets) && isnumeric(numfacets))
assert(ismatrix(origins) && ismember(size(origins, 2), 2 : 3))
assert(ismatrix(targets) && ismember(size(targets, 2), 2 : 3))
assert(size(origins, 2) == size(targets, 2))

settings = imagemethod.tracesceneSettings(varargin{:});

% Disable reporting if results are not actually used.
% NB: The cost of the trace dominates that of the calculation itself.
settings.Reporting = settings.Reporting && 3 <= nargout;

% Compute gains for each invidual reflection arity...
arities = settings.ReflectionArities;
settings = rmfield(settings, 'ReflectionArities');
[downlinks, uplinks, interactions, elapsed] = ...
    findinteractions(reflect, transmit, numfacets, arities, origins, targets, settings);

% These may be required for validation of aggregate values
functions = struct( ...
    'Free', settings.FreeGain, ...
    'Reflection', settings.ReflectionGain, ...
    'Sink', settings.SinkGain, ...
    'Source', settings.SourceGain, ...
    'Transmission', settings.TransmissionGain);

trace = struct( ...
    'Data', interactions, ...
    'Functions', functions);

end

% -------------------------------------------------------------------------
function [downlinks, uplinks, hits, elapsed] = findinteractions( ...
    reflect, transmit, numfacets, arities, origins, targets, settings)

% Key dimensions
numArities = numel(arities);
numOrigins = size(origins, 1);
numTargets = size(targets, 1);

% Broadcast arrays: Shared by each parallel worker
[pairedSourceIndices, pairedSinkIndices] = deal(zeros(numOrigins*numTargets, 1));
[pairedSourceIndices(:), pairedSinkIndices(:)] = ndgrid(1 : numOrigins, 1 : numTargets);
sourcePoints = origins(pairedSourceIndices, :);
sinkPoints = targets(pairedSinkIndices, :);

% Pre-allocate accumulation/reduction array on each worker/lab
spmd
    [uplinks, downlinks] = deal(zeros(numTargets, numOrigins, numArities));
    hits = {};
end

    function [sourceIndices, sinkIndices, pathPoints] = reflectionPoints(faceIndices)
        [pairindices, pathPoints] = reflect(sourcePoints, sinkPoints, faceIndices);
        sourceIndices = pairedSourceIndices(pairindices, :);
        sinkIndices = pairedSinkIndices(pairindices, :);
    end

    function hits = transmissionPoints(origins, directions, faceindices)
        % Intersections comprise reflection- and transmission points, so
        % drop reflection points from list of candidate transmission
        % points i.e. those at the beginning or end of a line segment.
        assert(isequal(size(origins), size(directions)))
        assert(size(origins, 3) == numel(faceindices) + 1)
        hits = transmit(origins, directions, faceindices);
    end

% Lazy (non-strict) list of independent tasks to be processed, each
% comprisng a list of facet sequences to check for reflected ray paths.
tasks = rayoptics.taskSequence(numfacets, arities);

% This functions captures the instance of Sequence and adapts the 
% Sequence interface ("hasnext() and getnext()")  to conform with 
% the interface used by the parallel reduction routine. 
    function [hasnext, next] = hasNextAndGetNext()
        hasnext = tasks.hasnext();
        if hasnext
            next = tasks.getnext();
        else
            next = []; % arbitrary placeholder value
        end
    end

% Process these tasks in parallel: Each parallel worker sums (uplink- and
% downlink) contributions for the tasks that it processes...
[downlinks, uplinks, hits, elapsed] = parallel.parreduce( ...
    @workerAccumulate, 3, @hasNextAndGetNext, ...
    downlinks, uplinks, hits, ...
    'Parameters', {@reflectionPoints, @transmissionPoints, settings}, ...
    'Initialize', @tic, ...
    'Finalize', @toc);

% ... Subsequently, the sums on the parallel workers are further
% reduced to grand totals on the client.
downlinks = parallel.reduce(@plus, downlinks);
uplinks = parallel.reduce(@plus, uplinks);

% If requested, each worker saves a complete record of individual 
% ray-facet interactions: Here, those records are copied from the 
% workers to the client processor. 
% NB: To this point, interactions are stored as cell array of 
% structs in a Composite object with a portion on each worker.
hits = [hits{:}];

% Convert cell array of structs to a (single) tabular struct...
if settings.Reporting
    
    % Combine individual chunks into a single (potentially huge) table
    hits = datatypes.struct.structfun( ...
        @vertcat, [hits{:}], 'UniformOutput', false);
    
    % Remap sequence index so values start at 1 and are contiguous
    pathlabels = [hits.SequenceIndex, hits.Identifier];
    [~, ~, identifiers] = unique(pathlabels, 'rows');
    hits.Identifier = identifiers;
    
    % Sort according to ray identifier, and then 
    % in order of interaction on each reflected segment
    hits = rmfield(hits, 'SequenceIndex');
    [~, permutation] = sortrows([
        hits.Identifier, ...
        hits.SegmentIndex, ... % previously 'RayIndex'
        hits.Parameter  % previously 'RayParameter'
        ]);    
    hits = datatypes.struct.tabular.rows(hits, permutation);
    
else
    % ... that has no fields if a trace was not requested.
    hits = struct;
    
end

end

% -------------------------------------------------------------------------
function [downlinks, uplinks, nodeTables] = workerAccumulate( ...
    task, ...
    downlinks, uplinks, nodeTables, ...
    reflectionPoints, transmissionPoints, settings)

import contracts.ndebug
import datatypes.isfunction
assert(iscell(task) && numel(task) == 2)
assert(ndebug || isequal(size(downlinks), size(uplinks)))
assert(ndebug || iscell(nodeTables))
assert(ndebug || isfunction(reflectionPoints))
assert(ndebug || isfunction(transmissionPoints))
assert(ndebug || isstruct(settings))

    function result = evaluateChecked(fun, varargin)
        result = feval(fun, varargin{:});
        if not(contracts.ndebug || all(isfinite(result)))
            error( ...
                contracts.msgid(mfilename, 'NaNInfGainFunction'), ...
                'Gain function %s returns nan or inf', func2str(fun))
        end
    end

[globalStep, candidateFaceIndices] = task{:};

% Compute reflection points
[segments.SourceIndex, segments.SinkIndex, pathpoints] = ...
    reflectionPoints(candidateFaceIndices);

if isempty(segments.SourceIndex)
    % No reflection paths exist between any source-receiver 
    % pairing for the current sequence of candidate facets.
    return
end

% Key dimensions
numFacesPerPath = numel(candidateFaceIndices);
numRaysPerPath = numFacesPerPath + 1;
numPaths = numel(segments.SourceIndex);
[numSources, numSinks, ~] = size(downlinks);

% Rays defining each ray/segment
directions = diff(pathpoints, 1, 3);

% Indices/identifiers for each ray and each ray segment
pathid = 1 : numPaths;
rayid = repmat(pathid(:), 1, numRaysPerPath);
segmentIndex = repmat(1 : numRaysPerPath, numPaths, 1);

% Compute transmission points on each path of ray segments
transmission = transmissionPoints( ...
    pathpoints(:, :, 1 : end - 1), ...
    directions, ...
    candidateFaceIndices);

% Friis free-space gain (all negative) for each path
segmentLengths = matfun.norm(directions, 2, 2);
segments.PathLength = sum(segmentLengths, 3);
gain.Free = evaluateChecked( ...
    settings.FreeGain, ...
    segments.SourceIndex, ...
    segments.PathLength);

% Gain (all positive) for source node on each path
gain.Source = evaluateChecked( ...
    settings.SourceGain, ...
    segments.SourceIndex, ...
    directions(:, :, 1)); % "outgoing"

% Gain (all negative) for sink node on each each path
gain.Sink = evaluateChecked( ...
    settings.SinkGain, ...
    segments.SinkIndex, ...
    directions(:, :, end)); % "incoming"

% Gains (all negative) for each reflection node
% Note: If spatially-varying transmission coefficients were ever
% to be supported, function TransmissionGain would have the array
% of intersection points as an additional argument.
segments.FaceIndex = repmat(candidateFaceIndices(:)', numPaths, 1);
reflectionGainOnPaths = evaluateChecked( ...
    settings.ReflectionGain, ...
    segments.FaceIndex(:), ...
    stack(directions(:, :, 1 : end - 1))); % "incoming"
gain.Reflection = accumarray( ...
    ops.vec(rayid(:, 2 : end)), ...
    ops.vec(reflectionGainOnPaths), ...
    [numPaths, 1]);

% Gain (all negative) for each transmission node (see Note above)
allDirections = stack(directions);
transmission.Direction = allDirections(transmission.RayIndex, :);
transmission.GainOnPath = evaluateChecked( ...
    settings.TransmissionGain, ...
    transmission.FaceIndex(:), ...
    transmission.Direction); % "incoming"
gain.Transmission = accumarray( ...
    ops.vec(rayid(transmission.RayIndex)), ...
    ops.vec(transmission.GainOnPath), ...
    [numPaths, 1]);

% Path gain in dBW
gain.Path = gain.Free + gain.Reflection + gain.Transmission;

% Accumulate sums of powers (watts) over source-receiver
% pairs to update downlink- and uplink received power
    function inout = accumulate(inout, gaindb) 
        index = numFacesPerPath + 1; 
        inout(:, :, index) = inout(:, :, index) + ...
            accumarray( ...
            [segments.SinkIndex(:), segments.SourceIndex(:)], ...
            specfun.fromdb(gaindb), ... % NB: "sum in watts, not in dB"
            [numSources, numSinks]);
    end
downlinks = accumulate(downlinks, gain.Source + gain.Path);
uplinks = accumulate(uplinks, gain.Sink + gain.Path);

if settings.Reporting
    
    import rayoptics.NodeTypes
    numtransmissions = numel(transmission.FaceIndex);
    segments.SourceType = repmat(NodeTypes.Source, numPaths, 1);
    segments.SinkType = repmat(NodeTypes.Sink, numPaths, 1);
    segments.ReflectionType = repmat(NodeTypes.Reflection, numPaths, numFacesPerPath);
    transmission.Type = repmat(NodeTypes.Transmission, numtransmissions, 1);
    transmission.Blank = blank(transmission.FaceIndex);
    
    import datatypes.struct.tabular.istabular
    assert(istabular(segments))
    assert(istabular(transmission))
    assert(istabular(gain))
    
    %
    % In each field, we have:
    % - block #1: [source, reflection] data, together defining rays
    % - block #2: transmission data
    % - block #3: sink/receiver data
    % Note well:
    % 1) "source" and "reflection" data are packed together
    %    deliberately to form "ray" data ("source + direction")
    %    i.e. distinguish "ray segment" from "ray path"
    % 2) "vec([source, reflection])" <-- correct
    %    as opposed to
    %    "[source(:); reflection(:)]" <-- incorrect
    %
    import ops.vec
    nodeTable = struct( ...
        'SequenceIndex', [
        vec(repmat(globalStep, numPaths*numRaysPerPath, 1));
        vec(repmat(globalStep, numtransmissions, 1));
        vec(repmat(globalStep, numPaths, 1));
        ], ...
        'Identifier', [
        vec(rayid);
        vec(rayid(transmission.RayIndex));
        vec(pathid);
        ], ...
        'SegmentIndex', [ % previously 'RayIndex'
        vec(segmentIndex);
        vec(segmentIndex(transmission.RayIndex));
        vec(repmat(numRaysPerPath + 1, numPaths, 1));
        ], ...
        'Parameter', [ % previously 'RayParameter'
        zeros(numPaths*numRaysPerPath, 1);
        transmission.RayParameter;
        ones(numPaths, 1);
        ], ...
        'ObjectIndex', [
        vec([segments.SourceIndex, segments.FaceIndex]);
        transmission.FaceIndex;
        segments.SinkIndex;
        ], ...
        'InteractionType', [
        vec([segments.SourceType, segments.ReflectionType]);
        transmission.Type;
        segments.SinkType;
        ], ...
        'Position', [ % previously 'IntersectionPoint'
        stack(pathpoints(:, :, 1 : end - 1));
        transmission.Point;
        pathpoints(:, :, end);
        ], ...
        'Direction', [
        stack(directions(:, :, [1, 1 : end - 1]));
        transmission.Direction;
        directions(:, :, end);
        ], ...
        'FreeDistance', [
        stack(segmentLengths);
        transmission.Blank;
        zeros(size(segments.PathLength));
        ], ...
        'FinalDistance', [
        vec(zeros(numPaths, numRaysPerPath));
        transmission.Blank;
        segments.PathLength;
        ], ...
        'SourceGain', [
        vec([gain.Source, zeros(numPaths, numFacesPerPath)]);
        blank(transmission.GainOnPath);
        blank(gain.Sink);
        ], ...
        'SinkGain', [
        vec([blank(gain.Source), zeros(numPaths, numFacesPerPath)]);
        blank(transmission.GainOnPath);
        gain.Sink;
        ]);
    
    assert(istabular(nodeTable))
    
    % Sort nodes on each path by ray index and
    % ray parameter, and sort paths by path index
    [~, permutation] = sortrows([
        nodeTable.Identifier, ...
        nodeTable.SegmentIndex, ... % previously 'RayIndex'
        nodeTable.Parameter  % previously 'RayParameter'
        ]);
    
    % Store for aggregation
    import datatypes.struct.tabular.rows
    nodeTables{end + 1} = rows(nodeTable, permutation);    
end

end

% -------------------------------------------------------------------------
function blank = blank(a)
blank = zeros(size(a));
end

% -------------------------------------------------------------------------
function x = stack(x)
%STACK Stacks the layers of a 3D array.
% STACK(CAT(3,A,B,C,...)) returns [A; B; C; ...] if A, B, C are matrices.
numcolumns = size(x, 2);
x = permute(x, [1 3 2]);
x = reshape(x, [], numcolumns);
end
