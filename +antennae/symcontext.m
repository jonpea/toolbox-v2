function handle = symcontext(normals)
%SYMCONTEXT Functions invariant under rotation about surface normal.
narginchk(1, 1)
    function result = feval(fun, id, xglobal)
        xunit = matfun.unit(xglobal, 2);
        dot = specfun.dot(normals(id, :), xunit, 2);
        angle = acos(min(abs(dot), 1));
        result = fun(angle);
    end
handle = @feval;
end
