function varargout = local2global(origin, frame, varargin)

[numGlobal, numLocal] = size(frame);

assert(numel(origin) == numGlobal, ...
    'Number of elements of ORIGIN must match number of columns of FRAME.')
assert(numel(varargin) == numLocal, ...
    'A local coordinate array is required for each row of FRAME.')
assert(nargout <= numGlobal, ...
    'Too many outputs for a frame with %u rows', numGlobal)

varargout = cell(1, numGlobal);
for k = 1 : numGlobal
    sum = origin(k);
    for j = 1 : numLocal
        sum = sum + varargin{j}*frame(j, k);
    end
    varargout{k} = sum;
end
