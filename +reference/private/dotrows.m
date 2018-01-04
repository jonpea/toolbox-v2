function c = dotrows(a, b, varargin)
assert(ismatrix(a))
assert(ismatrix(b))
c = matfun.dot(a, b, 2);
