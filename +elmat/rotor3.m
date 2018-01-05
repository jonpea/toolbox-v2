function rotor = rotor3d(orientation, alpha)
%ROTOR3D 3x3 rotation matrix.
% R = ROTOR3D([DX, DY, DZ], ALPHA) returns a 3x3 rotation matrix R
% such that the rows of
%            [X(:), Y(:), Z(:)]*R
% correspond to rotations of [X(:), Y(:), Z(:)] through angle ALPHA about
% the axis [DX, DY, DZ].
% This is the same rotation matrix employed in <strong>rotate</strong>,
% but is specified in radians (rather than degrees) and uses inclination
% (rather than elevation).
%
% See also ROTATE.

narginchk(2, 2)

% Unit vector for axis of rotation
switch numel(orientation)
    case 2 % spherical coordinates
        u = angulartocartesian(orientation, 1.0);
    case 3 % Cartesian coodinates
        u = orientation(:)/norm(orientation);
end

cosa = cos(alpha);
sina = sin(alpha);
vera = 1 - cosa;
x = u(1);
y = u(2);
z = u(3);
rotor = [
    cosa+x^2*vera x*y*vera-z*sina x*z*vera+y*sina;
    x*y*vera+z*sina cosa+y^2*vera y*z*vera-x*sina;
    x*z*vera-y*sina y*z*vera+x*sina cosa+z^2*vera;
    ]';
