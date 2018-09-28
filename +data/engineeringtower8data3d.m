function [faces, vertices, types] = engineeringtower8data3d(varargin)

narginchk(0, nargin)

parser = inputParser;
parser.addParameter('DoorHeight', 2.5, @(h) isscalar(h) && isnumeric(h))
parser.addParameter('FloorHeight', 0.0, @(h) isscalar(h) && isnumeric(h))
parser.addParameter('StudHeight', 3.0, @(h) isscalar(h) && isnumeric(h))
parser.addParameter('WithDoors', true, @(b) isscalar(b) && islogical(b))
parser.addParameter('WithFloor', false, @(b) isscalar(b) && islogical(b))
parser.addParameter('WithCeiling', false, @(b) isscalar(b) && islogical(b))
parser.addParameter('Convention', 'pais', @ischar)
parser.parse(varargin{:})
options = parser.Results;

assert(options.DoorHeight <= options.StudHeight)

% 2D plan and attributes
[wallfaces, doorfaces, vertices, types, doortypes] = ...
    engineeringtower8data2d(options.Convention);

floorheight = options.FloorHeight;
doorheight = floorheight + options.DoorHeight;
ceilingheight = floorheight + options.StudHeight;

% Extrude plan
model = facevertex.extrude(wallfaces, vertices, [floorheight, ceilingheight]);
if options.WithDoors
    doormodel = facevertex.extrude(doorfaces, vertices, [doorheight, ceilingheight]);
    model = facevertex.cat(model, doormodel);
    types = vertcat(types(:), doortypes(:));
end

if options.WithFloor
    model.Faces(end + 1, :) = facevertex.cap(@min, 3, model.Vertices);
    types(end + 1, 1) = 3;
end
   
if options.WithCeiling
    model.Faces(end + 1, :) = facevertex.cap(@max, 3, model.Vertices);
    types(end + 1, 1) = 4;
end

faces = model.Faces;
vertices = model.Vertices;

% -------------------------------------------------------------------------
function varargout = engineeringtower8data2d(convention)

narginchk(0, 1)
if nargin < 1 || isempty(convention)
    convention = 'neve';
end
assert(ischar(convention))

% Specify source plan
[wallfaces, vertices, wallgains] = data.engineeringtower8data;

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

% Doors in concrete service core
doorsincore = [8, 10, 11, 13];

% All other doors
otherdoors = setdiff(1 : size(doorfaces, 1), doorsincore);

% Use negative gain to sort with increasing attenuation
[uniquevalues, ~, walltypes] = unique(-wallgains);
assert(numel(uniquevalues) == 2, ...
    'Expected only two distinct gain values in dataset')

% Material types
doortypes = zeros(size(doorfaces, 1), 1);
doortypes(otherdoors) = 1;
doortypes(doorsincore) = 2;

% Coordinate transformation
switch validatestring(convention, {'butterworth', 'neve', 'pais', 'wyfy'})
    case {'butterworth', 'neve', 'wyfy'}
        offset = 0;
        rotor = 1;
    case 'pais'
        offset = max(vertices(:, 1 : 2), [], 1);
        rotor = elmat.rotor2(pi); 
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
