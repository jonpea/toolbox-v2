function result = fevalOrtho(fun, numin, transform, frames, id, xglobal)
xlocal = contract(frames(id, :, :), xglobal, 2);
[x{1 : size(xlocal, 2)}] = elmat.cols(xlocal);
[y{1 : numin}] = transform(x{:});
result = fun(y{:});
