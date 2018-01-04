function samples = fvsamples(faces, vertices, u, v)
narginchk(3, 4)
if nargin == 3
    assert(numel(u) == 2)
    [u, v] = deal(u(1), u(2));
end
assert(isscalar(u))
assert(isscalar(v))
[edge1, edge2, origin] = fvtangents(faces, vertices);
samples = origin + edge1*u + edge2*v;
