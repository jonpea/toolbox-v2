function xglobal = local2global(frames, xlocal)
xglobal = sum(frames .* sx.reshape(xlocal, [1 3]), 3);
