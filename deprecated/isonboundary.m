function result = isonboundary(uv, tol)

if nargin < 2 || isempty(tol)
    tol = 10*eps(class(uv));
end

% Third barycentric coordinate
% * "beta1 + beta2 <= 1": point lies in SW triangle
% * "beta1 + beta2 >= 1": point lies on NE triangle
% * "beta1 + beta2 == 0": point lies on SW-NE diagonal
uv(:, 3) = abs(1 - sum(uv, 2));

    function result = testrows(op, target)
        result = abs(op(uv, [], 2) - target) < tol;
    end

result = testrows(@min, 0.0) | testrows(@max, 1.0);

end