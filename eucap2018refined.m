function eucap2018refined(varargin)

import datatypes.cell2table
%
import facevertex.clone
import facevertex.extrude
import facevertex.faces
import facevertex.fv
import facevertex.vertices
%
import points.bbox
import points.text
import points.unary
import points.binary

%%
settings = parse(varargin{:});

%%
dbtype panel

%% Scene geometry and material properties
facets = datatypes.cell2table({
    'Material'     'Gain'   'FaceAlpha'   'FaceColor'   'LineWidth'
    panel.Steel     -3       0.1           rgb.black     2
    panel.Wood      -3       0.1           rgb.salmon    2
    panel.Concrete  -20      0.1           rgb.red       5
    panel.Gib       -3       0.1           rgb.magenta   2
    panel.Glass     -3       0.1           rgb.cyan      2
    panel.Ceiling   -3       0.5           rgb.blue      1
    panel.Floor     -3       0.1           rgb.green     1
    });
facets.EdgeColor = facets.FaceColor;

%%
height.Floor = 0.0;
height.Stud = 3.0;
height.Door = 2.0;
faceData2D = datatypes.cell2table({
    'ID'  'VertexIndices'           'ZSpan'          'Material'      
    1          [1 2]     [height.Floor height.Stud]  panel.Gib
    2          [2 3]     [height.Floor height.Stud]  panel.Concrete
    3          [4 5]     [height.Floor height.Stud]  panel.Gib
    4          [5 6]     [height.Floor height.Stud]  panel.Concrete
    5          [1 4]     [height.Floor height.Stud]  panel.Gib
    6          [3 6]     [height.Floor height.Stud]  panel.Concrete       
    7          [2 7]     [height.Floor height.Stud]  panel.Concrete
    8          [5 8]     [height.Floor height.Stud]  panel.Concrete
    9          [7 8]     [height.Floor height.Door]  panel.Wood
    10         [7 8]     [height.Door  height.Stud]  panel.Glass
    });

%%
vertices2D = [
    0     0
    0     2
    0     4
    3     0
    3     2
    3     4
    1     2
    2     2
    ];

%% View 2-D plan
scene2D = facevertex.fv(faceData2D.VertexIndices, vertices2D);
scene2D.Material = faceData2D.Material;

ax = settings.Axes('2-D Scene');
facevertex.multipatch(ax, ...
    scene2D.Material, facets, ...
    'Faces', faces(scene2D), ...
    'Vertices', vertices(scene2D))
points.text(ax, vertices(scene2D), 'Color', 'blue')
points.text(ax, facevertex.reduce(@mean, scene2D), 'Color', 'red')
axis(ax, bbox(vertices(scene2D), 0.1))
axis(ax, 'equal')

%%
    function draw(ax, scene)
        import facevertex.faces
        import facevertex.vertices
        hold(ax, 'on')
        facevertex.multipatch(ax, ...
            scene.Material, facets, ...% 2D & 3D are currently identical
            'Faces', faces(scene), ...
            'Vertices', vertices(scene))
        points.unary(@plot3, ax, vertices(scene), '.', 'MarkerSize', 15)
        points.text(ax, vertices(scene), 'Color', 'black')
        points.text(ax, facevertex.reduce(@mean, scene), 'Color', 'red')
        graphics.axislabels('x', 'y', 'z')
        axis(ax, points.bbox(vertices(scene), 0.1))
        axis(ax, 'equal')
        view(ax, 3)
        %rotate3d(ax, 'on')
    end

%% Generate 3-D model
[scene2DExtruded, facemap] = facevertex.extrude(scene2D, faceData2D.ZSpan);
scene2DExtruded.Material = scene2D.Material(facemap, :);

ax = settings.Axes('Extruded 2-D Scene');
title('Note the duplicate vertices')
draw(ax, scene2DExtruded)

%%
scene3D = facevertex.compress(scene2DExtruded);
scene3D.Material = scene2DExtruded.Material;

