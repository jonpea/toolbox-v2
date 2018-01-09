function tests = angulartocartesiantest
tests = functiontests(localfunctions);
end

function testpolartocartesian(testcase)

% Polar coordinates
numpoints = 20;
theta = linspace(-2*pi, 2*pi, numpoints)'; % column array
rho = rand(size(theta));

% Standard function
[expected.X, expected.Y] = pol2cart(theta, rho);

% Toolbox function
actual.XY = angulartocartesian(theta, rho);

verifyequal(testcase, actual.XY(:, 1), expected.X)
verifyequal(testcase, actual.XY(:, 2), expected.Y)

end

function testsphericaltocartesian(testcase)

% Spherical coordinates
numpoints = 20;
tworevolutions = linspace(-2*pi, 2*pi, numpoints);
[azimuth, elevation, radius] = ndgrid( ...
    tworevolutions, tworevolutions, rand(size(tworevolutions)));
azimuth = azimuth(:);
elevation = elevation(:);
radius = radius(:);

% Built-in function
[expected.X, expected.Y, expected.Z] = sph2cart(azimuth, elevation, radius);

% Toolbox function
inclination = pi/2 - elevation;
[actual.XYZ] = angulartocartesian([inclination, azimuth], radius);

verifyequal(testcase, actual.XYZ(:, 1), expected.X)
verifyequal(testcase, actual.XYZ(:, 2), expected.Y)
verifyequal(testcase, actual.XYZ(:, 3), expected.Z)

end

function verifyequal(testcase, actual, expected)
testcase.verifyEqual(actual, expected, 'AbsTol', 1e-14)
end
