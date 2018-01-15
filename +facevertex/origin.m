function origin = origin(varargin)
[faces, vertices] = facevertex.fv(varargin{:});
origin = vertices(faces(:, 1), :);
