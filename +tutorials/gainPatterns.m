%% Definition of gain patterns
function gainPatterns

%% Overview
% The gain pattern functionality was designed to satisfy the following
% requirements: 
%
% * Gain function evaluation should be vectorized internally.
% * Simple cases should be easy to implement.
% * Complicated cases should be possible to implement.
% * An arbitrary system of local coordinates can be employed, using any
% convenient convention.
%

%% Geometric model
% The geometric model is a simple square, comprises four vertices and four
% "faces" actually lines. Naturally, geometric models may be arbitrarily
% complex.

% One vertex per row
vertices = [
    -1 -1; % 1: SW
    +1 -1; % 2: SE
    +1 +1; % 3: NE
    -1 +1; % 4: NW
    ];

% One list of vertex indices per row
faces = [
    1 2;
    2 3;
    3 4;
    4 1;
    ];

%%
% Compute the center-point, a unit normal tangent vector, and a unit normal
% vector for each facet.
% Helper function |facevertex.reduce| applies a reduction function to the
% matrix whos rows comprise the vertices of each facet.
centers = facevertex.reduce(@mean, faces, vertices);
    function unitTangents = faceTangents(points)
        unitTangents = matfun.unit(diff(points), 2);
    end
tangents = facevertex.reduce(@faceTangents, faces, vertices);
normals = specfun.perp(-tangents, 2);

%%
% Stacks the normals and tangents into a pair of local Cartesian axes for
% each facet. Note that the order is significant (albeit arbitrary): In our
% case, we use the normal vector as the "x-axis" for local polar coordinate
% at each facet.
frames = cat(3, normals, tangents);

%% Define rays
% Here, we define a full circle of rays for each facet. In general, the
% number of rays incident on each facet is variable (0 or more). 
theta = linspace(0, 2*pi, 250);
identities = repmat(transpose(1 : size(faces, 1)), numel(theta), 1);
directions = repmat([cos(theta(:)), sin(theta(:))], size(faces, 1), 1);
assert(size(directions, 1) == size(identities, 1))

%% Helper function 
% To display geometry with frame vectors.
    function showSceneWithGain(db)
        figure(1), clf, hold on
        patch('Faces', faces, 'Vertices', vertices)
        points.plot(centers, 'ro')
        points.text(centers)
        points.quiver(centers, normals, 0, 'r')
        points.quiver(centers, tangents, 0, 'b')
        axis(points.bbox(centers + normals, 0.1), 'equal')
        points.plot(centers(identities, :) + db.*directions, '.')
    end
showSceneWithGain(0)

%% Gain patterns
% These can be defined in *any* convenient coordinate system. In our case,
% we work in polar coordinates relative to the unit normal of each facet
% (i.e. the unit normal is the "x-axis" of the local coordinate system).
%
% Although all patterns are, typically, defined in the same coordinate
% system, this is not a restriction, as demonstrated in *Vertion #2*,
% below.
gains = {
    @(angle) angle/(2*pi);
    @(angle) abs(cos(1*angle));
    @(angle) 1 - angle/(2*pi);
    @(angle) abs(cos(2*angle));
    };

%% Version #1: Implemented from scratch
% What follows is a reference implementation, intended to be transparent
% (reasonably easy to follow). Unfortunately, because each ray is processed
% individually (in a loop), this implementation is extremely *slow*.
    function db = antennaeVersionOne(id, direction, local)
        db = zeros(size(direction, 1), 1);
        for i = 1 : numel(db)
            local.id = id(i); % facet ID
            local.unit = direction(i, :); % direction of incidence
            local.x = dot(normals(local.id, :), local.unit); % x-coordinate in local frame
            local.y = dot(tangents(local.id, :), local.unit); % y-coordinate in local frame
            angle = specfun.wrapinterval(cart2pol(local.x, local.y), 0, 2*pi); % polar angle in local frame
            db(i) = gains{local.id}(angle);
        end
    end
showSceneWithGain(antennaeVersionOne(identities, directions))

%% Version #2: Standard case
% This is the most commmon use case, where all gain patterns involve the
% same class of coordinate transform (e.g. "global Cartesian to local
% unit-polar"). 
antennaeVersionTwo = antennae.dispatch( ...
    gains, ... % all functions must have a common interface (e.g. "angle")
    1 : 4, ... % map from facet ID to index in function list
    antennae.orthocontext(frames, @specfun.cart2upol));
%%
showSceneWithGain(antennaeVersionTwo(identities, directions))

%% Version #3: Non-standard case
% The following implementation shows how a (potentially different)
% coordinate transformation context could be specified for each gain
% pattern. Each function handle in the cell array should accept an array of
% indices and a matrix of directions (in global Cartesian coordinates).
antennaeVersionThree = antennae.dispatch({
    @(id, ~) gains{1}(id); % examines only the size of its argument
    @(id, ~) gains{2}(id); % (ditto)
    antennae.orthofunction(gains{3}, frames, @specfun.cart2upol, 1);
    antennae.orthofunction(gains{4}, frames, @specfun.cart2upol, 1);
    }, ...
    1 : 4); % map from facet ID to index in function list
%%
showSceneWithGain(antennaeVersionThree(identities, directions))

%%
end
