%function embreetest
clear

import embree.embreescene

%% Demonstration of MATLAB-Embree Mex interface
numfacets = 5;
numrays = 2;
labels = @(n) compose('%u', 0 : n - 1);
mask = []; % 2 : 2 : numfacets;
uv = [0.5 0.5];

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
origin = repmat([uv, 0.0], numrays, 1);
origin(:, end) = -1.0 + 0.1*(0 : numrays - 1)';
direction = repmat([0, 0, 1]*(max(vertices(:, end)) + 1), numrays, 1);
points.text(origin, labels(size(origin, 1)))
points.quiver(origin, direction, 0)

%% Intersections
tic
embree = embree.embreescene(faces, vertices);
hits = embree.intersectpaths(origin, direction, mask);
disp(hits)
toc

fprintf('Detected %u hits\n', datatypes.struct.tabular.height(hits))
[~, permutation] = sort(hits.RayIndex);
disp(struct2table(datatypes.struct.tabular.rows(hits, permutation)))

return
