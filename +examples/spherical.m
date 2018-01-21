clear

[azimuth, inclination] = sx.meshgrid( ...
    linspace(0, pi/2, 5), ...
    linspace(0, pi/2, 5));

axis1 = matfun.unit([ 1  1  1]);
axis2 = matfun.unit([-1  1  0]);
axis3 = specfun.cross(axis1, axis2);
frame = cat(3, axis1, axis2, axis3);
origin = [1 1 1];
zero = [0 0 0];

[u, v, w] = specfun.usph2cart(azimuth, inclination);
uvw = points.meshpoints(u, v, w);

%%
figure(1)
clf
hold('on')
points.plot(uvw, 'k.', 'MarkerSize', 10)
graphics.axislabels('u', 'v', 'w')
axis('equal')
grid('on')
view(3)

%%
xyz = points.cart.local2global(frame, uvw);

%%
clf
hold('on')
points.quiver(zero, xyz, 'k.', 'MarkerSize', 10)
points.quiver(zero, axis1, 'r')
points.quiver(zero, axis2, 'g')
points.quiver(zero, axis3, 'b')
axis('equal')
grid('on')
view(3)

