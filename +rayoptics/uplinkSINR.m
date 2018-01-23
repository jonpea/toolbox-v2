function result = uplinkSINR(linkGainDB, assignedSource, sourceChannel, mdsdb)

% Preconditions
narginchk(4, 4)
assert(ismatrix(linkGainDB))
assert(isvector(assignedSource))
assert(isvector(sourceChannel))
assert(size(linkGainDB, 1) == numel(assignedSource))
assert(size(linkGainDB, 2) == numel(sourceChannel))
assert(isscalar(mdsdb) && mdsdb < 0)

% Received uplink power at the access point from each mobile
allRows = 1 : numel(assignedSource);
onePerRow = sub2ind(size(linkGainDB), allRows(:), assignedSource(:));
signalDB = linkGainDB(onePerRow);
signalDB = signalDB(:);

interferenceWatts = linkInterference( ...
    linkGainDB, assignedSource, sourceChannel, 1);
noiseWatts = specfun.fromdb(mdsdb);
interferencePlusNoiseDBAll = ...
    specfun.todb(interferenceWatts(:) + noiseWatts);

% Store uplink INP of current access poin in all connected mobiles
interferencePlusNoiseDB = interferencePlusNoiseDBAll(assignedSource, :);

result = struct( ...
    'SINRatio', signalDB - interferencePlusNoiseDB, ...
    'SGainDBW', signalDB, ...
    'INGainDBW', interferencePlusNoiseDB);

end
