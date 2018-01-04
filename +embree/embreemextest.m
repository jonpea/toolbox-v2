clear
%function embreemextest

%% Demonstration of MATLAB-Embree Mex interface
numfacets = 3;
numrays = 2;
labels = @(n) (0 : n - 1)';

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
plotpoints(vertices, 'o')
labelpoints(vertices, labels(size(vertices, 1)))
labelfacets(faces, vertices, labels(size(faces, 1)))
xlabel('x')
ylabel('y')
zlabel('z')
axis equal
rotate3d on
view(3)

%% Rays
if false
    % This works beautifully
    origin = repmat([0.3 0.6 0.0], numrays, 1);
    origin(:, end) = -1.0 + 0.1*(0 : numrays - 1)';
    direction = repmat([0 0 1], numrays, 1);
else
    % This doesn't work :(
    origin = repmat([0.3 0.6 0.0], numrays, 1);
    origin(:, end) = numfacets + 0.1*(0 : numrays - 1)';
    direction = repmat([0 0 -1], numrays, 1);
end
tnear = ones(size(origin, 1), 1);
tfar = inf(size(origin, 1), 1);
labelpoints(origin, labels(size(origin, 1)))
plotvectors(origin, direction, 0)

%% Intersections
tic
intersections = embreeintersect( ...
    faces, vertices, origin, direction, tnear, tfar);
toc
tabulardisp(intersections)
