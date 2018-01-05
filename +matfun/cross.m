function c = cross(a, b, dim)
%CROSS  Vector cross product (with singleton expansion).
%   C = CROSS(A,B) returns the cross product of the vectors
%   A and B.  That is, C = A x B.  A and B must be 3 element
%   vectors.
%
%   C = CROSS(A,B) returns the cross product of A and B along the
%   first dimension of length 3.
%
%   C = CROSS(A,B,DIM), where A and B are N-D arrays, returns the cross
%   product of vectors in the dimension DIM of A and B. A and B must
%   have the same size, and both SIZE(A,DIM) and SIZE(B,DIM) must be 3.
%
%   See also DOT.

narginchk(2, 3)

import contracts.msgid

shape = sx.sizesx(a, b);

if nargin < 3
    dim = find(shape == 3, 1, 'first');
    if isempty(dim)
        error(msgid(mfilename, 'InvalidDimAorB'), ...
            'A and B must have at least one dimension of length 3.')
    end
end

assert(isscalar(dim) && isnumeric(dim) && 1 <= dim)

if all([size(a, dim), size(b, dim)] ~= 3)
    error(msgid(mfilename, 'InvalidDimAorBForCrossProd'), ...
        'A and B must be of length 3 in the dimension in which the cross product is taken.')
end

complement = setdiff(1 : numel(shape), dim);
split = @(x) num2cell(x, complement);

a = split(a);
b = split(b);

c{1} = a{2}.*b{3} - a{3}.*b{2};
c{2} = a{3}.*b{1} - a{1}.*b{3};
c{3} = a{1}.*b{2} - a{2}.*b{1};

c = cat(dim, c{:});
