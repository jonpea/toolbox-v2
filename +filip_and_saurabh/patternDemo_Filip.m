function patternDemo_Filip

clear

%% Gain pattern
c = 3d8;
f = 2.45d9;
Lambda = c/f;

thetaThreshold = 0.3*pi;
scaling = 0.1;

L = 0.49*(Lambda/sqrt(2.2));
W = 2.7*L;
k = (2*pi)/Lambda;

pattern = @(phi, theta, ~) ((sin((W*k/2).*sin(phi).*sin(theta)))./((W*k/2).*sin(phi).*sin(theta))) .* cos((L*k/2).*sin(theta).*cos(phi));

% Note (1): This is just to double-check "pattern", above...
    function radius = patternCheck(phi, theta, ~)
        sinsin = 0.5*k*W*sin(theta).*sin(phi);
        sincos = 0.5*k*L*sin(theta).*cos(phi);
        radius = (sin(sinsin)./sinsin) .* cos(sincos);
        mask = thetaThreshold < theta;
        radius(:, mask) = scaling.*((theta(mask)./pi).*radius(:, mask));
    end

%%

% Note (2): I have made two changes here:
% i. Adjusted the bounds on the sampling intervals by "delta" 
%   to prevent the 0/0 discussed in my email.
% ii. Changed the upper limit on theta (inclination) from pi to 0.5*pi 
%     for direct comparison with the reference plot in your email.
delta = 0.001;
[phi, theta, r] = sx.ndgrid( ...
    linspace(0 + delta, 2*pi - delta, 100), ... % azimuth
    linspace(0 + delta, pi - delta, 100), .... % inclination
    1.0);

%[azimuth, inclination] = sx.ndgrid(azimuth, inclination);
radius = pattern(phi, theta);

% ... Note (1) continued: Here we've verified that the formulae match
mask = thetaThreshold < theta;
radius(:, mask) = 1e-1.*((theta(mask)./pi).*radius(:, mask));
same = @(x, y) norm(x(:) - y(:)) < 1e-14;
assert(same(radius, patternCheck(phi, theta)))

[x, y, z] = funfun.pipe( ...
    {@sph2cart, @specfun.sphi}, ...
    phi,theta,radius);

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

radiusFun = griddedInterpolant({phi, theta}, radius);

[xx, yy, zz] = meshgrid(linspace(-1, 1, 15));
[sphi{1 : 2}] = specfun.cart2sphi(xx, yy, zz);
sphi{3} = radiusFun(sphi{1 : 2});
[xxs, yys, zzs] = specfun.sphi2cart(sphi{:});

sphi{3} = radiusFun(sphi{1 : 2});
[xxxs, yyys, zzzs] = funfun.pipe( ...
    @specfun.sphi2cart, ...
    @(phi, theta) deal(phi, theta, radiusFun(phi, theta)), ...
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

end
