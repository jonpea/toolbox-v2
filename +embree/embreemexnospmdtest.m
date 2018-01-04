function embreemexnospmdtest(varargin)

parser = inputParser;
parser.addParameter('NumRays', 5, @isscalar)
parser.addParameter('NumReps', 1, @isscalar)
parser.addParameter('Plotting', false, @isscalar)
parser.addParameter('Reports', false, @isscalar)
parser.addParameter('Scale', 2.0, @isscalar)
parser.addParameter('NumHitsToShow', 5, @isscalar)
parser.parse(varargin{:})
options = parser.Results;

rng(0)

%% Important note
% NB: Use of the median as opposed to e.g. the mean of vertex coordinates
% for ray origins result in many intersections at facet boundaries. This is
% because the median be identically equal to vertex coordinates and because
% the scene is an extrusion of a planar model. Generically, a small
% perturbation to ray origin positions will destroy most of these
% "spurious" intersections, where Embree disagrees with complete
% enumeration.
perturb = @(a) a + 1e-1*(rand(size(a)) - 0.5);

rng('default')

%% Geometric model
faces = [
    1 2 3 4;
    1 2 6 5;
    2 3 7 6;
    3 4 8 7;
    4 1 5 8;
    5 6 7 8;
    ];
faces = faces(randperm(size(faces, 1)), :);
faces = repmat(faces, options.NumReps, 1);


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

%%
if options.Plotting
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
azimuth = gen(0, 2*pi, ceil(sqrt(options.NumRays)));
inclination = gen(0, pi, floor(sqrt(options.NumRays)));
[azimuth, inclination] = ndgrid(azimuth, inclination);
direction = options.Scale*unit(sphericaltocartesian(azimuth, inclination, 1.0), 2);
numraysnew = size(direction, 1);
origin = repmat(median(vertices, 1), numraysnew, 1);
origin = perturb(origin);

origin = zeros(size(faces, 1), 3) + repmat(0.4, 1, 3);
target = squeeze(mean( ...
    reshape( ...
    vertices(faces', :), ...
    size(faces, 2), size(faces, 1), []), ...
    1));
direction = (target - origin).*((1 : size(origin, 1))' + 1);

if options.Plotting
    plotvectors(origin, direction, 0.0, 'b')
    plotpoints(origin, 'r*')
end

%%
fprintf('# faces: %u\n', size(faces, 1))
fprintf(' # rays: %u\n', numraysnew)

%% Intersections via Embree
tembree = tic;
embree = embreescene(faces, vertices);
hitsembree = embree.intersect(origin, direction);
elapsedembree = toc(tembree);
fprintf('  Embree: elapsed = %g sec (%u hits)\n', ...
    elapsedembree, numel(hitsembree.FaceIndex))
hitsembree = orderfields(hitsembree, { ...
    'RayIndex' ...
    'FaceIndex' ...
    'RayParameter' ...
    'FaceCoordinates' ...
    'Point'
    });

%% Intersections via brute-force calculation
model = planarmultifacet(faces, vertices);
tcomplete = tic;
hitscomplete = model.IntersectScene(origin, direction);
elapsedcomplete = toc(tcomplete);
fprintf('Complete: elapsed = %g sec (%u hits)\n', ...
    elapsedcomplete, numel(hitscomplete.RayIndex))
hitscomplete = orderfields(hitscomplete, { ...
    'RayIndex'
    'FaceIndex'
    'RayParameter'
    'FaceCoordinates'
    'Point'
    });
[~, permutation] = sortrows( ...
    [hitscomplete.RayIndex, hitscomplete.RayParameter]);
hitscomplete = tabularrows(hitscomplete, permutation);

fprintf('speed-up = %g sec (%.3g times)\n', ...
    elapsedcomplete - elapsedembree, ...
    elapsedcomplete / elapsedembree)

%%
if options.Reports && 0 < options.NumHitsToShow
    fprintf('Complete: First %u hits...\n', options.NumHitsToShow)
    tabulardisp(tabularhead(hitscomplete, options.NumHitsToShow))
    fprintf('Embree: First %u hits...\n', options.NumHitsToShow)
    tabulardisp(tabularhead(hitsembree, options.NumHitsToShow))
end

select = @(s) [s.RayIndex, s.FaceIndex];
[~, icomplete, iembree] = intersect( ...
    select(hitscomplete), select(hitsembree), 'rows');

extra = @(a, i) tabularrows(a, setdiff(1 : tabularsize(a), i));
extracomplete = extra(hitscomplete, icomplete);
extraembree = extra(hitsembree, iembree);

fprintf(' %u common hits\n', numel(icomplete))
fprintf('Complete: # extra hits = %u\n', tabularsize(extracomplete))
tabulardisp(extracomplete)
fprintf('  Embree: # extra hits = %u\n', tabularsize(extraembree))
tabulardisp(extraembree)

compare( ...
    hitsembree.RayParameter(iembree, :), ...
    hitscomplete.RayParameter(icomplete, :))
compare( ...
    hitsembree.FaceCoordinates(iembree, :), ...
    hitscomplete.FaceCoordinates(icomplete, :))
compare( ...
    hitsembree.Point(iembree, :), ...
    hitscomplete.Point(icomplete, :))

if options.Plotting
    plotpoints(hitsembree.Point, 'k.')
    plotpoints(extracomplete.Point, 'ro')
    plotpoints(extraembree.Point, 'g*')
    labelpoints(origin + direction)
    labelpoints(vertices)
    labelfacets(faces, vertices)
end

end

function compare(actual, expected)
tol = 1e-5;
mismatch = abs(actual - expected);
scale = abs(expected) + 1.0;
assert(all(mismatch(:)./scale(:) < tol));
end
