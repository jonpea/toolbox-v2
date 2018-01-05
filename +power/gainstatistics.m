function [stats, powertable, gaintable] = gainstatistics(interactions)

isreflection = interactions.InteractionType == interaction.Reflection;
pathnumreflections = accumarray(interactions.Identifier, isreflection);
pathpower = accumarray(interactions.Identifier, interactions.Power);
[numreflectionsunique, ~, map] = unique(pathnumreflections);
totalpower = accumarray(map, pathpower);

stats = struct( ...
    'NumReflections', numreflectionsunique, ...
    'TotalPower', totalpower, ...
    'RelativePower', totalpower/sum(totalpower));

numunique = @(e) numel(unique(e));
issink = interactions.InteractionType == interaction.Sink;
issource = interactions.InteractionType == interaction.Source;

% One source and one sink per path
assert(all(accumarray(interactions.Identifier, issink) == 1))
assert(all(accumarray(interactions.Identifier, issource) == 1))
pathsink = accumarray( ...
    interactions.Identifier(issink), interactions.ObjectIndex(issink));
pathsource = accumarray( ...
    interactions.Identifier(issource), interactions.ObjectIndex(issource));

pathnodegain = accumarray(interactions.Identifier, interactions.InteractionGain);
pathfreegain = accumarray(interactions.Identifier, interactions.FreeGain);
pathgain = pathfreegain + pathnodegain;

subscripts = [pathsink, pathsource, pathnumreflections + 1];
powertable = accumarray(subscripts, pathpower);
gaintable = accumarray(subscripts, pathgain);
