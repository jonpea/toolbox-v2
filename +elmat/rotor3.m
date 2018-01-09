function rotor = rotor3(direction, alpha)
%ROTOR3 3x3 rotation matrix.
%   R = ROTOR3(DIRECTION,ALPHA) returns a 3x3 rotation matrix R
%   such that the rows of
%                         [X(:),Y(:),Z(:)]*R
%   correspond to rotations of each row of [X(:),Y(:),Z(:)] through 
%   angle ALPHA about the axis defined by DIRECTION.
%
%   DIRECTION is a two- or three-element vector that describes the 
%   axis of rotation about point [0,0,0]:
%   - [AZIMUTH,ELEVATION] employs spherical coordinates in radians
%   - [DX,DY,DZ] uses Cartesian coordinates
%   See SPH2CART or CART2SPH for a description of these systems.
%
%   Positive scalar ALPHA is defined as the righthand-rule angle about the
%   direction vector as it extends from [0,0,0].
%
%   This is the same rotation matrix employed in <strong>rotate</strong>,
%   but is specified in radians (rather than degrees).
%
%   See also ROTATE.

narginchk(2, 2)

assert(isscalar(alpha))

% Unit vector for axis of rotation
switch numel(direction)
    case 2
        % Spherical coordinates
        azimuth = direction(1);
        elevation = direction(2);
        radius = 1.0;
        [x, y, z] = sph2cart(azimuth, elevation, radius);
        
    case 3
        % Cartesian coodinates
        u = direction/norm(direction);
        x = u(1);
        y = u(2);
        z = u(3);
        
    otherwise
        error( ...
            contracts.msgid(mfilename, 'IllegalDirection'), ...
            'DIRECTION should be a vector of length 2 or 3.')
end

cosa = cos(alpha);
sina = sin(alpha);
vera = 1 - cosa;
rotor = [
    cosa+x^2*vera x*y*vera-z*sina x*z*vera+y*sina;
    x*y*vera+z*sina cosa+y^2*vera y*z*vera-x*sina;
    x*z*vera-y*sina y*z*vera+x*sina cosa+z^2*vera;
    ]';
