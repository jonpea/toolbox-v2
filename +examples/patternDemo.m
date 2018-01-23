clear

pattern = @(azimuth, inclination, ~) sx.expand(sin(inclination), azimuth);

[azimuth, inclination, r] = sx.ndgrid( ...
    linspace(0, 2*pi, 30), ...
    linspace(0, pi, 15), ....
    1.0);

[azimuth, inclination] = sx.ndgrid(azimuth, inclination);
radius = pattern(azimuth, inclination);

[x, y, z] = funfun.pipe( ...
    {@sph2cart, @specfun.sphi}, ...
    azimuth, inclination, radius);

figure(1), clf('reset')
subplot(1, 2, 1)
surf(x, y, z, 'CData', radius, ...
    'FaceColor', 'interp', 'EdgeAlpha', 0.3)
graphics.axislabels('x', 'y', 'z')
colormap(jet)
axis('equal')
grid('on')
view(3)
colorbar('Location', 'south')

radiusFun = griddedInterpolant({azimuth, inclination}, radius);

[xx, yy, zz] = meshgrid(linspace(-1, 1, 15));
[sphi{1 : 2}] = specfun.cart2sphi(xx, yy, zz);
sphi{3} = radiusFun(sphi{1 : 2});
[xxs, yys, zzs] = specfun.sphi2cart(sphi{:});

sphi{3} = radiusFun(sphi{1 : 2});
[xxxs, yyys, zzzs] = funfun.pipe( ...
    @specfun.sphi2cart, ...
    @(az, inc) deal(az, inc, radiusFun(az, inc)), ...
    @specfun.cart2sphi, ...
    @meshgrid, ...
    linspace(-1, 1, 15));
assert(isequal(xxs, xxxs))
assert(isequal(yys, yyys))
assert(isequal(zzs, zzzs))

subplot(1, 2, 2), hold on
surf(x, y, z, 'FaceColor', 'none', 'EdgeAlpha', 0.3)
scatter3(xxs(:), yys(:), zzs(:), 1, sphi{3}(:))
colormap(jet)
axis('equal')
grid('on')
view(3)
colorbar('Location', 'south')
