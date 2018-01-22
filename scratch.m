clear
warning('off', 'MATLAB:dispatcher:UnresolvedFunctionHandle')
sRef = load('..\Lrooms2dconcrete.mat');
sNew = load('.\Lrooms2dconcreteNew.mat');
close all

sRef.options = rmfield(sRef.options, 'MultiSource');

compare = @(name) assert(isequal(sRef.(name), sNew.(name)));

compare('options')
compare('gridx')
compare('gridy')
compare('facetofunctionmap')

assert(norm(sRef.powers(:) - sNew.powers(:)) < eps)

for i = 0 : 3
    figure(i + 1), clf
    show(sRef, 1, i)
    show(sNew, 2, i)
end

function show(s, i, arity)

numarities = numel(s.arities);
arityindex = find(s.arities == arity);
if isempty(arityindex)
    arityindex = numarities + 1;
end
powersdb = specfun.todb(s.powers);
%for i = 1 : numarities + 1
ax = subplot(1, 2, i); hold on
if arityindex <= numarities
    temp = powersdb(:, 1, arityindex);
    titlestring = sprintf('arity %d', arity);
else
    temp = specfun.todb(sum(s.powers, 3));
    titlestring = 'total';
end
temp = reshape(temp, size(s.gridx)); % 1st transmitter only
surf(ax, s.gridx, s.gridy, temp, ...
    'EdgeAlpha', 0.0', 'FaceAlpha', 0.9)
caxis(ax, [min(temp(:)), min(max(temp(:)), s.gainthreshold)])
contour(ax, ...
    s.gridx, s.gridy, temp, 10, ...
    'Color', 'white', 'LineWidth', 1)
title(ax, titlestring)
%     patch(ax, ...
%         'Faces', fv3D.Faces(1 : end - 2, :), ...
%         'Vertices', fv3D.Vertices, ...
%         'FaceAlpha', 0.05, ...
%         'EdgeAlpha', 0.3, ...
%         'FaceColor', 'blue');
%     patch(ax, ...
%         'Faces', fv3D.Faces(end - 1 : end, :), ...
%         'Vertices', fv3D.Vertices, ...
%         'FaceAlpha', 0.05, ...
%         'EdgeAlpha', 0.3, ...
%         'FaceColor', 'red');
view(ax, 2)
axis(ax, 'equal', 'off', 'tight')
rotate3d(ax, 'on')
colormap(ax, jet)
colorbar(ax, 'Location', 'southoutside')

end
