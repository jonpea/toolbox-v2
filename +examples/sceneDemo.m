function sceneDemo
%%SCENEDEMO Demonstrates 2-D and 3-D scene geometry and facet properties.

%%
newAxes = graphics.tabbedaxes(clf(figure(1), 'reset'));

%% An enumeration provides descriptive indices
dbtype +examples/panel.m

%% Scene geometry and material properties
import examples.panel
materialData = datatypes.cell2table({
    'Material'     'Gain'   'FaceAlpha'   'FaceColor'            'LineWidth'
    panel.Steel     -3       0.1           graphics.rgb.black     2
    panel.Wood      -3       0.1           graphics.rgb.salmon    2
    panel.Concrete  -20      0.1           graphics.rgb.red       5
    panel.Gib       -3       0.1           graphics.rgb.magenta   2
    panel.Glass     -3       0.1           graphics.rgb.cyan      2
    panel.Ceiling   -3       0.05          graphics.rgb.blue      1
    panel.Floor     -3       0.1           graphics.rgb.green     1
    });
materialData.EdgeColor = materialData.FaceColor;

%%
height.Floor = 0.0;
height.Door = 2.0;
height.Stud = 3.0;

faceData2D = datatypes.cell2table({
    'ID'  'VertexIndices'           'ZSpan'          'Material'
    1          [1 2]     [height.Floor height.Stud]  panel.Gib
    2          [2 3]     [height.Floor height.Stud]  panel.Concrete
    3          [4 5]     [height.Floor height.Stud]  panel.Gib
    4          [5 6]     [height.Floor height.Stud]  panel.Concrete
    5          [1 4]     [height.Floor height.Stud]  panel.Gib
    6          [3 6]     [height.Floor height.Stud]  panel.Concrete
    7          [2 7]     [height.Floor height.Stud]  panel.Concrete
    8          [5 8]     [height.Floor height.Stud]  panel.Concrete
    9          [7 8]     [height.Floor height.Door]  panel.Wood
    10         [7 8]     [height.Door  height.Stud]  panel.Glass
    });

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

%% View 2-D plan
scene2D = facevertex.fv(faceData2D.VertexIndices, vertices2D);
scene2D.Material = faceData2D.Material;

ax = newAxes('2-D Scene');
facevertex.multipatch(ax, ...
    scene2D.Material, materialData, ...
    'Faces', facevertex.faces(scene2D), ...
    'Vertices', facevertex.vertices(scene2D))
points.text(ax, facevertex.vertices(scene2D), 'Color', 'blue')
points.text(ax, facevertex.reduce(@mean, scene2D), 'Color', 'red')
axis(ax, points.bbox(facevertex.vertices(scene2D), 0.1))
axis(ax, 'equal')
title(ax, 'Note the duplicate vertices and lines')

%%
    function draw(scene, tabTitle, local)
        % Helper function to visualize an entire scene with labels
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

%% Generate 3-D model
[scene2DExtruded, facemap] = facevertex.extrude(scene2D, faceData2D.ZSpan);
scene2DExtruded.Material = scene2D.Material(facemap, :);

draw(scene2DExtruded, 'Extruded 2-D Scene')
title('Note the duplicate vertices')

%%
scene3D = facevertex.compress(scene2DExtruded);
scene3D.Material = scene2DExtruded.Material;

draw(scene3D, 'Compressed 3-D Scene')

%%
floorface = facevertex.cap(@min, 3, scene3D) %#ok<NOPRT>
scene3D.Faces(end + 1, :) = floorface;
scene3D.Material(end + 1, :) = panel.Floor;

ceilingface = facevertex.cap(@max, 3, scene3D) %#ok<NOPRT>
scene3D.Faces(end + 1, :) = ceilingface;
scene3D.Material(end + 1, :) = panel.Ceiling;

draw(scene3D, 'Capped 3-D Scene')

%%
quarterTurn = @(x, n) (x + [3, 0, 0])*elmat.rotor3([0 0 1], n*pi/2);
allBuildings = arrayfun( ...
    facevertex.clone(quarterTurn, scene3D), 0 : 3, ...
    'UniformOutput', false);
allBuildings = facevertex.cat(allBuildings{:});

draw(allBuildings, 'Multiblock')

%%
numFloors = 3;
elevate = @(x, level) x + level*[0, 0, height.Stud];
allFloors = arrayfun( ...
    facevertex.clone(elevate, scene3D), 0 : numFloors - 1, ...
    'UniformOutput', false);
allFloors = facevertex.cat(allFloors{:});

draw(allFloors, 'Multistorey')

end
