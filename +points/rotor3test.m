function tests = rotor3dtest
tests = functiontests(localfunctions);
end

function test(testcase)

    function verifyequal(actual, expected)
        testcase.verifyEqual(actual, expected, 'AbsTol', 1e-14);
    end

angle = rand;
orientation = rand(1, 3); % row vector

% NB: Test requires that input is orthogonal to axis of rotation
preimage = sum(null(orientation(:)'), 2)';

rotor = rotor3d(orientation, angle);
image = preimage*rotor;

% Rotation matrix is orthogonal
verifyequal(rotor'*rotor, eye(3))
verifyequal(norm(image), norm(preimage))

% Rotation preserves angle relative to axis of rotation
verifyequal( ...
    dot(orientation, image), ...
    dot(orientation, preimage))
verifyequal(orientation*rotor, orientation)

% Rotation is through the angle specified
verifyequal(subspace(preimage(:), image(:)), angle) % Cosine Rule

end

function x = unit(x)
x = x/norm(x);
end
