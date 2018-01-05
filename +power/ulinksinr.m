function result = ulinksinr(linkgaindb, assignedsource, sourcechannel, mdsdb)

% Preconditions
narginchk(4, 4)
assert(ismatrix(linkgaindb))
assert(isvector(assignedsource) && isround(assignedsource))
assert(isvector(sourcechannel) && isround(sourcechannel))
assert(size(linkgaindb, 1) == numel(assignedsource))
assert(size(linkgaindb, 2) == numel(sourcechannel))
assert(isscalar(mdsdb) && mdsdb < 0)

% Received uplink power at the access point from each mobile
allrows = 1 : numel(assignedsource);
oneperrow = sub2ind(size(linkgaindb), allrows(:), assignedsource(:));
signaldb = linkgaindb(oneperrow);
signaldb = signaldb(:);

interferencewatts = linkinterference(linkgaindb, assignedsource, sourcechannel, 1);
noisewatts = fromdb(mdsdb);
interferenceplusnoisedball = todb(interferencewatts(:) + noisewatts);

% Store uplink INP of current access poin in all connected mobiles
inpdb = interferenceplusnoisedball(assignedsource, :);

result = struct( ...
    'SINRatio', signaldb - inpdb, ...
    'SGainDBW', signaldb, ...
    'INGainDBW', inpdb);

end
