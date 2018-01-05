function b = perp(a, dim)
%PERP Orthogonal complements of a matrix of 2-vectors.
%   B=PERP(A,DIM) satisfies, in the absence of rounding error,
%       ALL(DOT(A,B,DIM) == 0),
%   and NORM(A,2,DIM) == NORM(B,2,DIM).
%
%  PERP(A) acts along the first dimension of length 2.
%
%  For each 2-vector V in A, PERP(V) corresponds to the first two
%  components of the cross product CROSS([
%
% See also CROSS.

narginchk(1, 2)

ashape = size(a);

if nargin < 2
    dim = find(ashape == 2, 1, 'first');
    if isempty(dim)
        error(msgid(mfilename, 'InvalidDim'), ...
            'A must have at least one dimension of length 2.')
    end
end

assert(isscalar(dim) && isnumeric(dim) && 1 <= dim)

if size(a, dim) ~= 2
    error(msgid(mfilename, 'InvalidDimForPerp'), ...
        'A must be of length 2 in the dimension in which the complement is taken.')
end

three = 3;

% Subscripts selecting the 3rd position of dimension DIM
indices = repmat({':'}, 1, ndims(a));
indices{dim} = three;
third = substruct('()', indices);

% A singleton instance of the "vertical" vector [0 0 1], 
% i.e. the unit normal to the 2-D plane
if isempty(a)
    elements = [];
else
    elements = [0, 0, 1];
end
vshape = ones(size(ashape)); % singleton in all dimensions...
vshape(ashape == 0) = 0; % ... excepting zero dimensions
vshape(dim) = three; % ... and the target dimension
v = reshape(cast(elements, class(a)), vshape);

% Pad third element in dimension DIM with zeros
aa = subsasgn(a, third, zeros('like', a));

% Cross produce exploiting singleton expansion
bb = matfun.cross(v, aa, dim);

% Drop the third element from the result
b = subsasgn(bb, third, []);
