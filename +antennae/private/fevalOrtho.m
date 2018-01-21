function result = fevalOrtho(fun, numin, transform, frames, id, xglobal)
xlocal = points.cart.global2local(frames(id, :, :), xglobal);
[x{1 : size(xlocal, 2)}] = elmat.cols(xlocal);
[y{1 : numin}] = transform(x{:});
result = fun(y{:});
