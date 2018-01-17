function handle = orthocontext(frames, transform, numin)

narginchk(1, 3)

if nargin < 2
    transform = @specfun.cart2usphi;
end
if nargin < 3
    numin = nargout(transform);
    assert(0 < numin, ...
        'The number of intrinsic coordinates could not be inferred.')
end

    function result = feval(fun, id, xglobal)
        result = fevalOrtho(fun, numin, transform, frames, id, xglobal);
    end
handle = @feval;

end
