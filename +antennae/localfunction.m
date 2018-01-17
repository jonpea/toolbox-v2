function handle = localfunction(fun, frames, transform, numin)

narginchk(2, 4)

if nargin < 3
    transform = spectun.cart2sphi;
end

if nargin < 4
    options = [nargin(fun), nargout(transform), size(transform, 3)];
    numin = options(find(0 < options, 1, 'first'));
end

assert(datatypes.isfunction(fun) || isobject(fun))
assert(isnumeric(numin) && isscalar(numin) && 0 < numin)
assert(datatypes.isfunction(transform))
assert(isnumeric(frames))

numlocal = size(frames, 3);
    function result = evaluate(id, xglobal)
        xlocal = contract(frames(id, :, :), xglobal, 2);
        [x, y] = deal(cell(1, numlocal));
        [x{:}] = elmat.cols(xlocal);
        [y{:}] = transform(x{:});
        result = fun(y{1 : numin});
    end
handle = @evaluate;

end

function c = contract(a, b, dim)
narginchk(3, 3)
c = elmat.squeeze(specfun.dot(a, b, dim), dim);
end
