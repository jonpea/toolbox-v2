function result = butterworthtxpositions
% Tranmitter locations: "Manually" read from 
% guid-lines inserted on "level8locs.vsd" in Visio
origin = [36, 38]; % [mm] "on page"
zenith = [190, 192];
txa = [77, 152]; % [mm] "on page"
txb = [150, 79]; % [mm] "on page"
width = unique(zenith - origin); % [mm] "on page"
assert(isscalar(width)) % "square plan"
scale = 18.5/width; % [mm] -> [m]
txpoints = scale*[
    (txa - origin);
    (txb - origin);
    ]; % [m] from origin at lower left corner

result = nan(12, 2);
result([9, 12], :) = txpoints;
