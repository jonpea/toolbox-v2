function tests = frametest
tests = functiontests(localfunctions);
end

function test2d(testcase)

numpoints = 5; % arbitrary integer
v = randn(numpoints, 2);
f = frame(v);

% First frame vector is unit vector of that given
verifyequal(testcase, f(:, :, 1), normalizerows(v))

% Each frame vector has unit length (already tested above)
verifyequal(testcase, normrows(f(:, :, 1)), ones(numpoints, 1))
verifyequal(testcase, normrows(f(:, :, 2)), ones(numpoints, 1))

% Frame vectors are mutually orthogonal
verifyequal(testcase, dotrows(f(:, :, 1), f(:, :, 2)), zeros(numpoints, 1))

end

function test3d(testcase)

numpoints = 5; % arbitrary integer

v = normalizerows(randn(numpoints, 3));

% Use Gram-Schmidt procedure to produce complementary frame vector
w = randn(numpoints, 3);
w = normalizerows(w - dot(v, w, 2).*v);

f = frame(v, w);

% First f vector is unit vector of that given
% NB: Notice the ordering actually employed i.e. "not 1 and 2"
verifyequal(testcase, f(:, :, 3), v)
verifyequal(testcase, f(:, :, 1), w)

% Each frame vector has unit length (already tested above)
allones = ones(numpoints, 1);
verifyequal(testcase, normrows(f(:, :, 1)), allones)
verifyequal(testcase, normrows(f(:, :, 2)), allones)
verifyequal(testcase, normrows(f(:, :, 3)), allones)

% Distinct frame vectors are mutually orthogonal
allzeros = zeros(numpoints, 1);
verifyequal(testcase, dotrows(f(:, :, 1), f(:, :, 2)), allzeros)
verifyequal(testcase, dotrows(f(:, :, 1), f(:, :, 3)), allzeros)
verifyequal(testcase, dotrows(f(:, :, 2), f(:, :, 3)), allzeros)

end

function verifyequal(testcase, actual, expected)
testcase.verifyEqual(actual, expected, 'AbsTol', 1e-14);
end

function result = dotrows(x, y)
result = dot(x, y, 2);
end

function result = normrows(x)
result = sqrt(sum(x.^2, 2));
end

function result = normalizerows(x)
result = bsxfun(@rdivide, x, normrows(x));
end
