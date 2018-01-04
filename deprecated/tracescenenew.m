function [downlinkpower, uplinkpower, interactions] = ...
    tracescenenew(origins, targets, varargin)
%TRACESCENE Tabulate ray interactions with a scene.

narginchk(2, nargin)
assert(ismatrix(origins) && ismember(size(origins, 2), [2, 3]))
assert(ismatrix(targets) && ismember(size(targets, 2), [2, 3]))

settings = tracesceneargumentsnew(varargin{:});

% Disable reporting if results are not actually used
settings.Reporting = settings.Reporting && nargout == 3;

% Disable SPMD operation if a pool of workers is not available
if settings.SPMD && isempty(currentpool)
    warning([mfilename, ':PoolRequiredForSPMD'], ...
        'Create a parallel pool using parpool for option ''SMPD''.')
    settings.SPMD = false;
end

% Compute gains for each invidual reflection arity...
arities = settings.ReflectionArities;
settings = rmfield(settings, 'ReflectionArities');
    function varargout = individualreflectionarity(arity)
        [varargout{1 : nargout}] = ...
            findinteractions(arity, origins, targets, settings);
    end
[downlinkpower, uplinkpower, interactions] = arrayfun( ...
    @individualreflectionarity, arities(:), 'UniformOutput', false);

% ... and concatenate results in the third index
downlinkpower = stackmatrices(downlinkpower);
uplinkpower = stackmatrices(uplinkpower);
    function result = stackmatrices(x)
        result = cat(3, x{:});
    end

% Prepare detailed table of ray-entity interactions if required
if settings.Reporting
    % Since identifiers start at "1" for each arity, they need be
    % shifted to maintain uniqueness when arities are combined.
    maxid = cellfun(@(s) max(s.Identifier), interactions(:));
    offsets = [0; cumsum(maxid(1 : end - 1))];
    interactions = cellfun(@(s, offset) ...
        setfield(s, 'Identifier', s.Identifier + offset), ...
        interactions(:), ...
        num2cell(offsets), ...
        'UniformOutput', false);
end

interactions = struct( ...
    'Data', tabularvertcat(vertcat(interactions{:})), ...
    'Functions', struct( ...
    'Free', settings.FreeGain, ...
    'Reflection', settings.ReflectionGain, ...
    'Sink', settings.SinkGain, ...
    'Source', settings.SourceGain, ...
    'Transmission', settings.TransmissionGain));

end

% -------------------------------------------------------------------------
function [downlinkpower, uplinkpower, interactions] = ...
    findinteractions(arity, origins, targets, settings)

% Prepare to restore ndebug after aplying NDEBUG option (see [*])
state = ndebug;
cleaner = onCleanup(@() ndebug(state));

numtasks = imagemethodcardinality(settings.Scene.NumFacets, arity);

% NB: The line of code that has been commented out was intended to reduce
% the number of designated parallel workers to one when computing direct
% rays (for which there is just "one (large) task" that we don't attempt
% to partition amongst workers). Unfortunately, the arrays of uplink- and
% downlink powers are then filled with zeros: Either there is subtle bug in
% our implementation or in the MATLAB's implmentation of the SPMD block.
%numprocessors = tern(settings.SPMD, min(settings.NumWorkers, numtasks), 1);
numprocessors = tern(settings.SPMD, settings.NumWorkers, 1);
runspmd = settings.SPMD && isscalar(currentpool);

if showheadings(settings)
    fprintf('=================================================>>\n')
    fprintf(' %u reflection(s), %u candidate(s), %u worker(s)\n', ...
        arity, numtasks, numprocessors)
    fprintf('<<=================================================\n')
end

% Key dimensions
numorigins = size(origins, 1);
numtargets = size(targets, 1);

% Broadcast arrays: Shared by each parallel worker
[pairedsourceindices, pairedsinkindices] = deal(zeros(numorigins*numtargets, 1));
[pairedsourceindices(:), pairedsinkindices(:)] = ndgrid(1 : numorigins, 1 : numtargets);
sourcepoints = origins(pairedsourceindices, :);
sinkpoints = targets(pairedsinkindices, :);

