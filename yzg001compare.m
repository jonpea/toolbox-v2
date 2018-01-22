%% Comparison of |nelib| and |kakapo|
function yzg001compare(filename)

%%
if nargin < 1 || isempty(filename)
    filename = 'yzg0012dpowers.mat';
end

fprintf('Comparing %s\n', filename)
fprintf('----------------------------\n')

%% Load |nelib| data
fprintf('Loading nelib data...\n')
read = @(name) dlmread(fullfile('.', '+data', name));
nelib.gridx = read('yzg001_x.dat')';
nelib.gridy = read('yzg001_y.dat')';
nelib.gridp = cat(3, ...
    read('yzg001_dir.dat')', ...
    read('yzg001_ref1.dat')', ...
    read('yzg001_ref2.dat')');
nelib.total = sum(nelib.gridp, 3);
disp(nelib)

%% Load |kakapo| data
fprintf('Loading test data from %s...\n', filename)
kakapo = load(filename, 'gridx', 'gridy', 'gridp');
kakapo.total = sum(kakapo.gridp, 3);
disp(kakapo)

%% Visualize received power
figure(1), clf, axis equal
surf(nelib.gridx, nelib.gridy, specfun.todb(nelib.total), 'EdgeAlpha', 0.1)
xlabel('x'), ylabel('y')
title('Received power (dBw)')
rotate3d on

%% Maximum relative error for each reflection arity
relativeerror = @(actual, expected) abs(actual - expected)./abs(expected);
errorwatts = relativeerror(kakapo.gridp, nelib.gridp);
errordb = relativeerror(specfun.todb(kakapo.gridp), specfun.todb(nelib.gridp));
maxover = @(x, dim) max(x, [], dim);
maxreduce = @(x) squeeze(maxover(maxover(x, 1), 2));
maxerrorwatts = maxreduce(errorwatts);
maxerrordb = maxreduce(errordb);
arity = (0 : numel(maxerrorwatts) - 1)';
disp(struct2table(struct( ...
    'Reflections', arity, ...
    'MaxRelativeErrorWatts', maxerrorwatts, ...
    'MaxRelativeErrorDB', maxerrordb)))

%% Visualize distribution of relative errors
figure(2), clf, axis equal
subplot(1, 1 + size(errorwatts, 3), 1)
surf(nelib.gridx, nelib.gridy, specfun.todb(nelib.total), 'EdgeAlpha', 0.1)
axis tight, axis off, view(2)
title('total')
colorbar('Location', 'southoutside')
for i = 1 : size(errorwatts, 3)
    subplot(1, 1 + size(errorwatts, 3), 1 + i)
    surf(nelib.gridx, nelib.gridy, errorwatts(:, :, i), 'EdgeAlpha', 0.1)
    colorbar('Location', 'southoutside')
    axis tight, axis off, view(2)
    title(sprintf('error@%d', i - 1))
end

