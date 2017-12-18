function h = height(t)
%HEIGHT Number of rows in a table.
%   H = STRUCTS.HEIGHT(T) returns the number of rows in the table T.
%   If T is a structure array, compute the height of each element using
%   e.g. 
%   >> heights = arrayfun(@height, t)
%
%   See also WIDTH.

assert(isstruct(t))
assert(isscalar(t))

h = heights(t);

assert(numel(h) <= 1, ...
    'Invalid tabular struct: Fields do hot have uniform row size.')

if isempty(h)
    h = 0; % "struct with no fields has zero height"
end
