%% Tutorial on the representation of scene geometry

%%
clear
fontsize = 12;
figureindex = 1;

%% Helper functions
assertequal = @(a, b) assert(norm(a - b, inf) < 1e-12); % "equal arrays?"
assertzero = @(a) assertequal(a, 0); % "zero array?"
normrows = @(a) sqrt(sum(a.^2, 2)); % Euclidean norm of each row
dotrows = @(a, b) dot(a, b, 2); % dot product of each pair of rows
showtable = @(varargin) tabulardisp(struct(varargin{:})); % pretty-print a tabular struct
rowstotext = @(a) cellfun(@mat2str, num2cell(a, 2), 'UniformOutput', false); % convert rows to text

%% Two dimensional model
% We start with _vertex_ coordinates. Note that vertices 
% need not lie on a regular cartesian grid/lattice.
xtick = [0.0, 3.0]; % [m]
ytick = [0.0, 2.0, 4.0]; % [m]
[x, y] = meshgrid(xtick, ytick);
vertices = [x(:), y(:)];
%%
% Vertex coordinates in tabular form
tabulardisp(struct( ...
    'VertexIndex', (1 : size(vertices, 1))', ...
    'VertexCoordinates', vertices))

%%
% and in graphical form.
fig = figure(figureindex);
clf(fig, 'reset')
ax = axes(fig); 
hold(ax, 'on')
plotpoints(ax, vertices, '.')
labelpoints(ax, vertices, 'FontSize', fontsize, 'Color', 'red')
labelaxes(ax, 'x', 'y')
axis(ax, 'equal')
axis(ax, [xtick(1) - 1, xtick(end) + 1, ytick(1) - 1, ytick(end) + 1])

%%
% In two dimensions, _faces_ are actually line segments.
% We'll start with the so-called _face-vertex_ representation of scene
% geometry wherein each segment is encoded by an ordered pair of vertices.
faces = [1 2; 2 3; 4 5; 5 6; 1 4; 2 5; 3 6];
showtable( ...
    'FaceIndex', (1 : size(faces, 1))', ...
    'FaceVertices', faces)

%%
% MATLAB's own |patch| function employs the face-vertex respresentation
% directly.
patch(ax, ...
    'Faces', faces, ...
    'Vertices', vertices);
labelfacets(ax, faces, vertices, 'FontSize', fontsize, 'Color', 'blue')

%%
% Function |fvtotangents| returns an alternative representation, comprising
% one vertex in each face (|origin|) and a free vector (|tangent{:}|)
% joining the vertex pair. 
[origin, tangent] = fvtotangents(faces, vertices);
%% 
% The latter is a cell array to accommodate the three-dimensional case. 
tangent = tangent{:};

%%
% The advertised properties are easily confirmed:
first = vertices(faces(:, 1), :); % first vertex in each segment
second = vertices(faces(:, 2), :); % second vertex in each segment
assertequal(first, origin)
assertequal(second - first, tangent)

%%
% Function |fvframes| returns an orthonormal pair of axes in
% |frame|, whose own (local) origin we associated with the global
% coordinates in |origin|.
%
% * |frame(k, :, 1)| contains the global coordinates of a unit normal
% vector to facet |k|.
% * |frame(k, :, 2)| contains the global coordinates of the unit vector
% parallel to |tangent{:}|.
% * |map(:, :, k)| contains the the coefficients of an affine map from
% points in the affine hull of the face to the local coordinates with
% respect to the *unnormalized* tangential axis (|tangent|).
%
% NB. The association of |frame(:, :, 1)| with the normal direction is
% arbitrary, but deliberate: In two dimensions, the first cartesian axis is
% conventionally associated with the polar angle of zero, and it is with
% this angle that we associate facet normals in antenna patterns for
% electromagnetic simulations.
[frame, map] = fvframes(origin, tangent);

%%
% Let's confirm |frame|'s advertised properties:
axis1 = frame(:, :, 1);
axis2 = frame(:, :, 2);
assertzero(dotrows(axis1, axis2)) % orthogonality
assertzero(normrows(axis1) - ones) % unit norm
assertzero(normrows(axis2) - ones) % unit norm
assertequal(axis2, tangent./normrows(tangent)) % unit tangent

%%
plotframes(ax, origin, frame, 0.2, 'Color', 'blue')

%%
% The properties of |map| are best demonstrated with an example: Let's
% generate points located, say, three quarters of the way along each face.
specifiedlocal = 0.75;
xglobal = origin + specifiedlocal*tangent; 
plotpoints(xglobal, 'o')

