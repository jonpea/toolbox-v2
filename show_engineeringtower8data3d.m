clear
[faces, vertices, types] = data.engineeringtower8data3d('WithFloor', true, 'WithCeiling', true);
if numel(unique(types)) < 4
    warning('We are only plotting four material types in the code below')
end
figure, hold on
alpha = 0.1; 
patch('Faces', faces(types == 1, :), 'Vertices', vertices, 'FaceColor', 'blue', 'FaceAlpha', alpha)
patch('Faces', faces(types == 2, :), 'Vertices', vertices, 'FaceColor', 'red', 'FaceAlpha', alpha)
patch('Faces', faces(types == 3, :), 'Vertices', vertices, 'FaceColor', 'green', 'FaceAlpha', alpha)
patch('Faces', faces(types == 4, :), 'Vertices', vertices, 'FaceColor', 'cyan', 'FaceAlpha', alpha)
view(3)
axis('equal')
rotate3d('on')
grid('on')
xlabel('x')
ylabel('y')
zlabel('z')