% Pre-allocate arrays
[uplinkpower, downlinkpower] = deal(zeros(numtargets, numorigins));

    function [sourceindices, sinkindices, pathpoints] = reflectionpoints(faceindices)
        [pairindices, pathpoints] = imagemethod( ...
            settings.Scene.IntersectFacet, ...
            settings.Scene.Mirror, ...
            faceindices, ...
            sourcepoints, ...
            sinkpoints);
        sourceindices = pairedsourceindices(pairindices, :);
        sinkindices = pairedsinkindices(pairindices, :);
    end

    function intersections = transmissionpoints(origins, directions, faceindices)
        % Intersections comprise reflection- and transmission points, so
        % drop reflection points from list of candidate transmission
        % points i.e. those at the beginning or end of a line segment.
        intersections = tracesegments( ...
            settings.Scene, origins, directions, faceindices);
    end

reflectionpointshandle = @reflectionpoints;
transmissionpointshandle = @transmissionpoints;

if runspmd
    
    % Parallel execution:
    % This mode is preferable for very large problems,
    % but note that it does not support MATLAB's code
    % profiling tool or interactive break-points
    
    masterindex = 1;
    [partitionsizes, partitionoffsets] = partition(numtasks, numprocessors);
    
    if showdetails(settings)
        startbytes = ticBytes(currentpool);
    end
    
    spmd (numprocessors)
        
        % NDEBUG must be set on each worker
        ndebug(settings.NDEBUG); % [*]
        
        tstart = tic;
        [downlinkpower, uplinkpower, interactions] = spmdbody( ...
            downlinkpower, ...
            uplinkpower, ...
            reflectionpointshandle, ...
            transmissionpointshandle, ...
            arity, ...
            partitionoffsets(labindex), partitionsizes(labindex), ...
            settings);
        elapsed = toc(tstart);
        
        % Sum powers (in watts) and place result on worker #1
        downlinkpower = gplus(downlinkpower, masterindex);
        uplinkpower = gplus(uplinkpower, masterindex);
        
    end
    
    % Transfer results from workers back to client
    % NB: Powers have already been summed to lab/worker #1
    downlinkpower = downlinkpower{masterindex};
    uplinkpower = uplinkpower{masterindex};
    elapsed = [elapsed{:}];
    interactions = [interactions{:}];
    
    if showdetails(settings)
        tocBytes(currentpool, startbytes)
    end
    
    if showiterations(settings)
        tabulardisp(struct( ...
            'Worker', (1 : numprocessors)', ...
            'NumTasks', partitionsizes(:), ...
            'Elapsed', elapsed(:), ...
            'RelativeToMax', elapsed(:)/max(elapsed)))
        fprintf('MinLoad: %u tasks, %.2f sec\n', min(partitionsizes), min(elapsed))
        fprintf('MaxLoad: %u tasks, %.2f sec\n', max(partitionsizes), max(elapsed))
        fprintf('  Ratio:           %.2f times\n', max(elapsed)/min(elapsed))
    end
    
else
    
    % Serial execution:
    % This mode accommodates profiling and breakpoints
    % Note that, due to limitation
    %     "MATLAB:mir_error_spmd_nested_function",
    % the duplication in the function call below seems unavoidable:
    %  'An spmd block cannot refer to a nested function (bob).
    %   See SPMD in MATLAB, "Limitations".'
    % Implication: We can't pack the common code into a nested function
    
    ndebug(settings.NDEBUG); % [*]
    
    [downlinkpower, uplinkpower, interactions] = spmdbody( ...
        downlinkpower, ...
        uplinkpower, ...
        reflectionpointshandle, ...
        transmissionpointshandle, ...
        arity, ...
        1, numtasks, ...
        settings);
    
end

% Convert array of structs to a single tabular struct
interactions = tabularvertcat(interactions);

if settings.Reporting
    % Remap sequence index so values start at 1 and are contiguous
    pathlabels = tabulartomatrix(interactions, 'SequenceIndex', 'Identifier');
    [~, ~, identifiers] = unique(pathlabels, 'rows');
    interactions.Identifier = identifiers;
    interactions = rmfield(interactions, 'SequenceIndex');
end

end

