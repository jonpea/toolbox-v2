%clear
function embreemexprofiling(plotting)

if nargin < 1 || isempty(plotting)
    plotting = false;
end

%% Important note
% NB: Use of the median as opposed to e.g. the mean of vertex coordinates
% for ray origins result in many intersections at facet boundaries. This is
% because the median be identically equal to vertex coordinates and because
% the scene is an extrusion of a planar model. Generically, a small
% perturbation to ray origin positions will destroy most of these
% "spurious" intersections, where Embree disagrees with complete
% enumeration.
perturb = @(a) a + 1e-5*(rand(size(a)) - 0.5);

numfloors = 3;
numrays = 150000;
studheight = 3.0;
structured = false;
scale = 2.0;

rng('default')

%% Geometric model
if structured
    faces = [
        1 2 3 4;
        1 2 6 5;
        2 3 7 6;
        3 4 8 7;
        4 1 5 8;
        5 6 7 8;
        ]; %#ok<UNRCH>
    
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
else
    [model.Faces, model.Vertices] = engineeringtower8data3dnew;
    offsets = studheight*(0 : numfloors - 1);
    stack = facevertextranslate(model, offsets(:)*[0 0 1]);
    faces = stack.Faces;
    vertices = stack.Vertices;
    vertices(abs(vertices) < 1e-12) = 0; % threshold on miniscule values
end

%%
if plotting
    figure(1), clf, hold on
    patch('Faces', faces, 'Vertices', vertices, 'FaceAlpha', 0.05)
    axis equal
    axis tight
    %labelpoints(vertices, (0 : size(vertices, 1) - 1)')
    %labelfacets(faces, vertices)
    xlabel('x')
    ylabel('y')
    zlabel('z')
    view(3)
    rotate3d on
end

%% Rays
gen = @(a, b, n) a + (1 : n)*(b - a)/(n + 1);
azimuth = gen(0, 2*pi, ceil(sqrt(numrays)));
inclination = gen(0, pi, floor(sqrt(numrays)));
[azimuth, inclination] = ndgrid(azimuth, inclination);
direction = sphericaltocartesian(azimuth, inclination, 1.0);
%direction = repmat([0 0 -1], numrays, 1);
numraysnew = size(direction, 1);
% NB: "median" (cf. "mean" produces interesting results)
origin = repmat(median(vertices, 1) + [-1, 2, 0], numraysnew, 1);
origin = perturb(origin);
%origin = origin - [0 0 -2];

if plotting
    plotvectors(origin, direction, scale, 'b')
    plotpoints(origin, 'r*')
    % labelfacets(faces, vertices, (0 : size(faces, 1) - 1)')
    % labelpoints(origin + scale*direction, (0 : numraysnew - 1)')
end

%%
fprintf('# faces: %u (%u storeys)\n', size(faces, 1),  numfloors)
fprintf(' # rays: %u\n', numraysnew)

%% Intersections via Embree
tembree = tic;
embree = embreescene(faces, vertices);
hitsembree = embree.Intersect(origin, direction, []);
elapsedembree = toc(tembree);
fprintf('  Embree: elapsed = %g sec (%u hits)\n', ...
    elapsedembree, numel(hitsembree.FaceIndex))
hitsembree = orderfields(hitsembree, { ...
    'RayIndex'
    'SegmentIndex'
    'FaceIndex'
    'Point'
    'RayParameter'
    'FaceCoordinates'
    });

%% Intersections via brute-force calculation
model = planarmultifacet(faces, vertices);
tcomplete = tic;
hitscomplete = model.Intersect(origin, direction, []);
elapsedcomplete = toc(tcomplete);

scene2 = completescene(faces, vertices);
tcomplete2 = tic;
hitscomplete2 = scene2.Intersect(origin, direction, []);
elapsedcomplete2 = toc(tcomplete2);

assert(isequal(sort(hitscomplete.RayIndex), sort(hitscomplete2.RayIndex)))
assert(isequal(sort(hitscomplete.FaceIndex), sort(hitscomplete2.FaceIndex)))

fprintf('Complete: elapsed = %g sec (%u hits)\n', ...
    elapsedcomplete, numel(hitscomplete.RayIndex))
hitscomplete = orderfields(hitscomplete, { ...
    'RayIndex'
    'SegmentIndex'
    'FaceIndex'
    'Point'
    'RayParameter'
    'FaceCoordinates'
    });
[~, permutation] = sortrows( ...
    [hitscomplete.RayIndex, hitscomplete.RayParameter]);
hitscomplete = tabularrows(hitscomplete, permutation);

fprintf('       m - embree = %g sec (%.4g times)\n', ...
    elapsedcomplete - elapsedembree, ...
    elapsedcomplete / elapsedembree)
fprintf('     mex - embree = %g sec (%.4g times)\n', ...
    elapsedcomplete2 - elapsedembree, ...
    elapsedcomplete2 / elapsedembree)

%%
if numraysnew <= 20
    disp('Complete: hits...')
    tabulardisp(hitscomplete)
    disp('Complete2: hits...')
    tabulardisp(hitscomplete2)
    disp('Embree: hits...')
    tabulardisp(hitsembree)
end

select = @(s) [s.RayIndex, s.FaceIndex];
[~, icomplete, iembree] = intersect( ...
    select(hitscomplete), select(hitsembree), 'rows');

compare( ...
    hitsembree.RayParameter(iembree, :), ...
    hitscomplete.RayParameter(icomplete, :))
compare( ...
    hitsembree.FaceCoordinates(iembree, :), ...
    hitscomplete.FaceCoordinates(icomplete, :))
compare( ...
    hitsembree.Point(iembree, :), ...
    hitscomplete.Point(icomplete, :))

extra = @(a, i) tabularrows(a, setdiff(1 : tabularsize(a), i));
extracomplete = extra(hitscomplete, icomplete);
extraembree = extra(hitsembree, iembree);

fprintf(' %u common hits\n', numel(icomplete))
fprintf('Complete: # extra hits = %u\n', tabularsize(extracomplete))
tabulardisp(extracomplete)
fprintf('  Embree: # extra hits = %u\n', tabularsize(extraembree))
tabulardisp(extraembree)

if plotting
    plotpoints(extracomplete.Point, 'ro')
    plotpoints(extraembree.Point, 'g*')
end

end

function compare(actual, expected)
tol = 1e-5;
mismatch = abs(actual - expected);
scale = abs(expected) + 1.0;
assert(all(mismatch(:)./scale(:) < tol));
end
