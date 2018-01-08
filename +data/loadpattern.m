function [evaluator, interpolant, columndata] = loadpattern(filename, varargin)
assert(ischar(filename))
numcolumns = numel(data.scanheader(filename));
assert(ismember(numcolumns, 2 : 3))
format = repmat('%f ', 1, numcolumns);
columndata = data.loadcolumns(filename, format);
[evaluator, interpolant] = data.patterninterpolant(columndata, varargin{:});
