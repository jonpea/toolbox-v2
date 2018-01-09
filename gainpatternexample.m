%% Visualisation of gain patterns

%% Antenna patterns
present('isotropic_one.txt')

%%
present('halfwavedipole.txt')

%%
present('shortdipole.txt')

%%
% Radiation pattern of the patch antenna placed on a wall
% *NB* For reliable interpolation, the missing samples at
% $\phi = 360^\circ$ should be copied from $\phi = 0^\circ$.
present('farfield_patch_centre_cavitywall_timber_extract.txt')

%% Transmission coefficients
present('trans_TM_Wall_3.txt')
%%
present('trans_TE_Wall_3.txt')

%% Reflection coefficients
present('refl_TM_Wall_3.txt')
%%
present('refl_TE_Wall_3.txt')

%%
% NB: This is a work-around to force capture of plot above - 
% do not delete this line.
disp('Finished')

%%
function present(filename)

opacity = {'EdgeAlpha', 0.1, 'FaceAlpha', 1.0};

filepath = fullfile('.', '+data', filename);
columndata = data.loadcolumns(filepath, '%f %f %f');

polar = deg2rad(columndata.theta);
azimuth = deg2rad(columndata.phi);

% data = loadpattern(filepath);
% polar = resample(data.Theta);
% azimuth = resample(data.Phi);
% interpolant = griddedInterpolant( ...
%     {data.Theta, data.Phi}, data.Gain);
% radius = interpolant({polar, azimuth});

interpolant1 = data.loadpattern(filepath);
[polar1, azimuth1] = ndgrid(resample(polar), resample(azimuth));
radius1 = interpolant1(polar1, azimuth1);
% assert(norm(radius(:) - radius1(:), inf) < 1e-12)


interpolant2 = @(theta, phi) ...
    interpolant1(wrapquadrant(theta), wrapquadrant(phi));
[polar2, azimuth2] = ndgrid( ...
    linspace(0.0, pi, 360), ... % polar angles
    linspace(0.0, pi, 360)); % azimuthal angles
radius2 = reshape(interpolant2(polar2, azimuth2), size(polar2));

subplot(2, 1, 1)
graphics.spherical(radius1, azimuth1, polar1, opacity{:})
title('Sub-sampled every 1 degree')
labelaxes('x', 'y', 'z')
minradius = min(columndata.gain(:));
maxradius = max(columndata.gain(:));
if abs(minradius - maxradius) <= eps*(abs(maxradius) + 1)
    minradius = minradius - 0.5;
    maxradius = maxradius + 0.5;
end
caxis([minradius, maxradius])
colormap(jet)
colorbar('Location', 'east')
axis equal
rotate3d on
view(3)

subplot(2, 1, 2)
graphics.spherical(radius2, azimuth2, polar2, opacity{:})
title('Wrapped through quadrants')
labelaxes('x', 'y', 'z')
axis equal
rotate3d on
view(3)

input('Press enter to continue', 's');

end

function x = resample(x)
x = linspace(min(x), max(x), 361);
end
