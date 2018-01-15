function map = faceMapFromTangents(t, varargin)
%FVFRAMES Local coordinate frames for face-vertex representation
% [FRAME,NORMAL,OFFSET,ORIGIN,MAP]=FRAMES(FACES,TANGENTS{:}) returns frame
% data for face-vertex models in the rows of the following arrays:
%
%    MAP(K,:,:) - coefficients of the offset-to-local-coordinates map
%                   that is evaluated as
%                     SQUEEZE(SUM(MAP(K,:,:).*(X-ORIGIN(K,:)), 2))
%

narginchk(1, 2)

% Pre-allocate to ensure results are properly
% dimensioned even when first argument is empty
[numfaces, numdimensions] = size(t);
assert(nargin == numdimensions - 1)
map = zeros(numfaces, numdimensions, numdimensions - 1, 'like', t);

% Split tangent matrices by rows
tangents = cellfun(@(a) num2cell(a, 2), {t, varargin{:}}, 'UniformOutput', false); %#ok<CCAT>

% Compute map for each face and reassemble
map(:, :, :) = cell2mat(cellfun(@makeMap, tangents{:}, 'UniformOutput', false));

% -------------------------------------------------------------------------
function map = makeMap(varargin)
% See workings in comments below.

assert(all(cellfun(@isrow, varargin)))

% Stack tangent vectors into 1x2 or 2x3 matrix
% i.e. "t1(:)" or "[t1(:)'; t2(:)']"
tangents = vertcat(varargin{:}); 

% Workings:
% p(1:n) := vector of global coordinates
% alpha(1:n-1) := vector of local coordinates
% T := tangents'
% p(:) = T*alpha(:) = (Q*R)*alpha(:)
% --> alpha(:) = inv(Q*R)*p(:) = inv(R)*Q'*p(:)
% --> alpha(:)' = p(:)'*(inv(R)*Q')' = p(:)'*(Q/R')
[q, r] = qr(tangents', 0);
map = q/r';

% Reshape for horizontal concatenation 
map = reshape(map, [1, size(map)]);
