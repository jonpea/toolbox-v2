%% Tutorial on the representation of ray-scene intersection

%%
clear
fontsize = 8;
mm2m = @(x) x/1000; % converts "mm to m"
erase = @(handles) cellfun(@delete, handles);

%% Two dimensional model
xtick = mm2m(linspace(0, 3320, 2));
ytick = mm2m(linspace(0, 6510, 3));
[xgrid, ygrid] = meshgrid(xtick, ytick);
vertices = [xgrid(:), ygrid(:)];
faces = [1 2; 2 3; 4 5; 5 6; 1 4; 2 5; 3 6];
%%
scene = scenes.Scene(faces, vertices);
disp(scene)

%%
figure(1), clf, hold on
patch( ...
    'Faces', faces, ...
    'Vertices', vertices);
points.text(facevertex.reduce(@mean, faces, vertices), 'FontSize', fontsize)
points.text(vertices, 'FontSize', fontsize)
graphics.axislabels('x', 'y')
axis('equal')
view(2)

%%
% Orthogonal projection to a two dimensional surface
source = [
    2.0, 1.0;
    3.0, 2.0;
    ];
id = 6;
projected = scene.project(source, id);
oldhandles = {
    patch('Faces', faces(id, :), 'Vertices', vertices, 'EdgeColor', 'red');
    points.segments(source, projected, '-', 'ShowArrowHead', 'on');
    points.text(source);
    };

%%
mirrored = 2*projected - source;
norm(scene.mirror(source, id) - mirrored)

%%
% Ray-surface intersection in two dimensions
direction = [
    -1.0, -1.0;
    -0.1, 1.0;
    ];
interactions = scene.transmissions(source, direction, []);
%%
disp(struct2table(interactions))
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    points.text(source)
    points.quiver(source, direction);
    points.segments( ...
        source(interactions.RayIndex, :), ...
        interactions.Point, ...
        'ShowArrowHead', 'off');
    points.plot(interactions.Point, 'o');
    };

%%
sink = [
    1.0, 4.0;
    2.0, 5.0;
    ];

%%%
surfaces = [7 6];
[pairings, paths] = scene.reflections(source, sink, surfaces);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    points.plot(source, '.');
    points.plot(sink, '.');
    points.text(source);
    points.text(sink);
    points.plot(source(pairings, :), 's');
    points.plot(sink(pairings, :), 'x');
    points.paths(paths, 'Color', 'blue');
    };

%%
surfaces = [1 4 2 7 4];
[pairings, paths] = scene.reflections(source, sink, surfaces);
whos pairings paths
disp(pairings)
%%
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'EdgeColor', 'red');
    points.plot(source, '.');
    points.plot(sink, '.');
    points.text(source);
    points.text(sink);
    points.plot(source(pairings, :), 's');
    points.plot(sink(pairings, :), 'x');
    points.paths(paths, 'Color', 'blue');
    };

%% Three dimensional model
studheight = mm2m(3300);
extruded = facevertex.extrude(faces, vertices, [0.0, studheight]);
[faces, vertices]  = facevertex.fv([
    extruded.Faces;
    facevertex.cap(@min, 3, extruded);
    facevertex.cap(@max, 3, extruded);
    ], ...
    extruded.Vertices);

%%
scene = scenes.Scene(faces, vertices);

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
points.text(vertices, 'FontSize', fontsize, 'Color', 'red')
points.text(facevertex.reduce(@mean, faces, vertices), 'FontSize', fontsize, 'Color', 'blue')
graphics.axislabels('x', 'y', 'z')
axis('equal')
rotate3d('on')
view(120, 40)

%%
% Orthogonal projection to a two dimensional surface
source = [
    2.0, 1.0, 1.0;
    3.0, 2.0, 2.0;
    1.0, 4.0, 1.5;
    ];
id = 6;
projected = scene.project(source, id);
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(id, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    points.segments(source, projected, '-', 'ShowArrowHead', 'on');
    points.text(source);
    };

%%
mirrored = 2*projected - source;
norm(scene.mirror(source, id) - mirrored)

%%
% Ray-surface intersection in three dimensions
direction = [
    -1.0, -1.0, 0.5;
    -0.5, 1.0, -0.7;
    -1, -3, 1;
    ];
interactions = scene.transmissions(source, direction, []);
%%
disp(struct2table(interactions))
erase(oldhandles)
oldhandles = {
    patch( ...
        'Faces', faces(interactions.FaceIndex, :), ...
        'Vertices', vertices, ...
        'FaceColor', 'red', ...
        'FaceAlpha', 0.1);
    points.text(source)
    points.quiver(source, direction);
    points.segments( ...
        source(interactions.RayIndex, :), ...
        interactions.Point, ...
        'ShowArrowHead', 'off');
    points.plot(interactions.Point, 'o');
    };

%%
sink = [
    1.0, 4.0, 2.0;
    2.0, 5.0, 0.5;
    0.5, 5.0, 3.0;
    ];

%%%
surfaces = [7 6];
[pairings, paths] = scene.reflections(source, sink, surfaces);
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
    points.plot(source, '.');
    points.plot(sink, '.');
    points.text(source);
    points.text(sink);
    points.plot(source(pairings, :), 's');
    points.plot(sink(pairings, :), 'x');
    points.paths(paths, 'Color', 'blue');
    };

%%
surfaces = [1 4 2 7 4];
[pairings, paths] = scene.reflections(source, sink, surfaces);
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
    points.plot(source, '.');
    points.plot(sink, '.');
    points.text(source);
    points.text(sink);
    points.plot(source(pairings, :), 's');
    points.plot(sink(pairings, :), 'x');
    points.paths(paths, 'Color', 'blue');
    };