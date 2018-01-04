%function intersectiontest

clear
plotting = true;
uv = [0.75, 0.5];

lo = -1;
hi = +1;
vertices = [
    lo lo lo;
    hi lo lo;
    hi hi lo;
    lo hi lo;
    lo lo hi;
    hi lo hi;
    hi hi hi;
    lo hi hi;
    ];
faces = [
    4 3 2 1;
    1 2 6 5;
    2 3 7 6;
    3 4 8 7;
    4 1 5 8;
    5 6 7 8;
    ];

range = [0.2, 0.8];
weights = range(1) + rand(size(vertices, 1), 1)*diff(range);
weights = weights/sum(weights);
samples = repmat(fvsamples(faces, vertices, uv), 2, 1);
origins = repmat(sum(vertices.*weights, 1), size(samples, 1), 1);
directions = samples - origins;

tnear = 0;
tfar = inf;
[faceorigins, tangents] = fvtotangents(faces, vertices);
[~, offsettolocal, facenormals] = fvframes(faceorigins, tangents{:});

cscene = completescene(faces, vertices);
chits = cscene.intersect( ...
    origins, directions, tnear, tfar);
[~, permutation] = sortrows([chits.RayIndex, chits.FaceIndex]);
chits = tabularrows(chits, permutation);
tabulardisp(chits)

escene = embreescene(faces, vertices);
ehits = escene.intersect(origins, directions, tnear, tfar);
tabulardisp(ehits)
           
if plotting
    figure(1), clf, hold on
    patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.05)
    plotvectors(origins, directions, 0)
    plotvectors(fvcenters(faces, vertices), fvnormals(faces, vertices))
    plotpoints(samples, 'x')
    plotpoints(ehits.Point, '.')
    plotpoints(chits.Point, 's')
    axis equal
    axis tight
    labelpoints(vertices, (0 : size(vertices, 1) - 1)', 'Color', 'red')
    labelfacets(faces, vertices, 'Color', 'blue')
    xlabel('x')
    ylabel('y')
    zlabel('z')
    view(3)
    rotate3d on
end

numfaces = size(faces, 1);
numrays = size(origins, 1);
raysequence = (1 : numrays)';
facesequence = repmat((1 : numfaces)', 2, 1);
check = @(hits) ...
    cellfun(@feval, {
    @() assert(isequal(hits.RayIndex, raysequence));
    @() assert(isequal(hits.FaceIndex, facesequence));
    @() compare(hits.RayParameter, ones(numrays, 1));
    @() compare(hits.FaceCoordinates(:, 1), repmat(uv(1), numrays, 1));
    @() compare(hits.FaceCoordinates(:, 2), repmat(uv(2), numrays, 1));
    @() compare(hits.Point, samples);
    });

check(chits)
check(ehits)

% -------------------------------------------------------------------------
function compare(actual, expected, tol)
if nargin < 3 || isempty(tol)
    tol = 10*eps('single');
end
discrepancy = norm(actual - expected);
scale = norm(expected) + 1.0;
assert(discrepancy/scale < tol)
end
