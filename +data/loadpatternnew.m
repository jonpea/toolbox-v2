function [evaluator, interpolant, columns] = loadpatternnew(filename, varargin)
assert(ischar(filename))
numcolumns = numel(data.scanheader(filename));
assert(ismember(numcolumns, 2 : 3))
format = repmat('%f ', 1, numcolumns);
columns = data.loadcolumns(filename, format);
[evaluator, interpolant] = data.patterninterpolantnew(columns, varargin{:});
