function analysisDemo

%% Prepare workspace and figure
clear % workspace
import graphics.tabbedfigure

fig = figure(1);
newtab = tabbedfigure(fig, 'Visible', 'on'); % ... until first use
    function ax = newaxes(tabtitle)
        ax = axes(newtab(tabtitle));
    end

    function size = fontsize
        size = 15;
    end

    function labelaxis(ax, origins, frames, direction, local)
        local.axisscale = 1.5;
        local.labelscale = 1.6;
        local.format = graphics.untex('$\mathbf{e}_{%u,%u}$');
        points.quiver(ax, ...
            origins, local.axisscale*frames(:, :, direction), ...
            0, ... % no scaling
            'Color', graphics.rgb.gray(0.5), ...
            'LineWidth', 2)
        points.text(ax, ...
            origins + local.labelscale*frames(:, :, direction), ...
            compose(local.format, elmat.index(origins, 1), direction), ...
            'Interpreter', 'latex', ...
            'FontSize', fontsize);
    end

    function plotaxes(ax, origins, frames)
        points.text(ax, ...
            origins, ...
            compose( ...
            graphics.untex('$\mathbf{o}_%d$'), elmat.index(origins, 1)), ...
            'Interpreter', 'latex', 'FontSize', fontsize)
        for i = 1 : elmat.ncols(origins)
            labelaxis(ax, origins, frames, i);
        end
    end

%%
dbtype +examples/Materials.m

%% Scene geometry and material properties
import examples.Materials
facets = datatypes.cell2table({
    'Material'         'Gain'   'FaceAlpha'   'FaceColor'            'LineWidth'
    Materials.Concrete  -20      0.1           graphics.rgb.red       2
    Materials.Gib       -3       0.1           graphics.rgb.magenta   1
    });
facets.EdgeColor = facets.FaceColor;

%% Geometric data
vertices2D = [0 0; 0 8; 5 0; 5 4; 10 0; 10 4; 15 0; 15 8];
faceData2D = datatypes.cell2table({
    'ID'    'VertexIndices'     'Material'
    1       [1 7]               Materials.Gib
    2       [7 8]               Materials.Gib
    3       [8 2]               Materials.Gib
    4       [2 1]               Materials.Concrete
    5       [3 4]               Materials.Concrete
    6       [5 6]               Materials.Concrete
    });

%% View 2-D plan
scene2D = facevertex.fv(faceData2D.VertexIndices, vertices2D);
scene2D.Material = faceData2D.Material;
faceData = scenes.Scene(faceData2D.VertexIndices, vertices2D);

ax = newaxes('2-D Scene');
facevertex.multipatch(ax, ...
    scene2D.Material, facets, ...
    'Faces', facevertex.faces(scene2D), ...
    'Vertices', facevertex.vertices(scene2D))
points.text(ax, facevertex.vertices(scene2D), 'Color', 'blue')
points.text(ax, facevertex.reduce(@mean, scene2D), 'Color', 'black')
axis(ax, points.bbox(facevertex.vertices(scene2D), 0.1))
axis(ax, 'equal')

%% ---
%%
% Compute the center-point, a unit normal tangent vector, and a unit normal
% vector for each facet.
% Helper function |facevertex.reduce| applies a reduction function to the
% matrix whos rows comprise the vertices of each facet.
centers = facevertex.reduce(@mean, scene2D.Faces, scene2D.Vertices);
    function unitTangents = faceTangents(points)
        unitTangents = matfun.unit(diff(points), 2);
    end
tangents = facevertex.reduce(@faceTangents, scene2D.Faces, scene2D.Vertices);
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
identities = repmat(transpose(1 : size(scene2D.Faces, 1)), numel(theta), 1);
directions = repmat([cos(theta(:)), sin(theta(:))], size(scene2D.Faces, 1), 1);
assert(size(directions, 1) == size(identities, 1))

