function stats = frequencies(trace)

interactiontypes = trace.Data.InteractionType;

count = @(type) sum(rayoptics.NodeTypes.(type) == interactiontypes);
numSources = count('Source');
numSinks = count('Sink');
numReflections = count('Reflection');
numTransmissions = count('Transmission');
numNodes = numel(interactiontypes);
absoluteAndRelative = @(n) [n; n/numNodes];
stats = struct( ...
    'Measure', {{'Absolute'; 'Relative'}}, ...
    'Source', absoluteAndRelative(numSources), ...
    'Sink', absoluteAndRelative(numSinks), ...
    'Reflection', absoluteAndRelative(numReflections), ...
    'Transmission', absoluteAndRelative(numTransmissions), ...
    'All', absoluteAndRelative(numNodes));
