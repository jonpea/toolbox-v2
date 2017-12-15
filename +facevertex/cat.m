function varargout = cat(varargin)
%CAT Concatenate face-vertex models.
%   C=FACEVERTEX.CAT(C1,C2,...,CN) with face-vertex representations
%   C1,C2,...CN of N polygon complexes returns a new a new complex C where
%   C.Faces corresponds to [C1.Faces; C2.Faces; ...; CN.Faces].
%
%   Use FACEVERTEX.COMPRESS to reindex connectivity to eliminate possible
%   duplication between the vertices of C1,C2,...,CN.
%
%   See also FACEVERTEX.COMPRESS, CAT, VERTCAT, PATCH.

import facevertex.fv
import facevertex.isfv
import functional.reduce

narginchk(2, nargin)

% Parse optional argument
if ischar(varargin{end})
    padding = varargin{end};
    varargin(end) = [];
else
    padding = 'nan'; % default
end

% Pass primary arguments
if isnumeric(varargin{1})
    assert(mod(numel(varargin), 2) == 0)
    varargin = cellfun(@fv, ...
        varargin(1 : 2 : end), ... % faces
        varargin(2 : 2 : end), ... % vertices
        'UniformOutput', false);
end

% Preconditions
assert(ischar(padding))
assert(all(cellfun(@isfv, varargin)))

% Pad columns of connectivity lists to ensure conformity
switch validatestring(padding, {'nan', 'duplicate'})
    case 'nan'
        padder = @padNaN;
    case 'duplicate'
        padder = @padDuplicate;
end
maxNumColumns = max(cellfun(@(s) size(s.Faces, 2), varargin));
varargin = cellfun( ...
    @(s) padder(s, maxNumColumns), varargin, ...
    'UniformOutput', false);

% Concatenate successive pairs
c = reduce(@catPair, varargin);

varargout = cell(1, max(1, nargout));
[varargout{:}] = fv(c);

end

% -------------------------------------------------------------------------
function c = catPair(a, b)
%CATPAIR Concatenate a single pair of polygon complexes.
import facevertex.fv
c = fv([
    a.Faces;
    b.Faces + size(a.Vertices, 1);
    ], [
    a.Vertices;
    b.Vertices;
    ]);
end

% -------------------------------------------------------------------------
function s = padNaN(s, n)
%PADNAN Pad columns of a connectivity array with NaNs.
%  See also PATCH.
s.Faces(:, end + 1 : n) = nan;
end

% -------------------------------------------------------------------------
function s = padDuplicate(s, n)
%PADDUPLICATE Pads columns of a connectivity array with duplicates.
%   See also PATCH.
m = n - size(s.Faces, 2);
s.Faces(:, end + 1 : n) = repmat(s.Faces(:, end), 1, m);
end
