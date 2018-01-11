function tests = rotor2dtest
tests = functiontests(localfunctions);
end

function test(testcase)

    function verifyequal(actual, expected)
        testcase.verifyEqual(actual, expected, 'AbsTol', 1e-14);
    end

angle = rand;
preimage = rand(1, 2);
rotor = rotor2d(angle);
image = preimage*rotor;

% Rotation matrix is orthogonal
verifyequal(rotor'*rotor, eye(2))
verifyequal(norm(image), norm(preimage))

% Rotation is through the angle specified
verifyequal(subspace(preimage(:), image(:)), angle) % Cosine Rule

end
