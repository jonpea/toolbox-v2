function [evaluator, interpolant, data] = loadpatternnew(filename, varargin)
assert(ischar(filename))
numcolumns = numel(scanheader(filename));
assert(ismember(numcolumns, 2 : 3))
format = repmat('%f ', 1, numcolumns);
data = loadcolumns(filename, format);
[evaluator, interpolant] = patterninterpolantnew(data, varargin{:});
