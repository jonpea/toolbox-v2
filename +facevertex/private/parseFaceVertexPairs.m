function [pairs, varargin] = parseFaceVertexPairs(n, varargin)

import facevertex.fv

narginchk(1, nargin)
assert(1 <= n) % required for output to have correct fields

numArguments = numel(varargin);

if isnumeric(varargin{1})
    % Face-vertex matrix pairs
    assert(2*n <= numArguments)
    indices = 1 : 2*n;
    pairs = cellfun(@fv, ...
        varargin(indices(1 : 2 : end)), ...
        varargin(indices(2 : 2 : end)), ...
        'UniformOutput', false);
else
    % Struct or patch object
    assert(n <= numArguments)
    indices = 1 : n;
    pairs = varargin(indices);
end

varargin(indices) = [];
