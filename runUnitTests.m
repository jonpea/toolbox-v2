function runUnitTests(verbosity)

if nargin < 1
    verbosity = matlab.unittest.Verbosity.Terse; % i.e. "1"
end

    function run(suite)
        import matlab.unittest.plugins.TestRunProgressPlugin
        unittest.runsuite( ...
            suite, ...
            TestRunProgressPlugin.withVerbosity(verbosity));
    end

run(?elfun.UnitTests)
run(?elmat.UnitTests)
run(?matfun.UnitTests)
run(?rayoptics.UnitTests)
run(?reference.UnitTests)
run(?specfun.UnitTests)
run(?sx.UnitTests)

end
