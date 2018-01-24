function xlocal = global2local(frames, xglobal)
xlocal = contract(frames, xglobal, 2);

function c = contract(a, b, dim)
narginchk(3, 3)
c = elmat.squeeze(specfun.dot(a, b, dim), dim);
