function [faces, vertices, varargin] = parseFaceVertexPair(varargin)

import facevertex.fv

[pair, varargin] = parseFaceVertexPairs(1, varargin{:});
[faces, vertices] = fv(pair{:});
