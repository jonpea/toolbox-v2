function c = dotrows(a, b, varargin)
assert(ismatrix(a))
assert(ismatrix(b))
c = specfun.dot(a, b, 2);