%%
% Local coordinates are computed as the contraction of |map| with the
% global coordinates of the _offset_ from the origin.
xlocal = dotrows(map, xglobal - origin);
showtable( ...
    'FaceIndex', (1 : size(faces, 1))', ...    
    'Global', xglobal, ...
    'Local', xlocal)
assertequal(xlocal, specifiedlocal)

%%
% Summary of face data:
showtable( ...
    'Index', (1 : size(faces, 1))', ...
    'Faces', faces, ...
    'Normal', frame(:, :, 1), ...
    'Tangent', frame(:, :, 2))

%%
% Clear workspace except for...
clearexcept faces vertices ax fontsize ... floor plan and
    assertequal assertzero dotrows normrows rowstotext showtable % helpers

%% Three dimensional model
% To demonstrate the representation of three-dimensional scenes, let's
% extrude our existing two-dimensional plan in the vertical direction.
studheight = 3.0; % [m]
model = extrudeplan(faces, vertices, 0.0, studheight);

%%
% The result is the familiar face-vertex representation:
showtable( ...
    'VertexIndex', (1 : size(model.Vertices, 1))', ...
    'VertexCoordinates', model.Vertices)
%%
% In three dimensions, each rectangular facet requires a list of four
% vertices.
% (These are displayed as text because the original arrays, being
% too wide, are rendered as |[1x4 double]|.)
showtable( ...
    'FaceIndex', (1 : size(model.Faces, 1))', ...
    'FaceVertices', {rowstotext(model.Faces)})

%%
% Note that, in this case, the original vertices are now embedded in three
% dimensions at two values of the new coordinate:
assertequal(model.Vertices(1 : end/2, 3), zeros)
assertequal(model.Vertices(end/2 + 1 : end, 3), studheight)

%%
% Again, this representation is compatible with |patch|.
cla(ax, 'reset')
hold(ax, 'on')
patch(ax, ...
    'Faces', model.Faces, ... % extruded (vertical) surfaces
    'Vertices', model.Vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'blue');
labelpoints(ax, model.Vertices, 'FontSize', fontsize, 'Color', 'red')
labelfacets(ax, model.Faces, model.Vertices, 'FontSize', fontsize, 'Color', 'blue')
labelaxes(ax, 'x', 'y', 'z')
axis(ax, 'equal')
rotate3d(ax, 'on')
view(ax, -60, 30)

%% 
% Add a floor and ceiling to the extruded model.
floor = true; % "include floor facet?"
ceiling = true; % "include ceiling facet?"
[faces, vertices] = capfacevertex(model, floor, ceiling);
%%
% The additional face(s) are added to the bottom (final two rows) of
% |model.Faces|. Here, they are highlighted in a different color.
patch(ax, ...
    'Faces', faces(end - 1 : end, :), ... % surfaces of floor & ceiling
    'Vertices', vertices, ...
    'FaceAlpha', 0.05, ...
    'EdgeAlpha', 0.3, ...
    'FaceColor', 'red');
labelpoints(ax, vertices, 'FontSize', fontsize, 'Color', 'red')
labelfacets(ax, faces, vertices, 'FontSize', fontsize, 'Color', 'blue')

%%
% In three dimensions, a frame defines a *pair* of orthogonal tangential
% directions (first two axes) and a normal direction (third axis).
[origin, tangents] = fvtotangents(faces, vertices);

%%
% NB. The association of |frame(:, :, 3)| with the normal direction (cf.
% |frame(:, :, 1)| in the two dimensional case) is arbitrary, but
% deliberate: In three dimensions, the third cartesian axis is
% conventionally associated with angle of inclination zero, and it is with
% this angle that we associate facet normals in antenna patterns for
% electromagnetic simulations.
[frame, map] = fvframes(origin, tangents{:});

%%
% Verify advertised properties of |frame|:
axis1 = frame(:, :, 1);
axis2 = frame(:, :, 2);
axis3 = frame(:, :, 3);
assertzero(dotrows(axis1, axis2)) % orthogonality
assertzero(dotrows(axis1, axis3)) % orthogonality
assertzero(dotrows(axis2, axis3)) % orthogonality
assertzero(normrows(axis1) - ones) % unit norm
assertzero(normrows(axis2) - ones) % unit norm
assertzero(normrows(axis3) - ones) % unit norm
assertequal(axis1, tangents{1}./normrows(tangents{1})) % unit tangent
assertequal(axis2, tangents{2}./normrows(tangents{2})) % unit tangent

