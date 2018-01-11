function varargout = meshgrid(varargin)
%MESHGRID Cartesian grid in 2-D/3-D space.
%
%  Example:
%   >> [x, y] = sx.meshgrid(1 : 3)
%   x =
%        1     2     3
%   y =
%        1
%        2
%        3
%
%   See also SX.NDGRID, MESHGRID, NDGRID.

narginchk(1, 3)

if nargin == 1
    % Support for square/homogeneous grid
    % e.g. "[x,y,z] = meshgrid(1:10)"
    % NB: With one input and one output, the built-in
    % version of meshgrid returns a (2-D) matrix.
    varargin = repmat(varargin, 1, max(2, nargout));
end

assert(ismember(numel(varargin), 2 : 3)) % invariant

numaxes = numel(varargin);
assert(nargout <= numaxes)

if isvector(varargin{1})
    varargin{1} = varargin{1}(:).'; % row vector
end

if isvector(varargin{2})
    varargin{2} = varargin{2}(:); % column vector
end

if numaxes == 3 && isvector(varargin{3})
    varargin{3} = reshape(varargin{3}, 1, 1, []); % "into-the-page"-vector
end

varargout = varargin;

if ~sx.iscompatible(varargout{:})
    warning(arguments.msgid(mfilename, 'SXIncompatible'), ...
        'The given list is incompatible with singleton expansion.')
end
