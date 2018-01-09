function rotor = rotor2(alpha)
%ROTOR2 2x2 rotation matrix.
% R = ROTOR2(ALPHA) returns a 2x2 rotation matrix R
% such that the rows of
%            [X(:), Y(:)]*R
% correspond to rotations of the rows of [X(:),Y(:)] through angle ALPHA,
% specified in radians.
%
% See also ROTOR3.

narginchk(1, 1)
assert(isscalar(alpha))

cosa = cos(alpha);
sina = sin(alpha);
rotor = [
    cosa, -sina;
    sina,  cosa;
    ]';
