%% Demonstrates antenna patterns
function patterndemo

%%
% Two dimensions:
%
% # |F({X, Y})|: grid vectors where |isvector(X)| and |isvector(Y)|
% # |F(X, Y)|: grid matrices where |size(X) == size(Y)|
% # |F(XY)|: unstructured points where |size(XY, 2) == 2|
%
% Similarly, in three dimensions:
%
% # |F({X, Y, Z})|: grid vectors where |isvector(X)|, |isvector(Y)| and |isvector(Z)|
% # |F(X, Y)|: 3-D arrays |X|, |Y|, and |Z| have identical sizes
% # |F(XYZ)|: unstructured points where |size(XYZ, 2) == 3|
%

pattern = @(azimuth, inclination, ~) sx.expand(sin(inclination), azimuth);

azimuth = linspace(0, 2*pi, 50);
inclination = linspace(0, pi, 50);

[azimuth, inclination] = sx.meshgrid(azimuth, inclination);
radius = pattern(azimuth, inclination);

[x, y, z] = sph2cart(azimuth, pi/2 - inclination, radius);

surf(x, y, z, 'FaceColor', 'interp', 'EdgeAlpha', 0.1)
axis('equal')
graphics.axislabels('x', 'y', 'z')
view(3)

pipeline1 = funfun.comp(pattern, @specfun.cart2sphi, @elmat.cols);

    function gain = pipeline2(directions)
        directions = num2cell(directions, 1);
        [azimuth, inclination] = specfun.cart2sphi(directions{:});
        gain = pattern(azimuth, inclination);        
    end

directions = rand(1e6, 3);
run1 = @() pipeline1(directions);
run2 = @() pipeline2(directions);

assert(isequal(run1(), run2()))

fprintf('For %d rows:\n', size(directions, 1))
fprintf('    funfun.comp: %g sec\n', timeit(run1))
fprintf('manual function: %g\n', timeit(run2))

end