%% Helper function
% To display geometry with frame vectors.
    function showSceneWithGain(db)
        cla(ax), hold on
        facevertex.multipatch(ax, ...
            scene2D.Material, facets, ...
            'Faces', facevertex.faces(scene2D), ...
            'Vertices', facevertex.vertices(scene2D))
        points.text(ax, facevertex.vertices(scene2D), 'Color', 'blue')
        points.text(ax, facevertex.reduce(@mean, scene2D), 'Color', 'black')
        axis(ax, points.bbox(facevertex.vertices(scene2D), 0.1))
        axis(ax, 'equal')
        points.plot(ax, centers, 'ro')
        points.text(ax, centers)
        points.quiver(ax, centers, normals, 0, 'r')
        points.quiver(ax, centers, tangents, 0, 'b')
        axis(ax, points.bbox(centers + normals, 0.1), 'equal')
        points.plot(ax, centers(identities, :) + db.*directions, '.')
        axis(ax, 'tight')
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
[uniqueMaterials, ~, faceIndexToGainIndex] = unique(faceData2D.Material);
gains{uniqueMaterials == Materials.Concrete} = @(angle) angle/(2*pi);
gains{uniqueMaterials == Materials.Gib} = @(angle) abs(cos(angle));

%% Global Cartesian to local polar coordinate transformation
antennaeVersionTwo = antennae.dispatch( ...
    gains, ... % all functions must have a common interface (e.g. "angle")
    faceIndexToGainIndex, ... % map from facet ID to index in function list
    antennae.orthocontext(frames, @specfun.cart2upol));
%%
showSceneWithGain(antennaeVersionTwo(identities, directions))

%% Gain patterns
source.Origin = [
    2 2;
    12 6;
    ];
source.Gain = antennae.isopattern(1.5);
source.Frequency = 2.45d9; % [Hz]

[gridx, gridy] = meshgrid( ...
    linspace(0, 15, 10), ...
    linspace(0, 8, 10));
sink.Origin = points.meshpoints(gridx, gridy);

unitCircle = antennae.isopattern(1.0);
[material, ~, faceToPatternIndex] = unique(faceData2D.Material);
reflectionPattern{material == Materials.Gib} = antennae.isopattern(0.1);
reflectionPattern{material == Materials.Concrete} = antennae.isopattern(0.2);
transmissionPattern{material == Materials.Gib} = antennae.isopattern(0.3);
transmissionPattern{material == Materials.Concrete} = antennae.isopattern(0.4);
polarContext = antennae.orthocontext(faceData.Frame, @specfun.cart2pol);

%%
% See |tutorials.gainPatterns.m| for an explanation.
reflectionGains = antennae.dispatch( ...
    reflectionPattern, ...
    faceToPatternIndex, ...
    polarContext);
transmissionGains = antennae.dispatch( ...
    transmissionPattern, ...
    faceToPatternIndex, ...
    polarContext);

%% Sampling angles
theta = linspace(0, pi, 20);
phi = linspace(0, 2*pi)';

hold(ax, 'on')
grid(ax, 'on')
axis(ax, 'equal')
graphics.axislabels(ax, 'x', 'y')
plotaxes(ax, faceData.Origin, faceData.Frame)
graphics.polar(ax, ...
    unitCircle, faceData.Origin, faceData.Frame, ...
    'Azimuth', phi, ...
    'Color', graphics.rgb.gray(0.5))
% graphics.polar(ax, ...
%     reflectionPattern, faceData.Origin, faceData.Frame, ...
%     'Azimuth', phi, ...
%     'Color', 'red')

[downlinks, ~, trace] = rayoptics.analyze( ...
    faceData, ...
    source.Origin, ...
    sink.Origin, ...
    'ReflectionArities', [0, 1], ...
    'FreeGain', antennae.friisfunction(source.Frequency), ...
    'SourceGain', source.Gain, ... % [dB]
    'ReflectionGain', reflectionGains, ...
    'TransmissionGain', transmissionGains, ...
    'SinkGain', antennae.isopattern(0.0), ... % [dB]
    'Reporting', false);

