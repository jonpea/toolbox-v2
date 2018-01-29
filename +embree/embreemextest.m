clear
%function embreemextest

%% Demonstration of MATLAB-Embree Mex interface
numfacets = 5;
numrays = 2;
labels = @(n) compose('%u', (0 : n - 1)');

%% Geometric model
lo = 0;
hi = 1;
verticesbase = [
    lo, lo, lo;
    hi, lo, lo;
    hi, hi, lo;
    lo, hi, lo;
    ];
facesbase = [ 0, 1, 2, 3 ] + 1;
faces = facesbase;
vertices = verticesbase;
for i = 1 : numfacets - 1
   vertices = vertcat(vertices, verticesbase + i*[0, 0, hi]); %#ok<AGROW>
   faces = vertcat(faces, facesbase + i*4); %#ok<AGROW>
end

%%
figure(1), clf, hold on
patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.1)
points.plot(vertices, 'o')
points.text(vertices, labels(size(vertices, 1)))
points.text(facevertex.reduce(@mean, faces, vertices), labels(size(faces, 1)))
xlabel('x')
ylabel('y')
zlabel('z')
axis equal
rotate3d on
view(3)

%% Rays
if true
    % This works beautifully
    origin = repmat([0.3 0.6 0.0], numrays, 1);
    origin(:, end) = -1.0 + 0.1*(0 : numrays - 1)';
    zmax = max(vertices(:, end)) - min(origin(:, end));
    direction = repmat([0, 0, zmax + 0.1], numrays, 1);
else
    % This doesn't work :(
    origin = repmat([0.3 0.6 0.0], numrays, 1);
    origin(:, end) = numfacets + 0.1*(0 : numrays - 1)';
    direction = repmat([0 0 -1], numrays, 1);
end
tnear = ones(size(origin, 1), 1);
tfar = inf(size(origin, 1), 1);
points.text(origin, labels(size(origin, 1)))
points.quiver(origin, direction, 0)

%% Intersections
scene = embree.Scene(faces, vertices);
tic
hits = scene.transmissions(origin, direction, []);
toc
disp(struct2table(hits))

points.plot(hits.Point, 'o')
