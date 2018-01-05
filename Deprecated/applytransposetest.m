function tests = applytransposetest
tests = functiontests(localfunctions);
end

function test(testcase)
numpoints = 10;
testcase.TestData.Test(numpoints, 2);
testcase.TestData.Test(numpoints, 3);
testcase.TestData.Test(numpoints, 4);
end

function setupOnce(testcase)
testcase.TestData.Test = @generictest;
    function generictest(numpoints, numdimensions)
        random = @(varargin) randi([-10, 10], varargin{:});
        a = random(numpoints, numdimensions, numdimensions);
        x = random(numpoints, numdimensions);
        yactual = applytranspose(a, x);
        yexpected = zeros(size(x));
        for k = 1 : numpoints
            yexpected(k, :) = x(k, :)*reshape(a(k, :, :), numdimensions, []);
        end
        testcase.verifyEqual(yactual, yexpected);
    end
end
