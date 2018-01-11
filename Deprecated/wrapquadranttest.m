function tests = wrapquadranttest
tests = functiontests(localfunctions);
end

function test(testcase)

full = 1 + rand; % an arbitrary non-zero value

    function verifyequal(input, expected)
        testcase.verifyEqual( ...
            specfun.wrapquadrant(input, full), ...
            expected, ...
            'AbsTol', 1e-14);
    end

zero = 0.0;
half = full/2;
quarter = full/4;

% Limits
verifyequal(zero, zero)
verifyequal(quarter, quarter)
verifyequal(half, zero)
verifyequal(1.5*half, quarter)
verifyequal(full, zero)

% Interval
interval = linspace(0.0, quarter);
verifyequal(interval, interval)

% Wrapping
verifyequal(interval + quarter, fliplr(interval))

end
