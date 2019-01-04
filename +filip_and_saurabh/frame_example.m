phi = deg2rad(45); % [rad]
inc = deg2rad(30);
[x1, y1, z1] = specfun.sphi2cart(phi, inc, 1);
[x2, y2, z2] = specfun.sphi2cart(phi + pi/2, inc, 1);
[x3, y3, z3] = specfun.sphi2cart(phi + pi/2, inc - pi/2, 1);

origin = [0 0 0];
e1 = [x1 y1 z1];
e2 = [x2 y2 z2];
e3 = [x3 y3 z3];

figure(1); clf; 
points.plot([origin; e1], 'ro-'); hold on
points.plot([origin; e2], 'go-')
points.plot([origin; e3], 'bo-')
grid on
axis('equal')
rotate3d('on')
view(3)
xlabel('x')
ylabel('y')
zlabel('z')

sourceFrame = cat(3, e1, e2, e3);
test = [e1; e2; e3]
mass = test*test'
