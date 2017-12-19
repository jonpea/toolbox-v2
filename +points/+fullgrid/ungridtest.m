function tests = ungridtest
tests = functiontests(localfunctions);
end

function ndgridtest(testcase)

    function check(x0, y0, f)
        [X, Y] = ndgrid(x0, y0);
        Z = f(X, Y);
        [xx, yy, zz] = ungrid(X(:), Y(:), Z(:));
        testcase.verifyEqual(x0(:), xx(:))
        testcase.verifyEqual(y0(:), yy(:))
        testcase.verifyEqual(Z, zz)
    end

x0 = 10 : 14;
y0 = 20 : 26;
f = @(x, y) x + y;

check(x0, y0, f)
check(1, y0, f)
check(x0, 1, f)

end

function meshgridtest(testcase)

    function check(x0, y0, f)
        [X, Y] = meshgrid(x0, y0);
        Z = f(X, Y);
        [xx, yy, zz] = ungrid(X(:), Y(:), Z(:));
        testcase.verifyEqual(x0(:), xx(:))
        testcase.verifyEqual(y0(:), yy(:))
        testcase.verifyEqual(Z.', zz)
    end

x0 = 10 : 14;
y0 = 20 : 26;
f = @(x, y) x + y;

check(x0, y0, f)
check(1, y0, f)
check(x0, 1, f)

end
