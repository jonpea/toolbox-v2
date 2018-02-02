function [faces, vertices] = grid2fv(varargin)
%GRIDTOFV Face-vertex representation of gridded surface

if size(varargin{1}, 3) == 1
    dispatch = @gridtofv2d;
else
    dispatch = @gridtofv3d;
end

[faces, vertices] = dispatch(varargin{:});

end

% -------------------------------------------------------------------------
function [faces, vertices] = gridtofv2d(varargin)

assert(ismember(nargin, [2, 3]))
assert(all(cellfun(@(a) isequal(size(a), size(varargin{1})), varargin)))
assert(ismatrix(varargin{1}))

shape = size(varargin{1});
indices = reshape(1 : prod(shape), shape);
    function result = vertexindices(i, j)
        result = ops.vec(indices(i, j));
    end

lo = @(i) 1 : shape(i) - 1;
hi = @(i) 2 : shape(i);
faces = [
    vertexindices(lo(1), lo(2)) ... % "bottom left"
    vertexindices(hi(1), lo(2)) ... % "bottom right"
    vertexindices(hi(1), hi(2)) ... % "top right"
    vertexindices(lo(1), hi(2)) ... % "top left"
    ];

vertices = cell2mat(cellfun(@(a) a(:), varargin, 'UniformOutput', false));

end

% -------------------------------------------------------------------------
function [faces, vertices] = gridtofv3d(varargin)

narginchk(3, 4)

if nargin == 4
    dimensions = varargin{4};
else
    dimensions = 1 : 3;
end

assert(ndims(varargin{1}) == 3)
assert(all(cellfun( ...
    @(a) isequal(size(a), size(varargin{1})), varargin(1 : 3))))
assert(all(ismember(dimensions, 1 : 3)))

shape = size(varargin{1});

indices = reshape(1 : prod(shape), shape);

nonuniform = {'UniformOutput', false};
faces = cell2mat(arrayfun( ...
    @(dim) facesfordimension(dim, indices), dimensions(:), nonuniform{:}));
vertices = cell2mat(cellfun( ...
    @(a) a(:), varargin(1 : 3), nonuniform{:}));

end

function faces = facesfordimension(dim, indices)

shape = size(indices);
lo = @(dim) 1 : shape(dim) - 1;
hi = @(dim) 2 : shape(dim);
alldims = 1 : shape(dim);
faces = cell2mat(arrayfun(@slice, alldims(:), 'UniformOutput', false));

    function faces = slice(i)
        corner = @(varargin) ops.vec(vertexindices(i, varargin{:}));
        faces = [
            corner(lo, lo) ... % "bottom left"
            corner(hi, lo) ... % "bottom right"
            corner(hi, hi) ... % "top right"
            corner(lo, hi) ... % "top left"
            ];
    end

    function slice = vertexindices(index, range1, range2)
        otherdims = setdiff(1 : 3, dim);
        subscripts = substruct('()', ...
            insert(index, dim,  ...
            range1(otherdims(1)), ...
            range2(otherdims(2))));
        slice = subsref(indices, subscripts);
    end

end

function result = insert(item, at, varargin)
% Insert ITEM into vector INTO at index AT in [1, numel(INTO) + 1].
n = numel(varargin) + 1;
result = cell(1, n);
result(setdiff(1 : n, at)) = varargin;
result{at} = item;
end
