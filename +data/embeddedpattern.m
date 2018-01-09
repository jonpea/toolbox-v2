function evaluator = embeddedpattern(interpolant, level)

narginchk(1, 2)

if nargin < 2
    level = 0.0;
end

    function result = evaluate(angles)
        narginchk(1, 1)
        %assert(contracts.ndebug || size(angles, 2) == 2)
        %assert(contracts.ndebug || all(angles(:, 2) == level))
        result = interpolant(angles(:, 1));
    end
evaluator = @evaluate;

end

