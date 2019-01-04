varargin = {}; % Argument list can go here

%% Optional arguments
parser = inputParser;
parser.addParameter('LargeScale', true, @islogical)
parser.addParameter('Arities', 0, @isrow)
parser.addParameter('Fraction', 1.0, @isnumeric)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Plotting', true, @islogical)
parser.addParameter('Printing', false, @islogical)
parser.addParameter('Scene', @scenes.Scene, @datatypes.isfunction)
parser.addParameter('Serialize', false, @islogical)
parser.addParameter('StudHeight', 3.0, @isscalar)
parser.addParameter('XGrid', [], @isvector)
parser.addParameter('YGrid', [], @isvector)
parser.addParameter('CullDuplicateFaces', false, @islogical)
parser.parse(varargin{:})
options = parser.Results;

%% Wall plan & materials set
[linevertices, materialsdata, wallmaterials] = data.building903level4;
[faces, vertices] = facevertex.compress(facevertex.xy2fv( ...
    linevertices(:, [1 3])', ...
    linevertices(:, [2 4])'));
%% Change to better format

% Extra vertices **after** facevertex.compress!
vertices = [
    vertices;
    vertices(24, 1), vertices(3, 2); % (x24, y3)
    vertices(39, 1), vertices(25, 2); % (x39, y25)
];

if options.CullDuplicateFaces
    [~, select] = unique(sort(faces, 2), 'rows');
    fprintf('Removing %d redundant facet(s): %s\n', ...
        size(faces, 1) - numel(select), ...
        mat2str(setdiff(1 : size(faces, 1), select)))
    faces = faces(select, :);
else
    disp('WARNING: Duplicate faces exist')
    warning('off', 'embreescene:DuplicateFaces')
    warning('off', 'embreescene:DuplicateVertices')
end

%%
ax = axes(figure(1)); 
clf(ax, 'reset')
patch(ax, 'Faces', faces, 'Vertices', vertices)
points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
points.text(ax, vertices, 'FontSize', 10, 'Color', 'red')
axis('equal')

%%
extruded = facevertex.extrude(faces, vertices, [0.0, options.StudHeight]);
[faces, vertices] = facevertex.fv(extruded);

% Add 3 floor panels
floor = [
    1 24 71 3;
    25 72 39 71;
    72 68 70 40;
    ];
numfloorpanels = size(floor, 1);

% Add 3 ceiling panels
ceiling = floor + max(floor(:));

% Add ceiling **but not floor** onto original walls
faces = [faces; ceiling];

% Make a struct of faces & vertices only for use in the "clone" function,
% below
% Be wary of the distinction between these two objects!
scene = options.Scene(faces, vertices);
fv = struct('Faces', faces, 'Vertices', vertices);

%%
numFloors =3;
elevate = @(x, level) x + level*[0, 0, options.StudHeight];
storeys = arrayfun( ...
    facevertex.clone(elevate, fv), 0 : numFloors - 1, ...
    'UniformOutput', false);
combinedStoreys = facevertex.cat(storeys{:});
faces = combinedStoreys.Faces;
vertices = combinedStoreys.Vertices;

% Completely artibrary transmission & reflection coefficients
% for a floor/ceiling panel
materialsdata(end + 1, :) = [-12, -15];
floorceilingmaterialtype = size(materialsdata, 1); % after appending/resizing
floorceilingmaterials = repmat(floorceilingmaterialtype, numfloorpanels, 1);
wallmaterials = [
    wallmaterials;
    floorceilingmaterials;
    ];

wallmaterials = repmat(wallmaterials, numFloors, 1);
% At this point, we have a single scene with material properties that
% is missing only the definition of the floor on the ground storey.

% Add the ground storey's floor
faces = [faces; floor];
wallmaterials = [wallmaterials; floorceilingmaterials];
%%

materials = struct( ...
    'TransmissionGain', materialsdata(wallmaterials, 1), ...
    'ReflectionGain', materialsdata(wallmaterials, 2));

%%
if options.Plotting
    ax = axes(figure(1));
    clf(ax, 'reset')
    hold(ax, 'on')
    patch(ax, ...
        'Faces', faces, ...
        'Vertices', vertices, ...
        'FaceAlpha', 0.2, ...
        'FaceColor', graphics.rgb.blue, ...
        'EdgeColor', graphics.rgb.gray, ...
        'LineWidth', 1);
    patch(ax, ...
        'Faces', faces(wallmaterials == 9, :), ...
        'Vertices', vertices, ...
        'FaceAlpha', 0.5, ...
        'FaceColor', graphics.rgb.magenta, ...
        'EdgeColor', graphics.rgb.gray, ...
        'LineWidth', 1);
    %points.text(ax, facevertex.reduce(@mean, faces, vertices), 'FontSize', 7, 'Color', 'black')
    %points.text(ax, vertices, 'FontSize', 10, 'Color', 'red')
    set(ax, 'XTick', [0, 30.5], 'YTick', [0, 7.5])
    axis(ax, 'tight')
    axis(ax, 'equal')
    grid(ax, 'on')
    rotate3d('on')
    view(3)
end

% Sanity checks
assert(size(faces, 1) == numel(wallmaterials))

temporary = [materials.ReflectionGain, materials.TransmissionGain];
[uniquetemporary, ~, map] = unique(temporary, 'rows');
for index = 1 : size(uniquetemporary, 1)
    select = map == index;
    facesubset = faces(select, :);
    fig = figure(1 + index);
    clf(fig)
    ax = axes(fig);
    view(ax, -35, 15)
    hold(ax, 'on')
    patch(ax, 'Faces', facesubset, 'Vertices', vertices, 'FaceAlpha', 0.1)
    points.text(ax, facevertex.reduce(@mean, facesubset, vertices), 'FontSize', 7, 'Color', 'blue')
    title(ax, sprintf('Material group #%i', index))
    axis(ax, 'equal')
    axis(ax, 'tight')
    rotate3d(ax, 'on')
end
