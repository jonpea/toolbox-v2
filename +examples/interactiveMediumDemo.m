%% From |example2| in the WyFy distribution

%%
clear
fig = figure(1);
clf(fig, 'reset')

%% New representation
% Floor plan of University of Auckland, Engineering School Tower, Level 8
[faces, vertices, transmissiongains] = data.engineeringtower8data;
reflectiongains = repmat(realmin, size(transmissiongains));
scene = scenes.Scene(faces, vertices);
accesspoints = struct( ...
    'Position', [
    14 , 5 ;
    2.5, 1 ;
    3  , 16;
    9  , 15;
    ], ...
    'Gain', [1.3; 0.4; 1.9; 0.75], ...
    'Channel', [1; 1; 2; 2]);
mobiles = struct('Position', [5, 5; 10, 11], 'Gain', [5.0; 1.0]);
gainfunctions = struct( ...
    'Source', antennae.isopattern(accesspoints.Gain), ...
    'Reflection', antennae.isopattern(1.0), ...
    'Transmission', antennae.isopattern(1.0), ...
    'Sink', antennae.isopattern(mobiles.Gain), ...
    'Free', antennae.friisfunction);

%% Initialise wyfy system,
model = interactive.Interactive( ...
    faces, vertices, ...
    accesspoints.Position, ...
    mobiles.Position, ...
    'AccessPointGains', accesspoints.Gain, ...
    'AccessPointChannels', accesspoints.Channel, ...
    'TransmissionGain', transmissiongains, ...
    'FigureHandle', fig, ...
    'Quiet', false, ...
    'MobileGains', mobiles.Gain, ...
    'NumContourMapSamples', 20, ...
    'ReflectionArity', 0);
