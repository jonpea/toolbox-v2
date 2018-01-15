function map = faceMap(varargin)
%FVFRAMES Local coordinate frames for face-vertex representation
% MAP = FRAMES(FACES,TANGENTS{:}) returns frame data for face-vertex models
% in the rows of the following arrays: 
%
%    MAP(K,:,:) - coefficients of the offset-to-local-coordinates map
%                   that is evaluated as
%                     SQUEEZE(SUM(MAP(K,:,:).*(X-ORIGIN(K,:)), 2))
%

numdimensions = facevertex.ndirections(varargin{:});
[tangents{1 : numdimensions - 1}] = facevertex.tangents(varargin{:});
map = facevertex.faceMapFromTangents(tangents{:});
