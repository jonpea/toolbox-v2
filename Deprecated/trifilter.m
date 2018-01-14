function [selected, uv] = trifilter(tri, faceid, projection)
%TRIFILTER True where projections lie in facets of a triangulation.
% S = TRIFILTER(TRI, FACEID, P) returns a logical column vector S such 
% that S(K) is true if and only if P(K,:) lies in facet FACEID of 
% triangulation TRI.
% See also TRIANGULATION.

narginchk(3, 3)

% Pre-conditions
assert(ndebug || isa(tri, 'triangulation'))
assert(ndebug || size(faceid, 1) == size(projection, 1))
assert(ndebug || ismember(size(projection, 2), 2 : 3))

% Barycentric coordinates of 
uv = tri.cartesianToBarycentric(faceid, projection);

% Sanity check
% Note that 'triangulation' currently (R2017b) only supports double
assert(ndebug || isa(tri.Points, 'double'))
assert(ndebug || all(abs(sum(uv, 2) - 1) <= eps))

% Select points within the unit simplex.
% Note: It is unnecessary to check "no values exceed 1" since 
% "sum(barycentric coordinates) == 1" implies that at least one negative
% coordinate would result if one coordinate exceeds one.
selected = all(0 <= uv, 2);
