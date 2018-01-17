function handle = orthofunction(fun, frames, transform, numin)
narginchk(4, 4)
    function result = evaluate(id, xglobal)
        result = fevalOrtho(fun, numin, transform, frames, id, xglobal);
    end
handle = @evaluate;
end