ax = settings.Axes('Compressed 3-D Scene');
draw(ax, scene3D)

%%
floorface = facevertex.cap(@min, 3, scene3D) %#ok<NOPRT>
scene3D.Faces(end + 1, :) = floorface;
scene3D.Material(end + 1, :) = panel.Floor;

ceilingface = facevertex.cap(@max, 3, scene3D) %#ok<NOPRT>
scene3D.Faces(end + 1, :) = ceilingface;
scene3D.Material(end + 1, :) = panel.Ceiling;

ax = settings.Axes('3-D Scene');
draw(ax, scene3D)

%%
elevate = @(x, level) x + level*[0, 0, settings.StudHeight];
allFloors = arrayfun( ...
    facevertex.clone(elevate, scene3D), 0 : settings.NumFloors - 1, ...
    'UniformOutput', false);

ax = settings.Axes('Multistorey');
cellfun(@(scene) draw(ax, scene), allFloors)

%%
quarterTurn = @(x, n) (x + [3, 0, 0])*points.rotor3([0 0 1], n*pi/2); 
allBuildings = arrayfun( ...
    facevertex.clone(quarterTurn, scene3D), 0 : 3, ...
    'UniformOutput', false);

ax = settings.Axes('Multiblock');
cellfun(@(scene) draw(ax, scene), allBuildings)
grid(ax, 'on')

%
%     function stack(field)
%         alllevels.(field) = repmat(scene2D.(field), settings.NumFloors, 1);
%     end
% stack('Material')
% stack('Gain')
% 
% scene = settings.Scene(alllevels.Faces, alllevels.Vertices);
%

disp('Jon: Consider how to handle material properties of cloned object')

return

%% Configure access points
data2d = celltotabular({
    'ID'   'X'     'Y'  'Power'  'Channel'
    1      2.3       2     0        1
    2      2.3       6     0        1
    3      2.3       9     0        1
    4      2.3      13     0        1
    5      2.3      17     0        1
    6      6.8      17     0        1
    7      9.8      17     0        1
    8     13.3      17     0        1
    9     17.3      17     0        1
    10    17.3      11     0        1
    11    17.3       7     0        1
    12    17.3       2     0        1
    13    12.3       2     0        1
    14     6.8       2     0        1
    15       5       5     0        2
    16    13.5    13.5     0        2
    17    13.5       5     0        3
    18       5    13.5     0        3
    });
if isstruct(settings.AccessPoints)
    % Client has provided own table of access points
    data2d = settings.AccessPoints;
else
    % Client has selected from default list
    data2d = tabularrows(data2d, settings.AccessPoints);
end
data3d = tabularvertcat(arrayfun(@embedinfloor, 1 : settings.NumFloors));
    function data = embedinfloor(floorindex, locals)
        locals.height = ...
            settings.StudHeight*(floorindex - 1) + ...
            settings.AccessPointHeight;
        data = setfield(data2d, ...
            'Z', repmat(locals.height, size(data2d.X))); %#ok<SFLD>
        data.ID = data.ID + (floorindex - 1)*100;
        data = orderfields(data, ...
            {'ID', 'X', 'Y', 'Z', 'Power', 'Channel'});
    end
accesspoints = struct( ...
    'Index', data3d.ID, ...
    'Position', perturb([data3d.X, data3d.Y, data3d.Z]), ...
    'Channel', data3d.Channel, ...
    'Gain', data3d.Power);
%%
disp(struct2table(accesspoints))

%% Configure field points
lower = min(alllevels.Vertices, [], 1);
upper = max(alllevels.Vertices, [], 1);
numverticalpoints = settings.NumPointsPerFloor * settings.NumFloors;
widths = upper - lower;
delta = settings.StudHeight / (settings.NumPointsPerFloor + 1);
lower = lower + delta;
upper = upper - delta;
numpoints = ceil(widths./min(widths)*numverticalpoints);
rxxticks = linspace(lower(1), upper(1), numpoints(1));
rxyticks = linspace(lower(2), upper(2), numpoints(2));
rxzticks = linspace(lower(3), upper(3), numpoints(3));
rxgridpoints = gridpoints(rxxticks, rxyticks, rxzticks);
mobiles = struct( ...
    'Index', vec(1 : size(rxgridpoints, 1)), ...
    'Position', rxgridpoints);
