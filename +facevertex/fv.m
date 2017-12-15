function varargout = fv(varargin)
%FV Structure or de-structure a face-vertex representation.
%   REP = FV(FACES,VERTICES) returns face-vertex representation of a
%   polygon complex in a single struct.
% 
%   [FACES, VERTICES] = FV(REP) de-structures the struct into its
%   components.
%
%   See also FV2XY, XY2FV.

narginchk(1, 2)
nargoutchk(0, 2)

nin = nargin;
nout = max(1, nargout);

if nin == nout
    varargout = varargin;
    return
end

switch nin
    case 1
        assert(nout == 2)
        fvstruct = varargin{:};
        varargout = {fvstruct.Faces, fvstruct.Vertices};
    case 2
        assert(nout == 1)
        [faces, vertices] = varargin{:};
        varargout = {struct('Faces', faces, 'Vertices', vertices)};
end
