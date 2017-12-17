function tabular = tabularrows(tabular, rows)
%TABULARROWS Extract row subset of a tabular struct
% TABULARROWS(T,ROWS) returns a tabular struct containing a subset of the
% rows of tabular struct T that is specified in the array of roaw
assert(isstruct(tabular))
allsingleton = tabularsize(tabular) == 1;
    function field = select(field)
        assert(ndims(field) <= 4)
        if ~issingleton(field) || allsingleton
            field = field(rows, :, :, :);
        end
    end
tabular = structfun(@select, tabular, 'UniformOutput', false);
end

function result = issingleton(x)
result = size(x, 1) == 1;
end