%%
disp(struct2table(tabularhead(mobiles)))

%% Visualize configuration
    function varargout = showscene(title)
        ax = settings.Axes(title);
        hold(ax, 'on')
        multipatch(ax, ...
            allFloors.Material, facets, ...
            'Faces', allFloors.Faces, ...
            'Vertices', allFloors.Vertices, ...
            'FaceAlpha', 0.05)
        plotpoints(ax, accesspoints.Position, '.', 'MarkerSize', 30, 'Color', 'red')
        labelpoints(ax, accesspoints.Position + 0.2, ...
            csprintf('%u(%u)', accesspoints.Index, accesspoints.Channel), ...
            'FontSize', settings.FontSize)
        set(ax, 'FontSize', settings.FontSize)
        labelaxes(ax, 'x', 'y', 'z', 'FontSize', settings.FontSize)
        %camproj(ax, 'perspective')
        rotate3d(ax, 'on')
        axis(ax, 'equal')
        axis(ax, 'tight')
        rotate3d(ax, 'on')
        if 0 < nargout
            varargout = {ax};
        end
    end
%%
showrxpoints = @(ax) plotpoints(ax, ...
    mobiles.Position, '.', 'MarkerSize', 5, 'Color', 'black');
%%
ax = showscene('3D View');
view(ax, -150, 60)
showrxpoints(ax)
%%
ax = showscene('Top View');
view(ax, 0, 90);
showrxpoints(ax)
%%
ax = showscene('Side View');
view(ax, 90, 0);
showrxpoints(ax)

%% Perform analysis
starttime = tic;
fprintf('Running %s... \n', func2str(settings.Scene))
downlinks = analyze( ...
    accesspoints.Position, mobiles.Position, scene, ...
    'NumWorkers', settings.NumWorkers, ...
    'ReflectionArities', settings.Arities, ...
    'ReflectionGain', isofunction(alllevels.Gain), ...
    'Reporting', settings.Reporting, ...
    'SPMD', settings.SPMD, ...
    'TransmissionGain', isofunction(alllevels.Gain), ...
    'Verbosity', settings.Verbosity);
toc(starttime)

%% Visualize super-threshold SINR
ax = showscene('High SINR');
scatterpoints(ax, mobiles.Position, 30, ...
    threshold(downlinks.SINRatio, settings.SINRThreshold, 'above'), ...
    'filled', ...
    'MarkerFaceAlpha', 0.99)
caxis(ax, minmax(downlinks.SINRatio))
colorbar(ax)
view(ax, 3)

%% Visualize sub-threshold SINR
ax = showscene('Low SINR');
scatterpoints(ax, mobiles.Position, 30, ...
    threshold(downlinks.SINRatio, settings.SINRThreshold, 'below'), ...
    'filled', ...
    'MarkerFaceAlpha', 0.99)
caxis(ax, minmax(downlinks.SINRatio))
colorbar(ax)
view(ax, 3)

%%
% Sanity checks
gridshape = [numel(rxyticks), numel(rxxticks), numel(rxzticks)];
[x, y, z] = meshgrid(rxxticks, rxyticks, rxzticks);
assert(isequal(mobiles.Position(:, 1), x(:)))
assert(isequal(mobiles.Position(:, 2), y(:)))
assert(isequal(mobiles.Position(:, 3), z(:)))
assert(isequal(size(x), gridshape))

%% Visualize SINR contours
sinrgrid = reshape(downlinks.SINRatio, gridshape);
contourdata = {
    x(:, :, 1), ...
    y(:, :, 1), ...
    median(threshold(sinrgrid, realmax, 'below'), 3)
    };
