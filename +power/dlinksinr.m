function result = dlinksinr(linkgaindb, sourcechannel, mdsdb)

dim = 2; % operate across columns / along rows

% Preconditions
narginchk(3, 3)
assert(ismatrix(linkgaindb))
assert(isvector(sourcechannel))
assert(isround(sourcechannel))
assert(size(linkgaindb, dim) == numel(sourcechannel))
assert(isscalar(dim) && isround(dim))
assert(isscalar(mdsdb) && mdsdb < 0)

% For each sampling point, maximize received power over access points
[signaldb, assignedsource] = max(linkgaindb, [], dim);

interferencewatts = linkinterference(linkgaindb, assignedsource, sourcechannel, 2);
noisewatts = fromdb(mdsdb);
interferenceplusnoisedb = todb(interferencewatts + noisewatts);

result = struct( ...
    'AccessPoint', assignedsource, ...
    'Channel', sourcechannel(assignedsource), ...
    'SINRatio', signaldb - interferenceplusnoisedb, ...
    'SGainDBW', signaldb, ...
    'INGainDBW', interferenceplusnoisedb);

end
