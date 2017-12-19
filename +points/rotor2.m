function rotor = rotor2d(alpha)
%ROTOR2D 2x2 rotation matrix.
% R = ROTOR2D(ALPHA) returns a 2x2 rotation matrix R
% such that the rows of
%            [X(:), Y(:)]*R
% correspond to rotations of [X(:), Y(:)] through angle ALPHA.
%
% See also ROTOR3D.

narginchk(1, 1)

cosa = cos(alpha);
sina = sin(alpha);
rotor = [
    cosa, -sina;
    sina,  cosa;
    ]';
