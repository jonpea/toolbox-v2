function result = downlinkSINR(linkGainDB, sourceChannel, mdsdb)

dim = 2; % operate across columns / along rows

% Preconditions
narginchk(3, 3)
assert(ismatrix(linkGainDB))
assert(isvector(sourceChannel))
assert(isequal(fix(sourceChannel), sourceChannel))
assert(size(linkGainDB, dim) == numel(sourceChannel))
assert(isscalar(dim) && isequal(fix(dim), dim))
assert(isscalar(mdsdb) && mdsdb < 0)

% For each sampling point, maximize received power over access points
[signalDBW, assignedSource] = max(linkGainDB, [], dim);

interferenceWatts = power.linkinterference( ...
    linkGainDB, assignedSource, sourceChannel, 2);
noiseWatts = specfun.fromdb(mdsdb);
interferencePlusNoiseDB = specfun.todb(interferenceWatts + noiseWatts);

result = struct( ...
    'AccessPoint', assignedSource, ...
    'Channel', sourceChannel(assignedSource), ...
    'SINRatio', signalDBW - interferencePlusNoiseDB, ...
    'SGainDBW', signalDBW, ...
    'INGainDBW', interferencePlusNoiseDB);

end
