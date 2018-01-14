function points = fvbarycentric(faces, vertices, faceid, beta)

narginchk(2, 4)

numdimensions = size(vertices, 2);
[nummeshfaces, numfacevertices] = size(faces);

if nargin < 3 
    faceid = 1 : nummeshfaces;
end

if nargin < 4
    center = cast(1/numfacevertices, class(vertices));
    beta = repmat(center, 1, numfacevertices);
end

numfaces = numel(faceid);

if size(beta, 1) == 1
    beta = repmat(beta, numfaces, 1);
end

assert(size(beta, 1) == numel(faceid))
assert(size(beta, 2) == size(faces, 2))

points = zeros(numfaces, numdimensions);
for i = 1 : numfacevertices
    points = points + vertices(faces(faceid, i), :).*beta(:, i);
end
