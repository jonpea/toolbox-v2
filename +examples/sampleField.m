%% Sampling a discrete field along a line of interest

%%
clear

%% Discrete gain data (completely synthetic)
[x, y] = deal(linspace(0, 2*pi, 20));
z = sin(x(:)).*cos(y(:)');

figure(1), clf, hold on, grid on
surf(x, y, z, ...
    'EdgeAlpha', ...
    0.1, 'FaceAlpha', 0.5)
xlabel('x')
ylabel('y')
zlabel('z (gain)')
title('3-D visualization')
view(3)
rotate3d on

%% A piecewise linear interpolant of the gain samples
interpolant = griddedInterpolant({x, y}, z);

%% A line of interest (between "from" and "to")
from = [1, 1];
to = [5, 5];
line = @(t) from + t(:).*(to - from);

plot(from(1), from(2), 'o')
plot(to(1), to(2), 'x')

%% Fine sampling grid along the line of interest
tt = linspace(0, 1, 200);
temporary = line(tt);
xx = temporary(:, 1);
yy = temporary(:, 2);

plot(xx, yy, 'r-')

%% Samples of linear interpolant on line of interest
zz = interpolant(xx, yy);

plot3(xx, yy, zz, 'k-')

figure(2), clf, hold on, grid on
plot(tt, zz)
xlabel('t (along line)')
ylabel('z (gain)')
title('2-D visualization')
