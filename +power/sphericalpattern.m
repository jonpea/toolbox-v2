function pattern = sphericalpattern(fun, transform, wrap)

narginchk(1, 2)
if nargin < 2
    transform = @elfun.identity;
end
if nargin < 3
    wrap = @specfun.wrapcircle;
end
import datatypes.isfunction
assert(isfunction(fun))
assert(isfunction(transform))
assert(isfunction(wrap))

    function result = evaluate(x, y)
        narginchk(1, 2)
        if nargin == 1
            if iscell(x)
                % Grid vectors
                assert(numel(x) == 2)
                assert(all(@isvector, x))
                [x, y] = deal(x{1}, x{2}.');
            else
                % Point matrix
                assert(ismatrix(x))
                assert(size(x, 2) == 2)
                [x, y] = deal(x(:, 1), x(:, 2));
            end
        else
            % A grid matrix or a point matrix in multiple columns;
            % hence, nothing to be done here
        end
        result = transform(fun(wrap(x), wrap(y)));
    end

pattern = @evaluate;

end
