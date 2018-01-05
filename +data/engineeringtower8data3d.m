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
model = extrudeplan(wallfaces, vertices, floorheight, ceilingheight);
if options.WithDoors
    doormodel = extrudeplan(doorfaces, vertices, doorheight, ceilingheight);
    model = catfacevertex(model, doormodel);
    types = vertcat(types(:), doortypes(:));
end

if options.WithFloor
    model = capfacevertex(model, true, false);
    types(end + 1, 1) = 3;
end
   
if options.WithCeiling
    model = capfacevertex(model, false, true);
    types(end + 1, 1) = 4;
end

faces = model.Faces;
vertices = model.Vertices;