%%
plotframes(ax, origin, frame, 0.2, 'Color', 'blue')

%%
% Coordinate maps work in the same way as in the two-dimensional model.

%%
% The properties of |map| are best demonstrated with an example: Let's
% generate points located, say, three quarters of the way along each face.
specifiedlocal = [0.5, 0.75];
xglobal = origin + ...
    specifiedlocal(1)*tangents{1} + ...
    specifiedlocal(2)*tangents{2}; 
plotpoints(xglobal, 'o')
plotvectors(origin, xglobal - origin, 0)

%%
% Local coordinates are computed as the contraction of |map| with the
% global coordinates of the _offset_ from the origin.
offset = xglobal - origin;
xlocal = [
    dotrows(map(:, :, 1), offset), ...
    dotrows(map(:, :, 2), offset)
    ];
%%
showtable( ...
    'FaceIndex', (1 : size(faces, 1))', ...    
    'Global', xglobal, ...
    'Local', xlocal)
assertequal(xlocal(:, 1), specifiedlocal(1))
assertequal(xlocal(:, 2), specifiedlocal(2))

%%
% Summary of vertex data for final 3-dimensional scene:
showtable( ...
    'Index', (1 : size(vertices, 1))', ...
    'Vertices', vertices)
%%
% Summary of face data for final scene scene:
showtable( ...
    'Index', (1 : size(faces, 1))', ...
    'Faces', {rowstotext(faces)}, ...
    'Tangent1', frame(:, :, 1), ...
    'Tangent2', frame(:, :, 2), ...
    'Normal', frame(:, :, 3))

%% Computation of the global-to-local mapping coefficients
clearexcept ax assertequal assertzero dotrows normrows

%%
% Start with a completely random set of origins and tangent
numfacets = 4;
numdirections = 3;
random = @() rand(numfacets, numdirections);
origin = random();
tangent1 = random();
tangent2 = random();
specifiedlocal = [0.25, 0.75];

% Check that |fvframes| doesn't rely on orthogonal tangents
[frame, map] = fvframes(origin, tangent1, tangent2);
axis1 = frame(:, :, 1);
axis2 = frame(:, :, 2);
axis3 = frame(:, :, 3);
assertzero(dotrows(axis1, axis2))
assertzero(dotrows(axis1, axis3))
assertzero(dotrows(axis2, axis3))

xglobal = origin + ...
    specifiedlocal(1)*tangent1 + ...
    specifiedlocal(2)*tangent2;

offset = xglobal - origin;
xlocal1 = dotrows(map(:, :, 1), offset);
xlocal2 = dotrows(map(:, :, 2), offset);

assertequal(specifiedlocal(1), xlocal1)
assertequal(specifiedlocal(2), xlocal2)

[frame1, r11] = unit(tangent1);
r12 = dotrows(tangent2, frame1);
[frame2, r22] = unit(tangent2 - frame1.*r12);

assertequal(frame(:, :, 1), frame1)
assertequal(frame(:, :, 2), frame2)

% Verify our orthogonal-triangular (QR) decomposition
assertequal(tangent1, frame1.*r11)
assertequal(tangent2, frame1.*r12 + frame2.*r22)
assertequal(normrows(frame1), ones)
assertequal(normrows(frame2), ones)
assertequal(dotrows(frame1, frame2), zeros)

%%
% At this point, we have established:
% 
% $$\vec{x}_G = \vec{o} + T\vec{x}_L = \vec{o} + (F R)\vec{x}_L$$
%
% where
%
% $$F^\top F = I$$
%
% and 
%
% $$R^{-1} = \left[\begin{array}{cc} r_{11} & r_{12} \\ 0 & r_{22} \end{array}\right]^{-1} = \left[\begin{array}{cc} 1/r_{11} & -r_{12}/(r_{11} r_{22}) \\ 0 & 1/r_{22} \end{array}\right]$$
%
% Hence, 
%
% $$\vec{x}_L = R^{-1} (F^\top (\vec{x}_G - \vec{o}))$$
%
z1 = dotrows(frame1, offset);
z2 = dotrows(frame2, offset);

%%
xlocal1 = z1./r11 - z2.*r12./(r11.*r22);
xlocal2 =           z2./r22;
assertequal(specifiedlocal(1), xlocal1)
assertequal(specifiedlocal(2), xlocal2)

%%
function [u, vnorm] = unit(v)
% Unit vectors and lengths.
vnorm = sqrt(sum(v.^2, 2)); % lengths
u = v./vnorm; % coefficients of normalized vectors
end
