function result = linkinterference(linkGainDB, assignedSource, sourceChannel, dim)
% Interference power involves distinct pairings on the same channel
% i.e. a given source/access point does not interfere with itself
% and there is no interference across channels
allSources = 1 : numel(sourceChannel);
    function c = rowColumn(fun, a, b)
        c = bsxfun(fun, a(:), b(:)');
    end
isSameSource = rowColumn( ...
    @eq, ... % "equals", ==
    assignedSource, ...
    allSources);
isDifferentChannel = rowColumn( ...
    @ne, ... % "not equals", ~=
    sourceChannel(assignedSource), ...
    sourceChannel(allSources));
linkGainWatts = specfun.fromdb(linkGainDB);
linkGainWatts(isSameSource | isDifferentChannel) = 0.0; % drop "non-interfering" elements
result = sum(linkGainWatts, dim);
end
