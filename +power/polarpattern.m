function pattern = polarpattern(fun, transform, wrap)

narginchk(1, 2)
if nargin < 2
    transform = @elfun.identity;
end
if nargin < 3
    wrap = @wrapcircle;
end

import datatypes.isfunction
assert(isfunction(fun))
assert(isfunction(transform))
assert(isfunction(wrap))

    function result = evaluate(x)
        narginchk(1, 1)
        result = transform(fun(wrap(x)));
    end

pattern = @evaluate;

end
