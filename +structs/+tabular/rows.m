function t = rows(t, rows)
%ROWS Extract row subset of a tabular struct.
%   ROWS(T,ROWS) returns a tabular struct containing a the rows with
%   indices ROWS of tabular struct T.

assert(isstruct(t))

    function a = select(a)
        assert(ndims(a) <= 7)
        a = a(rows, :, :, :, :, :, :);
    end
t = structfun(@select, t, 'UniformOutput', false);

end
