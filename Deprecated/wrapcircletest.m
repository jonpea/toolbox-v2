function tests = wrapcircletest
tests = functiontests(localfunctions);
end

function test(testcase)

% Our interval is [0, full)
full = 1 + rand; % an arbitrary non-zero value

    function verifyequal(input, expected)
        testcase.verifyEqual( ...
            wrapcircle(input, full), ...
            expected, ...
            'AbsTol', 1e-14);
    end

% Limits
verifyequal(0.0, 0.0)
verifyequal(full, 0.0)

% Interval
delta = 10*eps(full);
interval = linspace(0, full - delta); % i.e. [0, full)
verifyequal(interval, interval)

% Wrapping
verifyequal(interval + full, interval)
verifyequal(interval + 2*full, interval)

end
