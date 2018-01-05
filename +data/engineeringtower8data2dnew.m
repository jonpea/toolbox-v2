function varargout = engineeringtower8data2dnew(convention, fig)

narginchk(0, 2)
if nargin < 1 || isempty(convention)
    convention = 'neve';
end
if nargin < 2
    fig = []; % default to no plot
end
assert(ischar(convention))

% Specify source plan
[wallfaces, vertices, walltypes] = engineeringtower8data;

% Additional vertices for doors
vertices = [
    vertices;
    4.4  4.2;
    12.5 11.1;
    14.3 14.3;
    ];

% Doors
doorfaces = [
    9 74;
    11 12;
    12 13;
    17 21;
    18 19;
    21 29;
    28 33;
    32 40;
    38 41;
    39 43;
    42 45;
    44 49;
    48 75;
    50 54;
    57 58;
    60 61;
    65 66;
    63 76;
    ];


% Materials of walls in which each door is installed
doorsincore = 10; % excluding 13, which is in gib cavity
doorstolift = [8, 11];
doortypes = repmat(panel.DoorInGibCavity, size(doorfaces(:, 1)));
doortypes(doorsincore) = panel.DoorInConcrete;
doortypes(doorstolift) = panel.DoorToLift;

% Coordinate transformation
switch validatestring(convention, {'butterworth', 'neve', 'pais', 'wyfy'})
    case {'butterworth', 'neve', 'wyfy'}
        offset = 0;
        rotor = 1;
    case 'pais'
        offset = max(vertices(:, 1 : 2), [], 1);
        rotor = rotor2d(pi);
end
vertices = vertices*rotor + offset;

if nargout <= 3
    varargout = {
        [wallfaces; doorfaces]
        vertices
        [walltypes; doortypes]
        };
else
    varargout = {
        wallfaces, doorfaces, ...
        vertices, ...
        walltypes, doortypes
        };
end


    function draw(faces, types, type, color, width)
        mask = types == type;
        patch( ...
            'Faces', faces(mask, :), ...
            'Vertices', vertices, ...
            'FaceAlpha', 0.1, ...
            'FaceColor', color, ...
            'EdgeColor', color, ...
            'LineWidth', width)
        labelfacets(faces(mask, :), vertices, 'Color', color)
    end

    function drawwalls(varargin)
        draw(wallfaces, walltypes, varargin{:})
    end

    function drawdoors(varargin)
        draw(doorfaces, doortypes, varargin{:})
    end

if ~isempty(fig)
    figure(fig), axis off
    labels = (1 : size(wallfaces, 1))';
    clf, hold on
    %labelpoints(vertices)
    % Walls
    drawwalls(panel.GibWall, 'magenta', 1)
    drawwalls(panel.ConcreteWall, 'red', 1)
    drawwalls(panel.GlassWindow, 'cyan', 1)
    % Doors
    drawdoors(panel.DoorInConcrete, 'green', 3)
    drawdoors(panel.DoorInGibCavity, 'black', 3)
    drawdoors(panel.DoorToLift, 'blue', 3)
    axis('equal')
    axis('tight')
    camproj('perspective')
    rotate3d('on')
    drawwalls(panel.Floor, 'green', 1)
    drawwalls(panel.Ceiling, 'blue', 1)
end

end

% =========================================================================
function [faces, vertices, gains] = engineeringtower8data

% glass = -3;
% gain_concrete = -20;
% gain_wall = -3;
glass = double(panel.GlassWindow);
concrete = double(panel.ConcreteWall);
gib = double(panel.GibWall);

header = { 'x1', 'y1', 'x2', 'y2', 'gain' }; %#ok<*NASGU>
data = num2cell([
    1          0          0    18.5000          0    glass
    2    18.5000          0    18.5000    18.5000    glass
    3    18.5000    18.5000          0    18.5000    glass
    4          0    18.5000          0          0    glass
    5          6          6     7.4000          6    concrete
    6     8.4000          6     9.2000          6    concrete
    7    10.6000          6    12.5000          6    concrete
    8    12.5000          6    12.5000    12.5000    concrete
    9    12.5000    12.5000     9.4000    12.5000    concrete
    10     8.3000    12.5000          6    12.5000    concrete
    11          6    12.5000          6          6    concrete
    12          6     8.2000    12.5000     8.2000    concrete
    13          6    11.1000    11.1000    11.1000    gib
    14          8     8.2000          8    11.1000    gib
    15     4.4000          0     4.4000          3    gib
    16     4.4000          3          6          3    gib
    17          6          3          6     4.2000    gib
    18     7.4000          0     7.4000     4.2000    gib
    19          7     4.2000    10.6000     4.2000    gib
    20    14.9000          0    14.9000     3.2000    gib
    21    11.6000     4.2000    14.9000     4.2000    gib
    22    14.3000     4.2000    14.3000     6.3000    gib
    23    14.3000     5.3000    18.5000     5.3000    gib
    24    14.3000     7.3000    14.3000    11.3000    gib
    25    14.3000     9.2000    18.5000     9.2000    gib
    26    14.3000    12.2000    14.3000    13.2000    gib
    27    14.3000         13    18.5000         13    gib
    28    12.7000    14.3000    15.5000    14.3000    gib
    29    15.5000    14.3000    15.5000    18.5000    gib
    30     9.1000    14.3000    11.8000    14.3000    gib
    31         11    14.3000         11    18.5000    gib
    32     7.7000    14.3000     8.2000    14.3000    gib
    33          8    14.3000          8    18.5000    gib
    34     5.7000    14.3000     6.8000    14.3000    gib
    35          6    14.3000          6    15.9000    gib
    36          6    15.9000     4.4000    15.9000    gib
    37     4.4000    15.9000     4.4000    18.5000    gib
    38          0    14.3000     4.8000    14.3000    gib
    39     4.4000    14.3000     4.4000    12.3000    gib
    40          0    11.1000     4.4000    11.1000    gib
    41          0     7.4000     4.4000     7.4000    gib
    42     4.4000     9.9000     4.4000     5.4000    gib
    43          0     4.2000     4.7000     4.2000    gib
    ], 1);

[faces, vertices] = linestofacevertex(data{2 : 5});
gains = panel(data{end});

end
