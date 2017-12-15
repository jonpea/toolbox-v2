function tf = isfv(s)
%ISFV True for polygon complex in face-vertex form.
%   ISFV(S) returns true if S is a struct with fields 'Faces' and
%   'Vertices'.
%
%   See also FV.

narginchk(1, 1)
tf = ...
    isgraphics(s, 'patch') || ... 
    (isfield(s, 'Faces') && isfield(s, 'Vertices'));
