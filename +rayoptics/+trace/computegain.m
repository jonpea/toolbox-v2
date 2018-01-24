function result = computegain(hits, gainFuns)

narginchk(1, 2)
if nargin == 1
    % Arguments have been packaged into a single struct
    gainFuns = hits.Functions;
    hits = hits.Data;
end
import datatypes.struct.tabular.istabular
assert(istabular(hits))
assert(isstruct(gainFuns))

numHitTypes = numel(enumeration('rayoptics.NodeTypes'));

% Partition interactions by type
% e.g. interactionrows{double(transmission)} returns
% indices into the rows of the table of interactions
hitRowsByType = accumarray( ...
    double(hits.InteractionType), ...
    (1 : numel(hits.InteractionType))', ...
    [numHitTypes, 1], ...
    @(indices) {indices});

    function result = evaluateGainDBW(type)
        % Computes gains for each type of interaction
        index = rayoptics.NodeTypes(type);
        result = feval( ...
            gainFuns.(type), ... % function/head
            hits.ObjectIndex(hitRowsByType{index}, :), ... % interaction object
            hits.Direction(hitRowsByType{index}, :)); % ray/beam direction
    end

    function result = accululateFor(type)
        % Accumulates gains of a given interaction type into a column
        % vector with as many rows as there are interactions of all types;
        % rows corresponding to other types of intereactions contain zeros
        result = accumarray( ...
            hitRowsByType{rayoptics.NodeTypes(type)}(:), ...
            evaluateGainDBW(type), ...
            size(hits.SegmentIndex)); % previously 'RayIndex'
    end

% Compute gain associated with individual interactions
sourceGain = accululateFor('Source'); 
reflectionGain = accululateFor('Reflection');
transmissionGain = accululateFor('Transmission');

% Aggregate sparse (with dense storage) vectors into a single column
hits.InteractionGain = ...
    sourceGain + reflectionGain + transmissionGain;

% Extracts source wavelength for each reflected path
isSource = hits.InteractionType == rayoptics.NodeTypes.Source;
isSink = hits.InteractionType == rayoptics.NodeTypes.Sink;
numPaths = numel(unique(hits.Identifier));
assert(sum(isSource) == numPaths)
assert(sum(isSink) == numPaths)
sourceIndex = hits.ObjectIndex(isSource, :);

% Friis free-space gains
totalDistance = accumarray(hits.Identifier, hits.FreeDistance);
freeGainByPathDBW = gainFuns.Free(sourceIndex, totalDistance);

% Accumulate gains over paths
interactionGainByPathDBW = accumarray( ...
    hits.Identifier, ...
    hits.InteractionGain); % [dBW]
totalGainByPathDBW = freeGainByPathDBW + interactionGainByPathDBW;

% This function assigns given values to the rows of an array (whose rows
% are assocated with hits) corresponding to sink nodes
selectSink = hits.InteractionType == rayoptics.NodeTypes.Sink;
    function result = assignSinks(values)
        result = zeros(size(hits.FreeDistance), 'like', values);
        result(selectSink) = values;
    end

hits.TotalDistance = assignSinks(totalDistance);
hits.FreeGain = assignSinks(freeGainByPathDBW);
hits.PathInteractionGain = assignSinks(interactionGainByPathDBW);
hits.TotalGainDBW = assignSinks(totalGainByPathDBW);
hits.TotalGain = assignSinks(specfun.fromdb(totalGainByPathDBW));

% Sanity checks
assert(all(isfinite(hits.FinalDistance)))
assert(all(isfinite(hits.TotalDistance)))
assert(isequal(size(hits.FinalDistance), size(hits.TotalDistance)))
assert(norm(hits.FinalDistance - hits.TotalDistance, inf) < 1e-10)

result = orderfields(hits, { ...
    'Identifier'
    'ObjectIndex'
    'InteractionType'
    'InteractionGain'
    'TotalDistance'
    'FreeGain'
    'PathInteractionGain'
    'TotalGainDBW' % previously 'TotalGain'
    'TotalGain' % previously 'Power'
    'SegmentIndex' % previously 'RayIndex'
    'Parameter' % previously 'RayParameter'
    'Position' % previously 'IntersectionPoint'
    'FreeDistance'
    'FinalDistance'
    'Direction'
    'SourceGain'
    'SinkGain'
    });

assert(istabular(result))

end
