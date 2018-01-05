%% Demonstration of the image method

%%
clear
import embree.embreescene
import facevertex.gridplan
import points.text
import rayoptics.imagemethod
import scene.completescene

%%
scenefactory = @embreescene;
% scenefactory = @completescene;

%%
numsegments = 6;
numpairs = 4;
vspace = @(x, n) [x, 0] + linspace(-0.4, 0.4, numpairs)'*[0, 1];
sourcepoints = vspace(0.0);
sinkpoints = vspace(numsegments);

[faces, vertices] = gridplan(0 : numsegments, 0.5*[-1, 1]);

%%
ax = axes(figure(1));
clf(ax, 'reset')
hold(ax, 'on')
axis(ax, 'equal'), axis(ax, 'off')
patch(ax, 'Faces', faces, 'Vertices', vertices);
points.text(ax, vertices, 'Color', 'blue')
points.text(ax, facevertex.reduce(@mean, faces, vertices), 'Color', 'red')
points.plot(ax, sourcepoints, 'rs')
points.plot(ax, sinkpoints, 'ro')

%%
numfaces = size(faces, 1);
top = numfaces;
bottom = numfaces - 1;
faceindices = zeros(1, numsegments);
faceindices(1 : 2 : end) = top;
faceindices(2 : 2 : end) = bottom;

scene = scenefactory(faces, vertices);
[pairindices, pathpoints] = imagemethod( ...
    scene.IntersectFacet, ...
    scene.Mirror, ...
    faceindices, ...
    sourcepoints, ...
    sinkpoints);

%%
arrayfun( ...
    @(i) points.plot(ax, stack(pathpoints(i, :, :)), '-'), ...
    1 : size(pathpoints, 1), ...
    'UniformOutput', false)

assert(numel(pairindices) == size(sourcepoints, 1))

% -------------------------------------------------------------------------
function x = stack(x)
%STACK Stacks the layers of a 3D array.
% STACK(CAT(3,A,B,C,...)) returns [A; B; C; ...] if A, B, C are matrices.
numcolumns = size(x, 2);
x = permute(x, [1 3 2]);
x = reshape(x, [], numcolumns);
end
