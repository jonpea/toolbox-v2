function slices = facegrids(faces, vertices, maketicks)

narginchk(2, 3)
if nargin < 3 || isempty(maketicks)
    maketicks = @defaultmaketicks;
end

assert(size(faces, 2) == 4)
assert(isfunction(maketicks))

[origin, tangents] = fvtotangents(faces, vertices);
normal = unit(cross(tangents{:}, 2), 2);

    function slice = transform(origin, tangent1, tangent2, normal, offset)
        [r, s, t] = ndgrid(maketicks(tangent1), maketicks(tangent2), offset);
        frame = [tangent1(:), tangent2(:), normal(:)];
        xyz = bsxfun(@plus, origin, [r(:), s(:), t(:)]*frame');
        slice = cellfun( ...
            @(a) reshape(a, size(r)), ...
            num2cell(xyz, 1), ...
            'UniformOutput', false);
        %plotpoints(xyz, '.')
    end

generate = @(offset) ...
    cellfun( ...
    @(varargin) transform(varargin{:}, offset), ...
    splitrows(origin), ...
    splitrows(tangents{1}), ...
    splitrows(tangents{2}), ...
    splitrows(normal), ...
    'UniformOutput', false);

offset = 0.01;
slices = [
    generate(+offset);
    generate(-offset);
    ];

end

function ticks = defaultmaketicks(tangent)
density = 20;
numticks = max(ceil(norm(tangent)*density), 3);
ticks = linspace(0.0, 1.0, numticks);
end

function a = splitrows(a) 
a = num2cell(a, 2);
end

