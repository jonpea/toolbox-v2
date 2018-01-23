function [stats, powerTable, gainTable] = process(trace)

hits = power.computegain(trace);

isReflection = hits.InteractionType == rayoptics.NodeTypes.Reflection;
pathNumReflections = accumarray(hits.Identifier, isReflection);
pathPower = accumarray(hits.Identifier, hits.Power);
[numReflectionsUnique, ~, map] = unique(pathNumReflections);
totalPower = accumarray(map, pathPower);

stats = struct( ...
    'NumReflections', numReflectionsUnique, ...
    'TotalPower', totalPower, ...
    'RelativePower', totalPower/sum(totalPower));

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
powerTable = accumarray(subscripts, pathPower);
gainTable = accumarray(subscripts, pathGainDBW);