ax = showscene('All Contours');
[contourmatrix, contourhandle] = contourf(ax, contourdata{:});
uistack(ax, contourhandle, 'bottom');
clabel(contourmatrix, contourhandle, ...
    'FontSize', settings.FontSize, ...
    'Color', 'black');
caxis(ax, minmax(downlinks.SINRatio))
colorbar(ax)

%% Hightlight SINR threshold
ax = showscene('Binary Contours');
[contourmatrix, contourhandle] = contourf(ax, ...
    contourdata{:}, [-realmax, settings.SINRThreshold]);
colormap(ax, [rgbsalmon; rgblime])
uistack(ax, contourhandle, 'bottom');
clabel(contourmatrix, contourhandle, ...
    'FontSize', settings.FontSize, ...
    'Color', 'black');

%% SINR isosurfaces
isosurf = @(ax, level, color) ...
    patch(ax, isosurface( ...
    x, y, z, sinrgrid, level, 'verbose'), ...
    'FaceAlpha', 0.9, 'FaceColor', color, 'EdgeColor', color);

%%
ax = showscene('Isosurface');
hold(ax, 'on')
delta = 1.0;
isosurf(ax, settings.SINRThreshold - delta, rgbsalmon)
isosurf(ax, settings.SINRThreshold + delta, rgblime)
%arrayfun(@(~) set(camlight, 'Parent', ax), 1 : 3)
view(ax, 3)

%% A very coarse measure of coverage
quantiletable(downlinks.SINRatio) % requires Statistics Toolbox

%%
fig = settings.Figure;
savefig(settings.Figure, fig.Name, 'compact')
fprintf('Saved figure in "%s.fig"\n', fig.Name)
%fig.Visible = 'off'; % uncomment to suppress trailing plot in published report

end

%%
function settings = parse(varargin)

import graphics.tabbedfigure
import parallel.currentpool
import parallel.numworkers

parser = inputParser;

% Transmitter/receiver configuration
parser.addParameter('NumFloors', 3, @(n) isscalar(n) && 0 < n)
parser.addParameter('NumPointsPerFloor', 5, @(n) isscalar(n) && 0 < n)
parser.addParameter('AccessPoints', 17:18, @(indices) all(iswithin(indices, 1, 18)))
parser.addParameter('SINRThreshold', 10, @(x) isscalar(x) && 0 < x)
% Image method
parser.addParameter('Arities', 0 : 1, @isrow)
parser.addParameter('Scene', @completescene, @isfunction)
parser.addParameter('Reporting', false, @islogical)
parser.addParameter('Verbosity', 0, @isscalar)
% Scene geometry
parser.addParameter('AccessPointHeight', 2.0, @isscalar) % [m]
parser.addParameter('DoorHeight', 2.2, @isscalar) % [m]
parser.addParameter('StudHeight', 3.0, @isscalar) % [m]
% Visualization
parser.addParameter('Axes', @newaxes, @isfunction)
parser.addParameter('Plotting', true, @islogical)
parser.addParameter('Figure', 1, @isscalar)
parser.addParameter('FontSize', 10, @isscalar)
% Parallel processing
parser.addParameter('SPMD', isscalar(currentpool), @(b) isscalar(b) && islogical(b))
parser.addParameter('NumWorkers', numworkers(currentpool), @(n) isscalar(n) && 1 <= n)

parser.parse(varargin{:})
settings = parser.Results;

% Configure tabbed figure
fig = figure(settings.Figure);
clf(fig, 'reset')
fig.NumberTitle = 'off';
fig.Visible = 'off'; % suppress in published output...
newtab = tabbedfigure(fig, 'Visible', 'on'); % ... until first use
    function ax = newaxes(tabtitle)
        ax = axes(newtab(tabtitle));
    end
fig.Name = sprintf('Scenario (APs %s, %s-reflected)', ...
    mat2str(settings.AccessPoints), ...
    mat2str(settings.Arities));
settings.Figure = fig;

end
