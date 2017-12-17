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

import scattered.plot
import facevertex.cap

[temp{1 : 3}] = meshgrid(linspace(0, 1, 5));
vertices = scattered.meshpoints(temp{:});

clf
hold('on')
grid('on')
scattered.plot(vertices, 'o')
xlabel('x'); ylabel('y'); zlabel('z')
patch( ...
    'Faces', cap(fun, dimension, vertices), ...
    'Vertices', vertices, ...
    'FaceColor', color, ...
    'FaceAlpha', 0.1)
view(3)

end
