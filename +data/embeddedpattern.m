function evaluator = embeddedpattern(interpolant)
halfpi = pi/2;
tol = eps(halfpi);
    function result = evaluate(angles)
        narginchk(1, 1)
        assert(ndebug || size(angles, 2) == 2)
        azimuth = angles(:, 1);
        elevation = angles(:, 2);
        assert(ndebug || all(abs(elevation - halfpi) < tol))
        result = interpolant(azimuth);
    end
evaluator = @evaluate;
end

