function [downlinkpower, uplinkpower, interactions, elapsed] = ...
    tracescenenew2(origins, targets, varargin)
%TRACESCENE Tabulate ray interactions with a scene.

narginchk(2, nargin)
assert(ismatrix(origins) && ismember(size(origins, 2), [2, 3]))
assert(ismatrix(targets) && ismember(size(targets, 2), [2, 3]))

settings = imagemethod.tracesceneargumentsnew(varargin{:});

% Disable reporting if results are not actually used
settings.Reporting = settings.Reporting && 3 <= nargout;

% Disable SPMD operation if a pool of workers is not available
if settings.SPMD && isempty(parallel.currentpool)
    warning([mfilename, ':PoolRequiredForSPMD'], ...
        'Create a parallel pool using parpool for option ''SMPD''.')
    settings.SPMD = false;
end

% Compute gains for each invidual reflection arity...
arities = settings.ReflectionArities;
settings = rmfield(settings, 'ReflectionArities');
[downlinkpower, uplinkpower, interactions, elapsed] = ...
    findinteractions(arities, origins, targets, settings);

interactions = struct( ...
    'Data', interactions, ...
    'Functions', struct( ...
    'Free', settings.FreeGain, ...
    'Reflection', settings.ReflectionGain, ...
    'Sink', settings.SinkGain, ...
    'Source', settings.SourceGain, ...
    'Transmission', settings.TransmissionGain));

end

% -------------------------------------------------------------------------
function [downlinkpower, uplinkpower, interactions, elapsed] = ...
    findinteractions(arities, origins, targets, settings)

% Prepare to restore ndebug after aplying NDEBUG option (see [*])
state = contracts.ndebug;
cleaner = onCleanup(@() contracts.ndebug(state));

% Key dimensions
numarities = numel(arities);
numorigins = size(origins, 1);
numtargets = size(targets, 1);

% Broadcast arrays: Shared by each parallel worker
[pairedsourceindices, pairedsinkindices] = deal(zeros(numorigins*numtargets, 1));
[pairedsourceindices(:), pairedsinkindices(:)] = ndgrid(1 : numorigins, 1 : numtargets);
sourcepoints = origins(pairedsourceindices, :);
sinkpoints = targets(pairedsinkindices, :);

% Pre-allocate arrays
spmd
    [uplinkpower, downlinkpower] = deal( ...
        zeros(numtargets, numorigins, numarities));
    interactions = {};
end

    function [sourceindices, sinkindices, pathpoints] = reflectionpoints(faceindices)
        [pairindices, pathpoints] = rayoptics.imagemethod( ...
            settings.Scene.IntersectFacet, ...
            settings.Scene.Mirror, ...
            faceindices, ...
            sourcepoints, ...
            sinkpoints);
        sourceindices = pairedsourceindices(pairindices, :);
        sinkindices = pairedsinkindices(pairindices, :);
    end

    function hits = transmissionpoints(origins, directions, faceindices)
        % Intersections comprise reflection- and transmission points, so
        % drop reflection points from list of candidate transmission
        % points i.e. those at the beginning or end of a line segment.
        hits = tracesegments( ...
            settings.Scene, origins, directions, faceindices);
    end

tasks = sequence.NestedSequence( ...
    sequence.ArraySequence(arities), ...
    @(arity) imagemethod.FacetSequence(settings.Scene.NumFacets, arity), ...
    @(globalindex, ~, facetindices) {globalindex, facetindices});
    function [hasnext, next] = getnext()
        hasnext = tasks.hasnext();
        if hasnext
            next = tasks.getnext();
        else
            next = [];
        end
    end
[downlinkpower, uplinkpower, interactions, elapsed] = parallel.parreduce( ...
    @spmdbody, 3, @getnext, ...
    downlinkpower, uplinkpower, interactions, ...
    'Parameters', {@reflectionpoints, @transmissionpoints, settings}, ...
    'Initialize', @tic, ...
    'Finalize', @toc);

% TODO: Would GPLUS run more efficiently?
downlinkpower = parallel.reduce(@plus, downlinkpower);
uplinkpower = parallel.reduce(@plus, uplinkpower);

interactions = [interactions{:}];

