function [stats, powerTable, gainTable] = process(trace)

hits = rayoptics.trace.computegain(trace);

isReflection = hits.InteractionType == rayoptics.NodeTypes.Reflection;
pathNumReflections = accumarray(hits.Identifier, isReflection);
pathGain = accumarray(hits.Identifier, hits.TotalGain);
[numReflectionsUnique, ~, map] = unique(pathNumReflections);
totalGain = accumarray(map, pathGain); % Watts/Watt

stats = struct( ...
    'NumReflections', numReflectionsUnique, ...
    'Gain', totalGain, ...
    'RelativeGain', totalGain/sum(totalGain));

isSink = hits.InteractionType == rayoptics.NodeTypes.Sink;
isSource = hits.InteractionType == rayoptics.NodeTypes.Source;

% Sanity check: One source and one sink per path
assert(all(accumarray(hits.Identifier, isSink) == 1))
assert(all(accumarray(hits.Identifier, isSource) == 1))

pathSinkIndex = accumarray( ...
    hits.Identifier(isSink), ...
    hits.ObjectIndex(isSink));
pathSourceIndex = accumarray( ...
    hits.Identifier(isSource), ...
    hits.ObjectIndex(isSource));

pathNodeGainDBW = accumarray( ...
    hits.Identifier, ...
    hits.InteractionGain);
pathFreeGainDBW = accumarray( ...
    hits.Identifier, ...
    hits.FreeGain);
pathGainDBW = pathFreeGainDBW + pathNodeGainDBW;

subscripts = [pathSinkIndex, pathSourceIndex, pathNumReflections + 1];
powerTable = accumarray(subscripts, pathGain);
gainTable = accumarray(subscripts, pathGainDBW);
