function [faces, vertices, types] = engineeringtower8data3dnew(varargin)

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
[wallfaces, doorfaces, vertices, types, doortypes2d] = ...
    data.engineeringtower8data2dnew(options.Convention);

import data.panel
archtypes(doortypes2d == panel.DoorInConcrete) = panel.ConcreteWall;
archtypes(doortypes2d == panel.DoorInGibCavity) = panel.GibWall;
archtypes(doortypes2d == panel.DoorToLift) = panel.ConcreteWall;

doortypes(doortypes2d == panel.DoorInConcrete) = panel.WoodenDoor;
doortypes(doortypes2d == panel.DoorInGibCavity) = panel.WoodenDoor;
doortypes(doortypes2d == panel.DoorToLift) = panel.SteelDoor;

floorheight = options.FloorHeight;
doorheight = floorheight + options.DoorHeight;
ceilingheight = floorheight + options.StudHeight;

% Extrude plan
model = facevertex.extrude(wallfaces, vertices, [floorheight, ceilingheight]);
if options.WithDoors
    doormodel = facevertex.extrude(doorfaces, vertices, [floorheight, doorheight]);
    archmodel = facevertex.extrude(doorfaces, vertices, [doorheight, ceilingheight]);
    model = facevertex.cat(model, doormodel, archmodel);
    types = [
        types(:);
        doortypes(:);
        archtypes(:);
        ];
end

if options.WithFloor
    %model = capfacevertex(model, true, false);
    floorface = facevertex.cap(@min, 3, model);
    model.Faces(end + 1, :) = floorface;
    types(end + 1, 1) = data.panel.Floor;
end

if options.WithCeiling
    %model = capfacevertex(model, false, true);
    ceilingface = facevertex.cap(@max, 3, model);
    model.Faces(end + 1, :) = ceilingface;
    types(end + 1, 1) = data.panel.Ceiling;
end

faces = model.Faces;
vertices = model.Vertices;
