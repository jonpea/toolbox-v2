function newshape = sxshape(a, positions, numdims)
%SXSHAPE Singleton eXpansion shape.
%   SXSHAPE(A,POS,N) returns the size of array A suitable for use 
%   in an expression that relies on singleton expansion.
%
%   See also SXRESHAPE.
narginchk(2, 3)
if nargin < 3 || isempty(numdims)
    numdims = max(positions(:));
end
assert(isequal(unique(positions), positions))
assert(all(1 <= diff(positions)))
assert(max(positions(:)) <= numdims)
[shape{1 : numel(positions)}] = size(a); % handles trailing 1s
newshape = ones(1, numdims);
newshape(positions) = cell2mat(shape);

