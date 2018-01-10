function c = fvfaces(c)
%FVFACES "Ragged" faces array for non-homogeneous polygonal patches.
% See also PATCH.

narginchk(1, 1)

if isnumeric(c) && ismatrix(c)
    return
end

assert(iscell(c) && isvector(c))
assert(~any(cellfun(@isempty, c)))
assert(all(cellfun(@isrow, c)))

maxnumcolumns = max(cellfun(@(a) size(a, 2), c));
    function a = pad(a)
        a(:, end + 1 : maxnumcolumns) = nan;
    end
c = cell2mat(cellfun(@pad, c(:), 'UniformOutput', false));

end
