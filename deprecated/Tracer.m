classdef Tracer < handle
    
    properties
        pairedsourceindices
        pairedsinkindices
        downlinkpower
        uplinkpower
        interactions
    end
    
    methods
        function [downlinkpower, uplinkpower, interactions] = spmdbody( ...
                arity, origins, targets, settings, firstglobalindex, numlocalcandidates)
            
            % Key dimensions
            numorigins = size(origins, 1);
            numtargets = size(targets, 1);
            
            % Broadcast arrays: Shared by each parallel worker
            [pairedsourceindices, pairedsinkindices] = deal(zeros(numorigins*numtargets, 1));
            [pairedsourceindices(:), pairedsinkindices(:)] = ndgrid(1 : numorigins, 1 : numtargets);
            sourcepoints = origins(pairedsourceindices, :);
            sinkpoints = targets(pairedsinkindices, :);
            
            [uplinkpower, downlinkpower] = deal(zeros(numtargets, numorigins));
            interactions = cell(numlocalcandidates, 1);
            
            function result = evaluatechecked(fun, varargin)
                result = feval(fun, varargin{:});
                if not(ndebug || all(isfinite(result)))
                    warning([mfilename ':NaNInfGainFunction'], ...
                        'Gain function %s returns nan or inf', func2str(fun))
                end
            end
            
            % Sum powers (in watts) and place result on worker #1
            reduce = @(distributed) gplus(distributed, 1);
            downlinkpower = reduce(downlinkpower);
            uplinkpower = reduce(uplinkpower);
            
            if settings.Reporting
                % Discards empty cell elements and produces one structure array
                interactions = [interactions{:}];
            end
            
        end
        
        function [uplinkpower, downlinkpower] = run(obj, jobid, uplinkpower, downlinkpower)
            
            arity = jobid(1);
            globalstep = jobid(2);
            
            candidatefaceindices = imagemethodsequence( ...
                globalstep, obj.Scene.NumFacets, arity);
            
            % Compute reflection points
            [pairindices, pathpoints] = imagemethod( ...
                obj.Scene.IntersectFacet, ...
                obj.Scene.Mirror, ...
                candidatefaceindices, ...
                sourcepoints, ...
                sinkpoints);
            %
            %
            % reflection = ReflectionPoints( ...
            %           candidatefaceindices, sourcepoints, sinkpoints)
            % reflection.Indices
            % reflection.Points
            %
            %
            
            if isempty(pairindices)
                % No paths exist between any source-receiver pairing
                return
            end
            
            % Structs serving as "mini-namespaces" to reduce clutter
            [source, sink, ray, free, reflection, transmission] = deal(struct);
            
            % Key dimensions
            numfacesperpath = numel(candidatefaceindices);
            numraysperpath = numfacesperpath + 1;
            numpaths = numel(pairindices);
            
            % Rays defining each ray/segment
            directions = diff(pathpoints, 1, 3);
            
            source.indices = obj.pairedsourceindices(pairindices, :);
            sink.indices = obj.pairedsinkindices(pairindices, :);
            
            % Indices/identifiers for each ray and each ray segment
            pathid = 1 : numpaths;
            rayid = repmat(pathid(:), 1, numraysperpath);
            segmentindex = repmat(1 : numraysperpath, numpaths, 1);
            
            % Compute ray-face intersections:
            % Intersections comprise reflection- and transmission points, so
            % drop reflection points from list of candidate transmission points
            % i.e. those at the beginning or end of a line segment
            startingtime = tic;
            intersections = tracesegments( ...
                obj.Scene, ...
                pathpoints(:, :, 1 : end - 1), ...
                directions, ...
                candidatefaceindices); % "exclude known reflection points"
            elapsed = toc(startingtime);
            %
            %
            % transmission = TransmissionPoints( ...
            %       pathpoints(:, :, 1 : end - 1), ...
            %       directions, ...
            %       candidatefaceindices)
            %
            %
            
            if showdetail(settings)
                fprintf('%d: %d rays: %g sec\n', ...
                    arity, ...
                    size(directions, 1)*size(directions, 3), ...
                    elapsed)
            end
            
            % Friis free-space gain (all negative) for each path
            segmentlengths = twonorm(directions, 2);
            free.pathlength = sum(segmentlengths, 3);
            free.gain = feval(obj.FreeGain, source.indices, free.pathlength);
            
            % Gain (all positive) for source node on each path
            source.gain = evaluatechecked( ...
                obj.SourceGain, ...
                source.indices, ...
                directions(:, :, 1)); % "outgoing"
            
            % Gain (all negative) for sink node on each each path
            sink.gain = evaluatechecked( ...
                obj.SinkGain, ...
                sink.indices, ...
                directions(:, :, end)); % "incoming"
            
            % Gains (all negative) for each reflection node
            % Note: If spatially-varying transmission coefficients were ever
            % to be supported, function TransmissionGain would have the array
            % of intersection points as an additional argument.
            reflection.faceindices = ...
                repmat(candidatefaceindices(:)', numpaths, 1);
            reflectiongainonpaths = evaluatechecked( ...
                obj.ReflectionGain, ...
                reflection.faceindices(:), ...
                stack(directions(:, :, 1 : end - 1))); % "incoming"
            reflection.gain = accumarray( ...
                vec(rayid(:, 2 : end)), ...
                vec(reflectiongainonpaths), ...
                [numpaths, 1]);
            
            % Gain (all negative) for each transmission node (see Note above)
            ray.directions = stack(directions);
            transmission.directions = ray.directions(intersections.RayIndex, :);
            transmissiongainonpaths = evaluatechecked( ...
                obj.TransmissionGain, ...
                intersections.FaceIndex(:), ...
                ray.directions(intersections.RayIndex, :)); % "incoming"
            transmission.gain = accumarray( ...
                vec(rayid(intersections.RayIndex)), ...
                vec(transmissiongainonpaths), ...
                [numpaths, 1]);
            
            % Accumulate sums of powers (watts) over source-receiver pairs
            accumulate = @(gaindb) ...
                accumarray( ...
                [sink.indices(:), source.indices(:)], ...
                fromdb(gaindb), ...
                [numtargets, numorigins]);
            
            % Path gain in dBW
            path.gain = free.gain + reflection.gain + transmission.gain;
            
            % Downlink- and uplink received power in watts
            obj.downlinkpower = obj.downlinkpower + accumulate(source.gain + path.gain);
            obj.uplinkpower = obj.uplinkpower + accumulate(sink.gain + path.gain);
            
            if obj.Reporting
                
                assert(istabular(source))
                assert(istabular(sink))
                assert(istabular(free))
                assert(istabular(reflection))
                %assert(istabular(transmission))
                
                numtransmissions = numel(intersections.FaceIndex);
                sourcetypes = repmat(interaction.Source, numpaths, 1);
                sinktypes = repmat(interaction.Sink, numpaths, 1);
                reflectiontypes = repmat(interaction.Reflection, numpaths, numfacesperpath);
                transmission.types = repmat(interaction.Transmission, numtransmissions, 1);
                transmission.blank = blank(intersections.FaceIndex);
                
                % In each field, we have:
                % - block #1: [source, reflection] data, together defining rays
                % - block #2: transmission data
                % - block #3: sink/receiver data
                % Note well:
                % 1) "source" and "reflection" data are packed together
                %    deliberately to form "ray" data ("source + direction")
                % 2) "vec([source, reflection])" <-- correct
                %    as opposed to
                %    "[source(:); reflection(:)]" <-- incorrect
                
                nodetable = struct( ...
                    'SequenceIndex', [
                    vec(repmat(globalstep, numpaths*numraysperpath, 1));
                    vec(repmat(globalstep, numtransmissions, 1));
                    vec(repmat(globalstep, numpaths, 1));
                    ], ...
                    'Identifier', [
                    vec(rayid);
                    vec(rayid(intersections.RayIndex));
                    vec(pathid);
                    ], ...
                    'RayIndex', [
                    vec(segmentindex);
                    vec(segmentindex(intersections.RayIndex));
                    vec(repmat(numraysperpath + 1, numpaths, 1));
                    ], ...
                    'RayParameter', [
                    zeros(numpaths*numraysperpath, 1);
                    intersections.RayParameter;
                    ones(numpaths, 1);
                    ], ...
                    'ObjectIndex', [
                    vec([source.indices, reflection.faceindices]);
                    intersections.FaceIndex;
                    sink.indices;
                    ], ...
                    'InteractionType', [
                    vec([sourcetypes, reflectiontypes]);
                    transmission.types;
                    sinktypes;
                    ], ...
                    'IntersectionPoint', [
                    stack(pathpoints(:, :, 1 : end - 1));
                    intersections.Point;
                    pathpoints(:, :, end);
                    ], ...
                    'Direction', [
                    stack(directions(:, :, [1, 1 : end - 1]));
                    transmission.directions;
                    directions(:, :, end);
                    ], ...
                    'FreeDistance', [
                    stack(segmentlengths);
                    transmission.blank;
                    zeros(size(free.pathlength));
                    ], ...
                    'FinalDistance', [
                    vec(zeros(numpaths, numraysperpath));
                    transmission.blank;
                    free.pathlength;
                    ], ...
                    'SourceGain', [
                    vec([source.gain, zeros(numpaths, numfacesperpath)]);
                    blank(transmissiongainonpaths);
                    blank(sink.gain);
                    ]);
                
                assert(istabular(nodetable))
                
                % Sort nodes on each path by ray index and
                % ray parameter, and sort paths by path index
                [~, permutation] = sortrows([
                    nodetable.Identifier, ...
                    nodetable.RayIndex, ...
                    nodetable.RayParameter
                    ]);
                
                % Store for aggregation
                obj.interactions{end + 1} = ...
                    tabularrows(nodetable, permutation);
                
            end
            
        end
        
    end
end

% =========================================================================
function hitsall = tracesegments(scene, origins, directions, faceindices)
narginchk(4, 4)
assert(isequal(size(origins), size(directions)))
assert(size(origins, 3) == numel(faceindices) + 1)
hitsall = scene.Intersect(origins, directions, faceindices);
% hitsallembree = SETTINGS.Private.Embree.Intersect(origins, directions, faceindices);
% comparehits(hitsall, hitsallembree, [])
end

% =========================================================================
function blank = blank(a)
blank = zeros(size(a));
end

% =========================================================================
function x = stack(x)
%STACK Stacks the layers of a 3D array.
% STACK(CAT(3,A,B,C,...)) returns [A; B; C; ...] if A, B, C are matrices.
x = permute(x, [1 3 2]);
x = reshape(x, [], size(x, 3));
end

% =========================================================================
function show = showdetail(settings)
show = 1 < settings.Verbosity;
end
