function result = linkinterference(linkgaindb, assignedsource, sourcechannel, dim)
% Interference power involves distinct pairings on the same channel
% i.e. a given source/access point does not interfere with itself
% and there is no interference across channels
allsources = 1 : numel(sourcechannel);
    function c = rowcolumn(fun, a, b)
        c = bsxfun(fun, a(:), b(:)');
    end
issamesource = rowcolumn( ...
    @eq, ...
    assignedsource, ...
    allsources);
isdifferentchannel = rowcolumn( ...
    @ne, ...
    sourcechannel(assignedsource), ...
    sourcechannel(allsources));
linkgainwatts = elfun.fromdb(linkgaindb);
linkgainwatts(issamesource | isdifferentchannel) = 0.0; % drop "non-interfering" elements
result = sum(linkgainwatts, dim);
end
