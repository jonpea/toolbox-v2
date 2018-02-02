%% Demonstration of scene geometry and facet properties.

%% Overview
% This script is part of our wireless sytems / ray-tracing toolbox.
% It demonstrates:
%
% * Representation of 2-D and 3-D scene geometry.
% * Association of material properties and graphical attributes with scene facets.
% * Visualization of scene geometry and material properties.
% * Creation of a non-trivial 3-D scene via extrusion of a 2-D plan.
% * Creation of complex 3-D scenes via transformation and combination.
%
% Key toolbox functions employed in this script are distinguishable from
% MATLAB's standard library functions by the presence of
% <https://www.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html
% |package|> names e.g. the package names in |datatypes.cell2table|,
% |facevertex.multipatch|, and |graphics.tabbedaxes| are |datatypes|,
% |facevertex|, and |graphics|, respectively.
%

%% Prepare workspace and figure
clear % workspace
newAxes = graphics.tabbedaxes(clf(figure(1), 'reset')); % tabbed figure

%% Enumerations in MATLAB
% In the interest of readability, we use an
% <https://www.mathworks.com/help/matlab/matlab_oop/enumerations.html
% |enumeration|> to associate indices with descriptive names.
dbtype +examples/Materials.m

%% Scene geometry and material properties
% Here, we associate data with each of the materials labelled in the
% enumeration. Note that columns
% <https://www.mathworks.com/help/matlab/ref/matlab.graphics.primitive.patch-properties.html#property_d119e751541
% |FaceAlpha|>,
% <https://www.mathworks.com/help/matlab/ref/matlab.graphics.primitive.patch-properties.html#property_d119e751338
% |FaceColor|>,
% <https://www.mathworks.com/help/matlab/ref/matlab.graphics.primitive.patch-properties.html#property_d119e752162
% |LineWidth|>, and
% <https://www.mathworks.com/help/matlab/ref/matlab.graphics.primitive.patch-properties.html#property_d119e751734
% |EdgeColor|> are valid
% <https://www.mathworks.com/help/matlab/ref/matlab.graphics.primitive.patch-properties.html
% patch properties>, compatible with
% <https://www.mathworks.com/help/matlab/ref/patch.html |patch|>; they are
% detected- and applied in |facevertex.multpatch|, below. In contrast,
% |Gain| is meaningful only to the user; an arbitrary number of such
% custom/patch fields may be specified.
%
% By default, the first line of the cell array passed to
% |datatypes.cell2table| contains column names. In our context, this
% is more convenient than the interface provided by the standard version of
% <https://www.mathworks.com/help/matlab/ref/cell2table.html |cell2table|>.
import examples.Materials
materialData = datatypes.cell2table({
    'Material'         'Gain'  'FaceAlpha'      'FaceColor'         'LineWidth'
    Materials.Steel     -3       0.1           graphics.rgb.black     2
    Materials.Wood      -3       0.1           graphics.rgb.salmon    2
    Materials.Concrete  -20      0.1           graphics.rgb.red       5
    Materials.Gib       -3       0.1           graphics.rgb.magenta   2
    Materials.Glass     -3       0.1           graphics.rgb.cyan      2
    Materials.Ceiling   -3       0.05          graphics.rgb.blue      1
    Materials.Floor     -3       0.1           graphics.rgb.green     1
    });
materialData.EdgeColor = materialData.FaceColor; % additional column

%%
% Each line ("facet"), defined by a vertex pair (|VertexIndices|), in our
% scene is associated with a material type (|Material|) and a pair of
% heights that specify how it will be extruded in the associated 3-D model.
height.Floor = 0.0;
height.Door = 2.0;
height.Ceiling = 3.0; % "ceiling"

faceData2D = datatypes.cell2table({
    'ID'  'VertexIndices'  'Material'               'ZSpan'
    1          [1 2]       Materials.Gib       [height.Floor height.Ceiling]
    2          [2 3]       Materials.Concrete  [height.Floor height.Ceiling]
    3          [4 5]       Materials.Gib       [height.Floor height.Ceiling]
    4          [5 6]       Materials.Concrete  [height.Floor height.Ceiling]
    5          [1 4]       Materials.Gib       [height.Floor height.Ceiling]
    6          [3 6]       Materials.Concrete  [height.Floor height.Ceiling]
    7          [2 7]       Materials.Concrete  [height.Floor height.Ceiling]
    8          [5 8]       Materials.Concrete  [height.Floor height.Ceiling]
    9          [7 8]       Materials.Wood      [height.Floor height.Door]
    10         [7 8]       Materials.Glass     [height.Door  height.Ceiling]
    });

%%
% Finally, these vertex coordinates combine with the |VertexIndices| field
% to define 2-D plan geometry.
vertices2D = [
    0.0,  0.0
    0.0,  2.0
    0.0,  4.0
    3.0,  0.0
    3.0,  2.0
    3.0,  4.0
    1.0,  2.0
    2.0,  2.0
    ];

%%
% |facevertex.fv| simply packs its arguments into a struct; we augment the
% geometry with a |Material| type for each facet.
scene2D = facevertex.fv(faceData2D.VertexIndices, vertices2D);
scene2D.Material = faceData2D.Material;

%% Visualization of a 2-D plan
% |facevertex.multipatch| uses the face-material map |scene2D.Material|
% with the properties tabulated in |materialData| to specify
% face/line colors and thicknesses etc.
% This is easier than making a sequence of calls to
% <https://www.mathworks.com/help/matlab/ref/patch.html |patch|>.
%
% *NB*: The duplicate lines and vertices are associated with
% overlapping 2-D projections of distinct 3-D facets, as we will see next.
ax = newAxes('2-D Scene');
facevertex.multipatch(ax, ...
    scene2D.Material, materialData, ...
    'Faces', facevertex.faces(scene2D), ...
    'Vertices', facevertex.vertices(scene2D))
