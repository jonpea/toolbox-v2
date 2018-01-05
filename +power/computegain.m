function result = computegain(gainfunctions, interactions)

narginchk(1, 2)
if nargin == 1
    % Arguments have been packaged into a single struct
    interactions = gainfunctions.Data;
    gainfunctions = gainfunctions.Functions;
end
assert(istabular(interactions))
assert(isstruct(gainfunctions))

numinteractiontypes = numel(enumeration('interaction'));

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
        index = interaction(type);
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
            interactionrows{interaction(type)}(:), ...
            transform(evaluate(type)), ...
            size(interactions.SegmentIndex)); % previously 'RayIndex'
    end

% Compute gain associated with individual interactions
timer = starttimer('evaluating interaction gain functions...');
sourcegain = accululatefor('Source', @identity); % @todb in old version
reflectiongain = accululatefor('Reflection', @identity);
transmissiongain = accululatefor('Transmission', @identity);

% Aggregate sparse (with dense storage) vectors into a single column
interactions.InteractionGain = ...
    sourcegain + reflectiongain + transmissiongain;
stoptimer(timer)

% Extracts source wavelength for each reflected path
issource = interactions.InteractionType == interaction.Source;
issink = interactions.InteractionType == interaction.Sink;
numpaths = numel(unique(interactions.Identifier));
assert(sum(issource) == numpaths)
assert(sum(issink) == numpaths)
sourceid = interactions.ObjectIndex(issource, :);

% Friis free-space gains
timer = starttimer('                     free-space gains...');
totaldistance = accumarray(interactions.Identifier, interactions.FreeDistance);
freegain = gainfunctions.Free(sourceid, totaldistance);
% freegain2 = friisgain(totaldistance, raywavelength, 'db');
% assert(norm(freegain - freegain2, inf) < 1e-14)
stoptimer(timer)

% Accumulate gains over paths
timer = starttimer('        accumulating gains over paths...');
interactiongain = accumarray( ...
    interactions.Identifier, interactions.InteractionGain);
totalgain = freegain + interactiongain;
power = fromdb(totalgain);
stoptimer(timer)

timer = starttimer('       assigning sink-specific fields...');
% This function assigns given values to the rows of an array (whose rows
% are assocated with interactions) corresponding to sink nodes
selectsink = interactions.InteractionType == interaction.Sink;
    function result = assignsinks(values)
        result = zeros(size(interactions.FreeDistance));
        result(selectsink) = values;
    end

interactions.TotalDistance = assignsinks(totaldistance);
interactions.FreeGain = assignsinks(freegain);
interactions.PathInteractionGain = assignsinks(interactiongain);
interactions.TotalGain = assignsinks(totalgain);
interactions.Power = assignsinks(power);
stoptimer(timer)

% tabulardisp(tabularhead( ...
%     tabularcolumns(interactions, 'FinalDistance', 'TotalDistance'), 10))
assert(ndebug || all(isfinite(interactions.FinalDistance)))
assert(ndebug || all(isfinite(interactions.TotalDistance)))
assert(ndebug || isequal(size(interactions.FinalDistance), size(interactions.TotalDistance)))
assert(ndebug || isequalfp(interactions.FinalDistance, interactions.TotalDistance))

timer = starttimer('                   re-ordering fields...');
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
stoptimer(timer)

end