% Convert cell array of structs to a (single) tabular struct
if settings.Reporting
    interactions = [interactions{:}];
else
    interactions = struct;
end

if settings.Reporting   
    interactions = datatypes.struct.structfun( ...
        @vertcat, interactions, 'UniformOutput', false);
    % Remap sequence index so values start at 1 and are contiguous
    pathlabels = [interactions.SequenceIndex, interactions.Identifier];
    [~, ~, identifiers] = unique(pathlabels, 'rows');
    interactions.Identifier = identifiers;
    interactions = rmfield(interactions, 'SequenceIndex');
    interactions = sorthits(interactions);
end

end

% -------------------------------------------------------------------------
function hits = sorthits(hits)
[~, permutation] = sortrows([
    hits.Identifier, ...
    hits.SegmentIndex, ... % previously 'RayIndex'
    hits.Parameter  % previously 'RayParameter'
    ]);
hits = datatypes.struct.tabular.rows(hits, permutation);
end

% -------------------------------------------------------------------------
function [downlinkpower, uplinkpower, nodetables] = spmdbody( ...
    task, ...
    downlinkpower, uplinkpower, nodetables, ...
    reflectionpoints, transmissionpoints, settings)

import contracts.ndebug
import datatypes.isfunction
assert(iscell(task) && numel(task) == 2)
assert(ndebug || isequal(size(downlinkpower), size(uplinkpower)))
assert(ndebug || iscell(nodetables))
assert(ndebug || isfunction(reflectionpoints))
assert(ndebug || isfunction(transmissionpoints))
assert(ndebug || isstruct(settings))

    function result = evaluatechecked(fun, varargin)
        result = feval(fun, varargin{:});
        if not(contracts.ndebug || all(isfinite(result)))
            error([mfilename ':NaNInfGainFunction'], ...
                'Gain function %s returns nan or inf', func2str(fun))
        end
    end

[globalstep, candidatefaceindices] = task{:};

% Compute reflection points
[segments.SourceIndex, segments.SinkIndex, pathpoints] = ...
    reflectionpoints(candidatefaceindices);

if isempty(segments.SourceIndex)
    % No paths exist between any source-receiver pairing
    return
end

% Key dimensions
numfacesperpath = numel(candidatefaceindices);
numraysperpath = numfacesperpath + 1;
numpaths = numel(segments.SourceIndex);
[numsources, numsinks, ~] = size(downlinkpower);

% Rays defining each ray/segment
directions = diff(pathpoints, 1, 3);

% Indices/identifiers for each ray and each ray segment
pathid = 1 : numpaths;
rayid = repmat(pathid(:), 1, numraysperpath);
segmentindex = repmat(1 : numraysperpath, numpaths, 1);

% Compute transmission points on each path of ray segments
transmission = transmissionpoints( ...
    pathpoints(:, :, 1 : end - 1), ...
    directions, ...
    candidatefaceindices);

% Friis free-space gain (all negative) for each path
segmentlengths = matfun.norm(directions, 2, 2);
segments.PathLength = sum(segmentlengths, 3);
gain.Free = evaluatechecked( ...
    settings.FreeGain, ...
    segments.SourceIndex, ...
    segments.PathLength);

% Gain (all positive) for source node on each path
gain.Source = evaluatechecked( ...
    settings.SourceGain, ...
    segments.SourceIndex, ...
    directions(:, :, 1)); % "outgoing"

% Gain (all negative) for sink node on each each path
gain.Sink = evaluatechecked( ...
    settings.SinkGain, ...
    segments.SinkIndex, ...
    directions(:, :, end)); % "incoming"

