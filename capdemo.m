%%
clear

%%
draw(@min, 1, 'red')
%%
draw(@max, 1, 'yellow')
%%
draw(@min, 2, 'blue')
%%
draw(@max, 2, 'green')
%%
draw(@min, 3, 'cyan')
%%
draw(@max, 3, 'magenta')


function draw(fun, dimension, color)

[temp{1 : 3}] = meshgrid(linspace(0, 1, 5));
vertices = points.meshpoints(temp{:});

clf
hold('on')
grid('on')
points.plot(vertices, 'o')
xlabel('x'); ylabel('y'); zlabel('z')
patch( ...
    'Faces', facevertex.cap(fun, dimension, vertices), ...
    'Vertices', vertices, ...
    'FaceColor', color, ...
    'FaceAlpha', 0.1)
view(3)

end
