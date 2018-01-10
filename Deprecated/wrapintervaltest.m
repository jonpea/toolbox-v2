function tests = wrapintervaltest
tests = functiontests(localfunctions);
end

function test(testcase)

% Our interval is [lower, upper)
lower = -rand;
upper = rand;

    function verifyequal(input, expected)
        testcase.verifyEqual( ...
            wrapinterval(input, lower, upper), ...
            expected, ...
            'AbsTol', 1e-12);
    end

% Limits
verifyequal(lower, lower)
verifyequal(upper, lower)

% Interval
width = upper - lower;
delta = 10*eps(width);
interval = linspace(lower, upper - delta);
verifyequal(interval, interval)

% Wrapping
verifyequal(interval - 2*width, interval)
verifyequal(interval - width, interval)
verifyequal(interval + width, interval)
verifyequal(interval + 2*width, interval)

end