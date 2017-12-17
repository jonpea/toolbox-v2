function xfaces = extreme(fun, dim, varargin)

vertices = facevertex.vertices(varargin{:});

%
% Remove specified dimension; if this was not done, then
% resulting set of points would be coplanar, which would result in 
% e.g.
% MATLAB:convhull:EmptyConvhull3DErrId,
% 'Error computing the convex hull. The points may be coplanar or collinear.'
%
others = setdiff(1 : size(vertices, 2), dim);

indices = find(vertices(:, dim) == fun(vertices(:, dim)));
subset = convhull(vertices(indices, others));
xfaces = indices(subset);
