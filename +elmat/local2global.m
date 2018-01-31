function varargout = local2global(origin, frame, varargin)

[m, n] = size(frame);

assert(numel(origin) == m, ...
    'Number of elements of ORIGIN must match number of columns of FRAME.')
assert(numel(varargin) == n, ...
    'A local coordinate array is required for each row of FRAME.')
assert(nargout <= m, ...
    'Too many outputs for a frame with %u rows', m)
assert(norm(frame*frame' - eye(m), inf) < 10*eps(class(frame)), ...
    'Rows of FRAME must be mutually orthonormal.')

varargout = cell(1, m);
for k = 1 : m
    sum = origin(k);
    for j = 1 : n
        sum = sum + varargin{j}*frame(j, k);
    end
    varargout{k} = sum;
end
