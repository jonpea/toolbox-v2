function m = mirror(x, n, c)
%MIRROR Mirror point relative to affine hull of hyperplane.
% M = MIRROR(X, N, C) is the mirror point of X relative to the hyperplane
%  H = { Y: DOT(N, Y) == C } for normal vector N and scalar offset C.
% The mean point 0.5*(X + M) is the projection of X onto H.
% See also DOT.

% Workings: 
% m = p + (p - x) = 2*p - x ... mirror m, projection p, input point x
% p = x + alpha*n ... projection that satisfies dot(n, p) == c
% --> c == dot(n, p) = dot(n, x + alpha*n) = dot(n, x) + alpha*dot(n, n)
% --> alpha = (c - dot(n, x) / dot(n, n)
% m = 2*(x + alpha*n) - x = x + 2*alpha*n

import contracts.ndebug

narginchk(3, 3)
assert(ndebug || size(x, 1) == size(n, 1) || isrow(x) || isrow(n))
assert(ndebug || size(x, 2) == size(n, 2))
assert(ndebug || isequal(class(x), class(n)))
assert(ndebug || isequal(class(x), class(c)))
assert(ndebug || iscolumn(c))

alpha = (c - dotrows(n, x)) ./ dotrows(n, n);
m = x + 2*alpha.*n;