% -------------------------------------------------------------------------
function [downlinkpower, uplinkpower, interactions] = spmdbody( ...
    downlinkpower, uplinkpower, ...
    reflectionpoints, transmissionpoints, ...
    arity, firstglobalindex, numlocalcandidates, settings)

if settings.Reporting
    nodetables = cell(numlocalcandidates, 1);
end

    function result = evaluatechecked(fun, varargin)
        result = feval(fun, varargin{:});
        if not(ndebug || all(isfinite(result)))
            warning([mfilename ':NaNInfGainFunction'], ...
                'Gain function %s returns nan or inf', func2str(fun))
        end
    end

    function [globalstep, candidatefaceindices] = nexttask(localstep)
        globalstep = firstglobalindex + localstep - 1;
        candidatefaceindices = imagemethodsequence( ...
            globalstep, settings.Scene.NumFacets, arity);
    end

% Frequency with which to print progress line
chunksize = fix(1/4*numlocalcandidates);

% The reflection points for each candidate
% sequence of facets may be checked independently
for localstep = 1 : numlocalcandidates
    
    if showiterations(settings)
        if labindex == 1 && mod(localstep, chunksize) == 1
            numcompletedsteps = localstep - 1;
            fprintf('  processed %d/%d (%.0f%%)\n', ...
                numcompletedsteps, ...
                numlocalcandidates, ...
                100*numcompletedsteps/numlocalcandidates)
        end
    end
    
    [globalstep, candidatefaceindices] = nexttask(localstep);
    
    % Compute reflection points
    [segments.SourceIndex, segments.SinkIndex, pathpoints] = ...
        reflectionpoints(candidatefaceindices);
    
    if isempty(segments.SourceIndex)
        % No paths exist between any source-receiver pairing
        continue
    end
    
    % Key dimensions
    numfacesperpath = numel(candidatefaceindices);
    numraysperpath = numfacesperpath + 1;
    numpaths = numel(segments.SourceIndex);
    
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
    segmentlengths = twonorm(directions, 2);
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
        vec(rayid(:, 2 : end)), ...
        vec(reflectiongainonpaths), ...
        [numpaths, 1]);
    
    % Gain (all negative) for each transmission node (see Note above)
    alldirections = stack(directions);
    transmission.Direction = alldirections(transmission.RayIndex, :);
    transmission.GainOnPath = evaluatechecked( ...
        settings.TransmissionGain, ...
        transmission.FaceIndex(:), ...
        transmission.Direction); % "incoming"
    gain.Transmission = accumarray( ...
        vec(rayid(transmission.RayIndex)), ...
        vec(transmission.GainOnPath), ...
        [numpaths, 1]);
    
    % Path gain in dBW
    gain.Path = gain.Free + gain.Reflection + gain.Transmission;
    
    % Accumulate sums of powers (watts) over source-receiver
    % pairs to update downlink- and uplink received power
    accumulate = @(inout, gaindb) inout + accumarray( ...
        [segments.SinkIndex(:), segments.SourceIndex(:)], ...
        fromdb(gaindb), ... % NB: Convert dB to watts
        size(inout));
    downlinkpower = accumulate(downlinkpower, gain.Source + gain.Path);
    uplinkpower = accumulate(uplinkpower, gain.Sink + gain.Path);
    
    if settings.Reporting
        
        numtransmissions = numel(transmission.FaceIndex);
        segments.SourceType = repmat(interaction.Source, numpaths, 1);
        segments.SinkType = repmat(interaction.Sink, numpaths, 1);
        segments.ReflectionType = repmat(interaction.Reflection, numpaths, numfacesperpath);
        transmission.Type = repmat(interaction.Transmission, numtransmissions, 1);
        transmission.Blank = blank(transmission.FaceIndex);
        
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
        nodetables{localstep} = tabularrows(nodetable, permutation);
        
    end
    
end

if settings.Reporting
    % Discards empty cell elements and produces one structure array
    interactions = [nodetables{:}];
else
    % An "empty" tablular struct
    interactions = struct;
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

% -------------------------------------------------------------------------
function show = showheadings(settings)
show = 0 < settings.Verbosity;
end

function show = showiterations(settings)
show = 1 < settings.Verbosity;
end

function show = showdetails(settings)
show = 2 < settings.Verbosity;
end