%%
%% Power distributions
gains = downlinks.GainComponents;
distribution = rayoptics.distributionTable(gains);
disp(struct2table(distribution))

%% Compute gains and display table of interactions
% if options.Reporting
%     
%     fprintf('\nComputed %u paths\n\n', rayoptics.trace.numpaths(trace))
%     
%     startTime = tic;
%     interactionGains = rayoptics.trace.computegain(trace);
%     powerTime = toc(startTime);
%     fprintf('============== computegain: %g sec ==============\n', powerTime)
%     
%     %% Distribution of interaction nodes
%     disp('From stored interaction table')
%     disp(struct2table(rayoptics.trace.frequencies(trace)))
%     
%     %% Distribution of received power
%     [gainStats, gainComponents] = rayoptics.trace.process(trace);
%     disp(struct2table(gainStats))
%     
%     %% Sanity check
%     import datatypes.struct.structsfun
%     assert(max(structsfun( ...
%         @(a,b) norm(a-b,inf), distribution, gainStats)) < tol)
%     assert(isequalfp( ...
%         downlinks.GainComponents, ....
%         gainComponents(:, :, options.Arities + 1)))
%     disp('calculated powers do match :-)')
%     
%     %%
%     fprintf('Timing\n')
%     fprintf('______\n')
%     fprintf(' computing nodes: %g sec\n', traceTime)
%     fprintf(' computing gains: %g sec\n', powerTime)
% end
% 
% %%
% if options.Reporting && options.Serialize
%     numinteractions = datatypes.struct.tabular.height(interactionGains);
%     if 1e6 < numinteractions
%         prompt = sprintf( ...
%             'Proceed to save %d rows to .mat file? {yes | no} ', ...
%             numinteractions);
%         response = input(prompt, 's');
%         switch validatestring(lower(response), {'yes', 'no'})
%             case 'yes'
%                 fprintf('saving results to %s.mat\n', mfilename)
%                 savebig(mfilename, 'interactiongains', 'distribution')
%             case 'no'
%                 fprintf('skipped serialization\n');
%         end
%     end
% end
% 
% %%
% gridp = reshape(gains, [size(gridx), size(gains, 3)]); %#ok<NASGU>
% save([mfilename, 'powers.mat'], ...
%     'gridx', 'gridy', 'gridp', 'scene', ...
%     'argumentlist', 'source')
% iofun.savebig([mfilename, 'trace.mat'], 'trace')
powersum = reshape(sum(gains, 3), size(gridx));
% 
% %% Aggregate power at each receiver (field point)
% if options.Reporting
%     sinkindices = find(interactionGains.InteractionType == rayoptics.NodeTypes.Sink);
%     reportpower = accumarray( ...
%         trace.Data.ObjectIndex(sinkindices), ...
%         interactionGains.TotalGain(sinkindices));
%     reportpower = reshape(reportpower, size(gridx));
%     assert(isequalfp(reportpower, powersum))
%     disp('calculated powers do match :-)')
% end
% 
% if ~options.Plotting
%     return
% end
% 
% if min(size(gridx)) == 1
%     fprintf('Ignoring ''Plotting'' for grid of size %s\n', mat2str(size(gridx)))
%     return
% end

%%
surfc(gridx, gridy, specfun.todb(powersum), 'EdgeAlpha', 0.1)
set(gca, 'DataAspectRatio', [1.0, 1.0, 25])
title('Gain at Receivers (dBW)')
rotate3d on
colorbar
set(gcf, 'PaperOrientation', 'landscape')
view(-35, 25)

%%
if options.Printing
    % Printing to file is *very* time-consuming
    printnow = @(prefix) ...
        print('-dpdf', '-bestfit', ...
        sprintf('%s_%dx%d', prefix, size(gridx, 1), size(gridx, 2)));
    printnow('surf_front')
    view(-125, 15)
    printnow('surf_back')
end

end
