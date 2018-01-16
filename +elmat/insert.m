function a = insert(a, loc, b)
%INSERT Insert elements into an array.
%   INSERT(A,LOC,B) inserts the elements of array B into
%   array A at the locations specified in LOC.
%
%   A should be one-dimensional. Use RESHAPE if a necessary.
%
%   A and B must be of mututally compatible classes
%   e.g. both logical, both numeric, or both cell arrays.
%
%   Array LOC may be logical with SIZE(A) or numeric with SIZE(B):
%   1. If logical, SUM(LOC) must match NUMEL(B) unless B is scalar;
%   2. If numeric, NUMEL(LOC) must match NUMEL(B) unless B is scalar.
%
%   In case (2), LOC must not contain duplicate elements.
%
%   Examples:
%   >> elmat.insert([1 2 3], 1, 0)
%   ans =
%        0     1     2     3
%   >> elmat.insert([1 2 3], 3, 0)
%   ans =
%        1     2     0     3
%   >> elmat.insert([1 2 3], 4, 0)
%   ans =
%        1     2     3     0
%   >> elmat.insert([2 4 6], [1 2 3], [100 300 500])
%   ans =
%      100     2   300     4   500     6
%   >> elmat.insert({2 4 6}, [1 2 3], {100 300 500})
%   ans =
%     1×6 cell array
%     Columns 1 through 6
%       {[100]}  {[2]}  {[300]}  {[4]}  {[500]}  {[6]}
%
%   See also ACCUMARRAY, RESHAPE, SUB2IND, IND2SUB.

narginchk(3, 3)

if isnumeric(loc)
    % Must sort before cumulative offsets are added [**]
    [loc, permutation] = sort(loc(:));
    b = b(permutation); % preserve correspondence
else
    assert(islogical(loc))
    assert(numel(loc) == numel(a))
    loc = find(loc)'; % NB: Already sorted
end

assert(numel(loc) == numel(b) || isscalar(b))

newloc = loc(:)' + (0 : numel(loc) - 1); % [**] cumulative offsets
newlength = numel(a) + numel(b);
oldloc = setdiff(1 : newlength, newloc);

[a(oldloc), a(newloc)] = deal(a, b);