% Gains (all negative) for each reflection node
% Note: If spatially-varying transmission coefficients were ever
% to be supported, function TransmissionGain would have the array
% of intersection points as an additional argument.
segments.FaceIndex = repmat(candidatefaceindices(:)', numpaths, 1);
reflectiongainonpaths = evaluatechecked( ...
    settings.ReflectionGain, ...
    segments.FaceIndex(:), ...
    stack(directions(:, :, 1 : end - 1))); % "incoming"
gain.Reflection = accumarray( ...
    ops.vec(rayid(:, 2 : end)), ...
    ops.vec(reflectiongainonpaths), ...
    [numpaths, 1]);

% Gain (all negative) for each transmission node (see Note above)
alldirections = stack(directions);
transmission.Direction = alldirections(transmission.RayIndex, :);
transmission.GainOnPath = evaluatechecked( ...
    settings.TransmissionGain, ...
    transmission.FaceIndex(:), ...
    transmission.Direction); % "incoming"
gain.Transmission = accumarray( ...
    ops.vec(rayid(transmission.RayIndex)), ...
    ops.vec(transmission.GainOnPath), ...
    [numpaths, 1]);

% Path gain in dBW
gain.Path = gain.Free + gain.Reflection + gain.Transmission;

% Accumulate sums of powers (watts) over source-receiver
% pairs to update downlink- and uplink received power
    function inout = accumulate(inout, gaindb) 
        index = numfacesperpath + 1; 
        inout(:, :, index) = inout(:, :, index) + ...
            accumarray( ...
            [segments.SinkIndex(:), segments.SourceIndex(:)], ...
            elfun.fromdb(gaindb), ... % NB: Convert dB to watts
            [numsources, numsinks]);
    end
downlinkpower = accumulate(downlinkpower, gain.Source + gain.Path);
uplinkpower = accumulate(uplinkpower, gain.Sink + gain.Path);

if settings.Reporting
    
    import imagemethod.interaction
    numtransmissions = numel(transmission.FaceIndex);
    segments.SourceType = repmat(interaction.Source, numpaths, 1);
    segments.SinkType = repmat(interaction.Sink, numpaths, 1);
    segments.ReflectionType = repmat(interaction.Reflection, numpaths, numfacesperpath);
    transmission.Type = repmat(interaction.Transmission, numtransmissions, 1);
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
    nodetable = struct( ...
        'SequenceIndex', [
        vec(repmat(globalstep, numpaths*numraysperpath, 1));
        vec(repmat(globalstep, numtransmissions, 1));
        vec(repmat(globalstep, numpaths, 1));
        ], ...
        'Identifier', [
        vec(rayid);
        vec(rayid(transmission.RayIndex));
        vec(pathid);
        ], ...
        'SegmentIndex', [ % previously 'RayIndex'
        vec(segmentindex);
        vec(segmentindex(transmission.RayIndex));
        vec(repmat(numraysperpath + 1, numpaths, 1));
        ], ...
        'Parameter', [ % previously 'RayParameter'
        zeros(numpaths*numraysperpath, 1);
        transmission.RayParameter;
        ones(numpaths, 1);
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
        stack(segmentlengths);
        transmission.Blank;
        zeros(size(segments.PathLength));
        ], ...
        'FinalDistance', [
        vec(zeros(numpaths, numraysperpath));
        transmission.Blank;
        segments.PathLength;
        ], ...
        'SourceGain', [
        vec([gain.Source, zeros(numpaths, numfacesperpath)]);
        blank(transmission.GainOnPath);
        blank(gain.Sink);
        ], ...
        'SinkGain', [
        vec([blank(gain.Source), zeros(numpaths, numfacesperpath)]);
        blank(transmission.GainOnPath);
        gain.Sink;
        ]);
    
    assert(istabular(nodetable))
    
    % Sort nodes on each path by ray index and
    % ray parameter, and sort paths by path index
    [~, permutation] = sortrows([
        nodetable.Identifier, ...
        nodetable.SegmentIndex, ... % previously 'RayIndex'
        nodetable.Parameter  % previously 'RayParameter'
        ]);
    
    % Store for aggregation
    import datatypes.struct.tabular.rows
    nodetables{end + 1} = rows(nodetable, permutation);
    
end

end

% -------------------------------------------------------------------------
function hitsall = tracesegments(scene, origins, directions, faceindices)
narginchk(4, 4)
assert(isequal(size(origins), size(directions)))
assert(size(origins, 3) == numel(faceindices) + 1)
hitsall = scene.Intersect(origins, directions, faceindices);
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

% % -------------------------------------------------------------------------
% function show = showheadings(settings)
% show = 0 < settings.Verbosity;
% end
% 
% function show = showiterations(settings)
% show = 1 < settings.Verbosity;
% end
% 
% function show = showdetails(settings)
% show = 2 < settings.Verbosity;
% end
