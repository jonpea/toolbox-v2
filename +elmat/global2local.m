function varargout = global2local(origin, frame, varargin)

[m, n] = size(frame);

assert(numel(origin) == m, ...
    'Number of elements of ORIGIN must match number of columns of FRAME.')
assert(numel(varargin) == n, ...
    'A local coordinate array is required for each row of FRAME.')
assert(nargout <= n, ...
    'Too many outputs for a frame with %u columns', n)
assert(norm(frame*frame' - eye(m), inf) < 10*eps(class(frame)), ...
    'Rows of FRAME must be mutually orthonormal.')

varargout = cell(1, n);
for k = 1 : m
    sum = zeros('like', frame);
    for j = 1 : n
        sum = sum + (varargin{j} - origin(j))*frame(k, j);
    end
    varargout{k} = sum;
end
