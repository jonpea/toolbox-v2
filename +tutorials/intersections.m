%% Tutorial on the representation of ray-scene intersection

%%
clear
fontsize = 8;
mm2m = @(x) x/1000; % converts "mm to m"
erase = @(handles) cellfun(@delete, handles);

%% Two dimensional model
xtick = mm2m(linspace(0, 3320, 2));
ytick = mm2m(linspace(0, 6510, 3));
[vertices, x, y] = gridpoints(xtick, ytick);
faces = [1 2; 2 3; 4 5; 5 6; 1 4; 2 5; 3 6];
%%
scene = planarmultifacet(faces, vertices);
tabulardisp(scene)

%%
figure(1), clf, hold on
patch( ...
    'Faces', faces, ...
    'Vertices', vertices);
labelfacets(faces, vertices, 'FontSize', fontsize)
labelpoints(vertices, 'FontSize', fontsize)
labelaxes('x', 'y')
axis equal
view(2)

%%
% Orthogonal projection to a two dimensional surface
source = [
    2.0, 1.0;
    3.0, 2.0;
    ];
id = 6;
projection = scene.Project(source, id);
oldhandles = {
    patch('Faces', faces(id, :), 'Vertices', vertices, 'EdgeColor', 'red');
    plotsegments(source, projection, '-', 'ShowArrowHead', 'on');
    labelpoints(source);
    };

%%
mirrored = 2*projection - source;
norm(scene.Mirror(source, id) - mirrored)

%%
% Ray-surface intersection in two dimensions
direction = [
    -1.0, -1.0;
    -0.1, 1.0;
    ];
interactions = scene.IntersectScene(source, direction, 0.0, inf);
%%
tabulardisp(interactions)
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    labelpoints(source)
    plotvectors(source, direction);
    plotsegments( ...
        source(interactions.RayIndex, :), ...
        interactions.Point, ...
        'ShowArrowHead', 'off');
    plotpoints(interactions.Point, 'o');
    };

%%
sink = [
    1.0, 4.0;
    2.0, 5.0;
    ];

%%%
surfaces = [7 6];
[pairings, paths] = imagemethod( ...
    scene.IntersectFacet, scene.Mirror, surfaces, source, sink);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    plotpoints(source, '.');
    plotpoints(sink, '.');
    labelpoints(source);
    labelpoints(sink);
    plotpoints(source(pairings, :), 's');
    plotpoints(sink(pairings, :), 'x');
    plotpaths(paths, 'Color', 'blue');
    };

%%
surfaces = [1 4 2 7 4];
[pairings, paths] = imagemethod( ...
    scene.IntersectFacet, scene.Mirror, surfaces, source, sink);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    plotpoints(source, '.');
    plotpoints(sink, '.');
    labelpoints(source);
    labelpoints(sink);
    plotpoints(source(pairings, :), 's');
    plotpoints(sink(pairings, :), 'x');
    plotpaths(paths, 'Color', 'blue');
    };

%% Three dimensional model
floor = true;
ceiling = true;
studheight = mm2m(3300);
[faces, vertices] = capfacevertex( ...
    extrudeplan(faces, vertices, 0.0, studheight), ...
    floor, ceiling);
%%
scene = planarmultifacet(faces, vertices);
tabulardisp(scene)

%%
figure(1), clf, hold on
patch( ...
    'Faces', faces(1 : end - 2, :), ... % extruded (vertical) surfaces
    'Vertices', vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
patch( ...
    'Faces', faces(end - 1 : end, :), ... % surfaces of floor & ceiling
    'Vertices', vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'red');
labelpoints(vertices, 'FontSize', fontsize, 'Color', 'red')
labelfacets(faces, vertices, 'FontSize', fontsize, 'Color', 'blue')
labelaxes('x', 'y', 'z')
axis equal
rotate3d on
view(120, 40)

%%
% Orthogonal projection to a two dimensional surface
source = [
    2.0, 1.0, 1.0;
    3.0, 2.0, 2.0;
    1.0, 4.0, 1.5;
    ];
id = 6;
projection = scene.Project(source, id);
oldhandles = {
    patch( ...
        'Faces', faces(id, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    plotsegments(source, projection, '-', 'ShowArrowHead', 'on');
    labelpoints(source);
    };

%%
mirrored = 2*projection - source;
norm(scene.Mirror(source, id) - mirrored)

%%
% Ray-surface intersection in three dimensions
direction = [
    -1.0, -1.0, 0.5;
    -0.5, 1.0, -0.7;
    -1, -3, 1;
    ];
interactions = scene.IntersectScene(source, direction, 0.0, inf);
%%
tabulardisp(interactions)
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    labelpoints(source)
    plotvectors(source, direction);
    plotsegments( ...
        source(interactions.RayIndex, :), ...
        interactions.Point, ...
        'ShowArrowHead', 'off');
    plotpoints(interactions.Point, 'o');
    };

%%
sink = [
    1.0, 4.0, 2.0;
    2.0, 5.0, 0.5;
    0.5, 5.0, 3.0;
    ];

%%%
surfaces = [7 6];
[pairings, paths] = imagemethod( ...
    scene.IntersectFacet, scene.Mirror, surfaces, source, sink);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    plotpoints(source, '.');
    plotpoints(sink, '.');
    labelpoints(source);
    labelpoints(sink);
    plotpoints(source(pairings, :), 's');
    plotpoints(sink(pairings, :), 'x');
    plotpaths(paths, 'Color', 'blue');
    };

%%
surfaces = [1 4 2 7 4];
[pairings, paths] = imagemethod( ...
    scene.IntersectFacet, scene.Mirror, surfaces, source, sink);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    plotpoints(source, '.');
    plotpoints(sink, '.');
    labelpoints(source);
    labelpoints(sink);
    plotpoints(source(pairings, :), 's');
    plotpoints(sink(pairings, :), 'x');
    plotpaths(paths, 'Color', 'blue');
    };