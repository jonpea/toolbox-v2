function c = contract(a, b, dim)
narginchk(3, 3)
c = elmat.squeeze(specfun.dot(a, b, dim), dim);