points.text(ax, facevertex.vertices(scene2D), 'Color', 'blue')
points.text(ax, facevertex.reduce(@mean, scene2D), 'Color', 'red')
axis(ax, points.bbox(facevertex.vertices(scene2D), 0.1)) % "bounding box, 10% margin"
axis(ax, 'equal')
title(ax, 'Note the duplicate vertices and lines')

%% Generate 3-D model by extrusion
[scene2DExtruded, facemap] = facevertex.extrude(scene2D, faceData2D.ZSpan);
scene2DExtruded.Material = scene2D.Material(facemap, :);

%% Visualization of a 3-D plan
% See the definition, at the bottom of this file, of helper function
% |drawScene|, which is reused for all 3-D visualizations in this script.
% Naturally, its code looks very similar to that for 2-D visualizations.
drawScene(newAxes, materialData, scene2DExtruded, 'Extruded 2-D Scene')
title('Note the duplicate vertices')

%% Scene compression
% Here, we eliminate duplicate vertices that arise in the extrusion
% process, wherein vertices at the top of one facet may coincide with those
% at the bottom of another (independently extruded) facet.
%
% Compression is not performed by default (inside |facevertex.extrude|) so
% that the number of extruded vertices in the initial 3-D model is more
% easily predictable by users.
scene3D = facevertex.compress(scene2DExtruded);
scene3D.Material = scene2DExtruded.Material;
%%
drawScene(newAxes, materialData, scene3D, 'Compressed 3-D Scene')

%% Add facets for floor and ceiling
% Here, |facevertex.cap| returns a face-vertex list for a "cap" at the specified
% extreme (<https://www.mathworks.com/help/matlab/ref/min.html |min|>,
% <https://www.mathworks.com/help/matlab/ref/max.html |max|>) in the 3rd
% direction ("z-direction", second argument).
%
% Notes:
%
% * The user has full control over how the new facet is indexed in the
% scene, and how material properties are updated.
% * |facevertex.cap| only attempts to "cap" a scene using an _axis-aligned_
% _quadrilateral_, irrespective of the types of polygons that comprise
% the rest of the scene (even though heterogeneous scenes are supported).
% * All vertices in the cap must already exist in the scene; the user may
% need to add additional vertices specifically for a capping facet.
%
floorface = facevertex.cap(@min, 3, scene3D) %#ok<NOPTS>
scene3D.Faces(end + 1, :) = floorface;
scene3D.Material(end + 1, :) = Materials.Floor;
%%
ceilingface = facevertex.cap(@max, 3, scene3D) %#ok<NOPTS>
scene3D.Faces(end + 1, :) = ceilingface;
scene3D.Material(end + 1, :) = Materials.Ceiling;
%%
drawScene(newAxes, materialData, scene3D, 'Capped 3-D Scene')

%% Scene transformation & composition (I)
% A (sensible) transformation applied to the vertix coordinates effect the
% transformation on the entire scene. Here, we demonstrate "quarter turn"
% transformations of the original 3-D scene.
%
% * The first argument of |quarterTurn| refers to the vertex coordinates of
% the original scene. Zero- or more subsequent arguments refer to an
% arbitrary set of transformation parameters; in this case, |n| refers to
% the number of quarter turns.
% * |facevertex.clone| consumes the first argument, while
% <https://www.mathworks.com/help/matlab/ref/arrayfun.html |arrayfun|>
% threads the remaining slot.
% * Use of |arrayfun| is natural here, but not mandatory.
%
% Generalization to more complicated transformations is hopefully clear.
quarterTurn = @(x, n) (x + [3, 0, 0])*elmat.rotor3([0 0 1], n*pi/2);
allBuildings = arrayfun( ...
    facevertex.clone(quarterTurn, scene3D), 0 : 3, ...
    'UniformOutput', false);
%%
% The transformed copies of the original scene are joined into a single
% macro-scene.
allBuildings = facevertex.cat(allBuildings{:});
%%
drawScene(newAxes, materialData, allBuildings, 'Multiblock')

%% Scene transformation & composition (II)
% Similar to the preceding example, transformed copies of the original
% scene are joined to form a single multi-story building.
numFloors = 3;
elevate = @(x, level) x + level*[0, 0, height.Ceiling];
allFloors = arrayfun( ...
    facevertex.clone(elevate, scene3D), 0 : numFloors - 1, ...
    'UniformOutput', false);
allFloors = facevertex.cat(allFloors{:});
%%
drawScene(newAxes, materialData, allFloors, 'Multistorey')
drawnow
%%
% Naturally, examples (I) and (II) could be combined to produce a
% multiblock-multistorey complex.

%% 

%% 
% Thank you!

%% Appendix: Definition of |drawScene|
% This helper is used to visualize all 3-D scenes in the script,
% eliminating unnecessary code duplication.
function drawScene(newAxes, materialData, scene, tabTitle, local)
import facevertex.faces
import facevertex.vertices
local.ax = newAxes(tabTitle);
hold(local.ax, 'on')
grid(local.ax, 'on')
facevertex.multipatch(local.ax, ...
    scene.Material, materialData, ...% 2D & 3D are currently identical
    'Faces', faces(scene), ...
    'Vertices', vertices(scene))
points.plot(local.ax, vertices(scene), '.', 'MarkerSize', 15)
points.text(local.ax, vertices(scene), 'Color', 'black')
points.text(local.ax, facevertex.reduce(@mean, scene), 'Color', 'red')
graphics.axislabels('x', 'y', 'z')
axis(local.ax, points.bbox(vertices(scene), 0.1))
axis(local.ax, 'equal')
view(local.ax, 3)
end
