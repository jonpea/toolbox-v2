function n = faceNormal(varargin)
%   See also TRIANGULATION/FACENORMAL.
unit = @(a) matfun.unit(a, 2);
[faces, vertices] = facevertex.fv(varargin{:});
switch size(vertices, 2)
    case 2
        t = facevertex.tangents(faces, vertices);
        n = specfun.perp(unit(t), 2);
    case 3
        [t1, t2] = facevertex.tangents(faces, vertices);
        n = cross(unit(t1), unit(t2), 2);
    otherwise
        assert(false, contracts.unreachable)
end
