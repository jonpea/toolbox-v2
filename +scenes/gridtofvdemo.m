%function gridtofvdemo

%% Grid representation
%[x, y, z] = sphere(6);
[x, y, z] = peaks(6);

%%
configureaxes = @() suppress({
    view(gca, 45, 15);
    void(@() axis(gca, 'equal'));
    void(@() axis(gca, 'off'));
    });

%% Grid without elevation (2D)
[faces, vertices] = gridtofv(x, y);

figure(1), clf
subplot(1, 2, 1)
surf(x, y, zeros(size(x)))
configureaxes()

subplot(1, 2, 2)
patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.1)
labelpoints(vertices, 'Color', 'blue')
labelfacets(faces, vertices, 'Color', 'red')
configureaxes()

%% Grid with elevation (3D)
[faces, vertices] = gridtofv(x, y, z);

figure(2), clf
subplot(1, 2, 1)
surf(x, y, z)
configureaxes()
subplot(1, 2, 2)
patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.1)
labelpoints(vertices, 'Color', 'blue')
labelfacets(faces, vertices, 'Color', 'red')
configureaxes()

%% 3D grid
[x, y, z] = meshgrid(-2 : 1, 2 : 5, 6 : 8);
xyz = gridpoints(x, y, z);

configureaxes = @() suppress({
    view(gca, 45, 15);
    void(@() axis(gca, 'equal'));
    void(@() axis(gca, 'off'));
    });

figure(3), clf
subplot(1, 2, 1)
plotpoints(xyz, '.', 'MarkerSize', 15)
labelpoints(xyz)
configureaxes()

%%
for dim = {1, 2, 3, [1 2], [1 3], [2 3], [1 2 3]}
    [faces, vertices] = gridtofv(x, y, z, dim{:});
    %%
    clf
    patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.1)
    labelpoints(vertices, 'Color', 'blue')
    labelfacets(faces, vertices, 'Color', 'red')
    title(sprintf('slice %s', mat2str(dim{:})))
    configureaxes()
end
