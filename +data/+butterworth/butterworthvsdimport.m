% function [points, data] = butterworthvsdimport
clear

[faces, vertices, walltypes] = engineeringtower8data3d( ...
    'Convention', 'butterworth') ;

figure(1)
clf('reset')
patch( ...
    'Faces', faces(walltypes == 1, :), ...
    'Vertices', vertices, ...
    'FaceAlpha', 0.1, ...
    'FaceColor', 'blue', ...
    'EdgeColor', 'blue', ...
    'LineWidth', 1)
hold on
patch( ...
    'Faces', faces(walltypes == 2, :), ...
    'Vertices', vertices, ...
    'FaceAlpha', 0.1, ...
    'FaceColor', 'red', ...
    'EdgeColor', 'red', ...
    'LineWidth', 2)
labelpoints(towercoordinates, 0 : 52)

labeldata = level8labels('level8labels-report.xlsx');
locationdata = level8locations('level8locs-report.xlsx');

readinches = @(cs) arrayfun(@(s) sscanf(lower(char(s)), '%f'), cs);
points = [
    readinches(locationdata.XLocation) ...
    readinches(locationdata.YLocation)
    ];

filter = @(extents) extents == '0.06 in';
rxmask = filter(locationdata.Width) & filter(locationdata.Height);
rxpoints = points(rxmask, :);

txmask = strncmp(locationdata.DisplayedText, 'TX', 2);
txpoints = points(txmask, :);

[rxpointsnew, rxlabelsnew] = butterworthrxpositions;

hull = @(x) x(convhull(x), :);
center = @(x) mean(hull(x), 1);

% rxpoints = [rxpoints; center(rxpoints)];
% rxpointsnew = [rxpointsnew; center(rxpointsnew)];
% rxlabelsnew = [rxlabelsnew; 777];

figure(2), clf, hold on
plotpoints(rxpoints, 'x', 'Color', 'blue')
plotpoints(rxpointsnew, 'x', 'Color', 'black')
plotpoints(hull(rxpoints), 'o', 'Color', 'blue')
plotpoints(hull(rxpointsnew), 'o', 'Color', 'black')
axis equal
axis tight

scale = 1.0;
offset = center(rxpoints);
rxpoints = scale*(rxpoints - offset);
txpoints = scale*(txpoints - offset);
rxpointsnew = rxpointsnew - center(rxpointsnew);

figure(3), clf, hold on
plotpoints(rxpoints, 'x', 'Color', 'blue')
plotpoints(rxpointsnew, 'x', 'Color', 'black')
plotpoints(hull(rxpoints), 'o', 'Color', 'blue')
plotpoints(hull(rxpointsnew), 'o', 'Color', 'black')
axis equal
axis tight

scale = 2.8;
rxpoints = scale*rxpoints;
txpints = scale*txpoints;
rxpointsnew = scale*rxpointsnew;

offset = 18.5*repmat(0.5, 1, 2);
rxpoints = rxpoints + offset;
txpoints = txpoints + offset;
rxpointsnew = rxpointsnew + offset;

figure(1)
% Dataset #1
plotpoints(rxpoints, 'o', 'Color', 'blue'), hold on
%labelpoints(rxpoints, 'Color', 'blue'), hold on

plotpoints(txpoints, 's', 'Color', 'blue', 'MarkerFaceColor', 'blue')
labelpoints(txpoints, 'Color', 'blue')

% Dataset #2
plotpoints(rxpointsnew, 'x', 'Color', 'black')
labelpoints(rxpointsnew, rxlabelsnew, 'Color', 'black')

axis equal
axis tight
