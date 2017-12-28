function varargout = runsuite(metaclass, varargin)
import matlab.unittest.TestRunner
import matlab.unittest.TestSuite.fromClass
suite = fromClass(metaclass);
runner = TestRunner.withDefaultPlugins;
cellfun(@runner.addPlugin, varargin)
result = runner.run(suite);
if 0 < nargout
    varargout = {result};
end
