function varargout = rununittests(verbosity)
if nargin < 1
    verbosity = 1;
end
import matlab.unittest.plugins.TestRunProgressPlugin
[varargout{1 : nargout}] = unittest.runsuite( ...
    ?sx.UnitTests, ...
    TestRunProgressPlugin.withVerbosity(verbosity));