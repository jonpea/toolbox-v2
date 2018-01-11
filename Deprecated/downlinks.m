function ...
    [sinrdb, assignedsource, signaldb, interferenceplusnoisedb] = ...
    downlinks(linkgaindb, sourcegaindb, sourcechannel, varargin)
%DOWNLINKS Downlink SINR and channel.

% Preconditions
narginchk(2, 4)
if nargin < 3 || isempty(sourcegaindb)
    sourcegaindb = zeros(size(sourcechannel));
end
assert(ismatrix(linkgaindb))
assert(isvector(sourcegaindb))
assert(isvector(sourcechannel))
assert(isequal(fix(sourcechannel), sourcechannel))
assert(size(linkgaindb, 2) == numel(sourcegaindb))
assert(size(linkgaindb, 2) == numel(sourcechannel))

% For each sampling point, maximize received power over access points
downlinkpowerwatts = fromdb(bsxfun(@plus, linkgaindb, sourcegaindb(:)'));
[signalwatts, assignedsource] = max(downlinkpowerwatts, [], 2);

% Interference power involves distinct pairings on the same channel
% i.e. a given source/access point does not interfere with itself
% and there is no interference across channels
allsources = 1 : numel(sourcechannel);
issamesource = rowcolumn(@eq, assignedsource, allsources);
isdifferentchannel = rowcolumn(@ne, sourcechannel(assignedsource), sourcechannel(allsources));
downlinkpowerwatts(issamesource | isdifferentchannel) = 0; % drop "non-interfering" elements
mdswatts = fromdb(minimumdiscernablesignal(varargin{:}));
interferenceplusnoisewatts = ...
    sum(downlinkpowerwatts, 2) + ... % interference
    mdswatts; % noise

signaldb = todb(signalwatts);
interferenceplusnoisedb = todb(interferenceplusnoisewatts);
sinrdb = signaldb - interferenceplusnoisedb;

function c = rowcolumn(fun, a, b)
c = bsxfun(fun, a(:), b(:)');
