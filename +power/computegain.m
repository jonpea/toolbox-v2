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

    function result = evaluate(type)
        % Computes gains for each type of interaction
        index = rayoptics.NodeTypes(type);
        result = feval( ...
            gainFuns.(type), ... % function/head
            hits.ObjectIndex(hitRowsByType{index}, :), ... % interaction object
            hits.Direction(hitRowsByType{index}, :)); % ray/beam direction
    end

    function result = accululatefor(type, transform)
        % Accumulates gains of a given interaction type into a column
        % vector with as many rows as there are interactions of all types;
        % rows corresponding to other types of intereactions contain zeros
        result = accumarray( ...
            hitRowsByType{rayoptics.NodeTypes(type)}(:), ...
            transform(evaluate(type)), ...
            size(hits.SegmentIndex)); % previously 'RayIndex'
    end

% Compute gain associated with individual interactions
sourceGain = accululatefor('Source', @elfun.identity); % @todb in old version
reflectionGain = accululatefor('Reflection', @elfun.identity);
transmissionGain = accululatefor('Transmission', @elfun.identity);

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
freeGainByPath = gainFuns.Free(sourceIndex, totalDistance);

% Accumulate gains over paths
interactionGainByPath = accumarray(hits.Identifier, hits.InteractionGain); % [dBw]
totalGainByPath = freeGainByPath + interactionGainByPath;
power = specfun.fromdb(totalGainByPath);

% This function assigns given values to the rows of an array (whose rows
% are assocated with hits) corresponding to sink nodes
selectsink = hits.InteractionType == rayoptics.NodeTypes.Sink;
    function result = assignSinks(values)
        result = zeros(size(hits.FreeDistance));
        result(selectsink) = values;
    end

hits.TotalDistance = assignSinks(totalDistance);
hits.FreeGain = assignSinks(freeGainByPath);
hits.PathInteractionGain = assignSinks(interactionGainByPath);
hits.TotalGain = assignSinks(totalGainByPath);
hits.Power = assignSinks(power);

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
    'TotalGain'
    'Power'
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
