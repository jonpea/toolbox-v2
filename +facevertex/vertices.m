function v = vertices(f, v)

narginchk(1, 2)

if nargin == 1
    if isstruct(f)
        v = f.Vertices;
    elseif isnumeric(f)
        v = f;
    end
end
