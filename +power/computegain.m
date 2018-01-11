function result = computegain(gainfunctions, interactions)

narginchk(1, 2)
if nargin == 1
    % Arguments have been packaged into a single struct
    interactions = gainfunctions.Data;
    gainfunctions = gainfunctions.Functions;
end
assert(datatypes.struct.tabular.istabular(interactions))
assert(isstruct(gainfunctions))

numinteractiontypes = numel(enumeration('imagemethod.interaction'));

% Partition interactions by type
% e.g. interactionrows{double(transmission)} returns
% indices into the rows of the table of interactions
interactionrows = accumarray( ...
    double(interactions.InteractionType), ...
    (1 : numel(interactions.InteractionType))', ...
    [numinteractiontypes, 1], ...
    @(indices) {indices});

    function result = evaluate(type)
        % Computes gains for each type of interaction
        index = imagemethod.interaction(type);
        result = feval( ...
            gainfunctions.(type), ... % function/head
            interactions.ObjectIndex(interactionrows{index}, :), ... % interaction object
            interactions.Direction(interactionrows{index}, :)); % ray/beam direction
    end

    function result = accululatefor(type, transform)
        % Accumulates gains of a given interaction type into a column
        % vector with as many rows as there are interactions of all types;
        % rows corresponding to other types of intereactions contain zeros
        result = accumarray( ...
            interactionrows{imagemethod.interaction(type)}(:), ...
            transform(evaluate(type)), ...
            size(interactions.SegmentIndex)); % previously 'RayIndex'
    end

% Compute gain associated with individual interactions
sourcegain = accululatefor('Source', @elfun.identity); % @todb in old version
reflectiongain = accululatefor('Reflection', @elfun.identity);
transmissiongain = accululatefor('Transmission', @elfun.identity);

% Aggregate sparse (with dense storage) vectors into a single column
interactions.InteractionGain = ...
    sourcegain + reflectiongain + transmissiongain;

% Extracts source wavelength for each reflected path
issource = interactions.InteractionType == imagemethod.interaction.Source;
issink = interactions.InteractionType == imagemethod.interaction.Sink;
numpaths = numel(unique(interactions.Identifier));
assert(sum(issource) == numpaths)
assert(sum(issink) == numpaths)
sourceid = interactions.ObjectIndex(issource, :);

% Friis free-space gains
totaldistance = accumarray(interactions.Identifier, interactions.FreeDistance);
freegain = gainfunctions.Free(sourceid, totaldistance);

% Accumulate gains over paths
interactiongain = accumarray( ...
    interactions.Identifier, interactions.InteractionGain);
totalgain = freegain + interactiongain;
power = elfun.fromdb(totalgain);

% This function assigns given values to the rows of an array (whose rows
% are assocated with interactions) corresponding to sink nodes
selectsink = interactions.InteractionType == imagemethod.interaction.Sink;
    function result = assignsinks(values)
        result = zeros(size(interactions.FreeDistance));
        result(selectsink) = values;
    end

interactions.TotalDistance = assignsinks(totaldistance);
interactions.FreeGain = assignsinks(freegain);
interactions.PathInteractionGain = assignsinks(interactiongain);
interactions.TotalGain = assignsinks(totalgain);
interactions.Power = assignsinks(power);

import contracts.ndebug
assert(ndebug || all(isfinite(interactions.FinalDistance)))
assert(ndebug || all(isfinite(interactions.TotalDistance)))
assert(ndebug || isequal(size(interactions.FinalDistance), size(interactions.TotalDistance)))
assert(ndebug || norm(interactions.FinalDistance - interactions.TotalDistance, inf) < 1e-10)

result = orderfields(interactions, { ...
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

end
