function varargout = compress(varargin)
%COMPRESS Remove redundant vertices from a face-vertex representation.

import facevertex.fv

narginchk(1, 2)

% Parse argument list
[faces, vertices] = fv(varargin{:});

% Drop unused vertices
[select, ~, map] = unique(faces(:));
faces(:) = map(:);
vertices = vertices(select, :);

% Re-map vertex indices
[vertices, ~, map] = unique(vertices, 'rows');
faces(:) = map(faces(:));

% Pack output arguments
varargout = cell(1, max(1, nargout));
[varargout{:}] = fv(faces, vertices);
