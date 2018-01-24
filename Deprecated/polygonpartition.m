function [in, on] = polygonpartition(indices, vertices, points)

narginchk(3, nargin)
assert(iscell(indices))
assert(all(cellfun(@isnumeric, indices)))
assert(size(vertices, 2) == 2)
assert(size(points, 2) == 2)

    function [in, on] = query(indices)
        [in, on] = inpolygon( ...
            points(:, 1), ...
            points(:, 2), ...
            vertices(indices, 1), ...
            vertices(indices, 2));
    end

[in, on] = cellfun(@query, indices, 'UniformOutput', false);

in = flatten(in);
on = flatten(on);

end

function a = flatten(c)
a = cellfun(@(row) row(:)', c, 'UniformOutput', false);
end
