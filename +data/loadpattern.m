function [evaluator, interpolant, data] = loadpattern(filename, varargin)
assert(ischar(filename))
numcolumns = numel(scanheader(filename));
assert(ismember(numcolumns, 2 : 3))
format = repmat('%f ', 1, numcolumns);
data = loadcolumns(filename, format);
[evaluator, interpolant] = patterninterpolant(data, varargin{:});
