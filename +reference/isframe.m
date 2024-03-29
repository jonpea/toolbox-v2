function result = isframe(face)
%ISFRAME Returns true if input is a frame structure.
% See also FRAME.

result = ...
    isstruct(face) && ...
    ismember(face, 'Origin') && ...
    ismember(face, 'Normal') && ...
    ismember(face, 'Offset') && ...
    ismember(face, 'OffsetToLocalMap') && ...
    ismember(face, 'Class') && ...
    isrow(face.Origin) && ...
    isrow(face.Normal) && ...
    isscalar(face.Offset) && ...
    ismatrix(face.OffsetToLocalCoefficients) && ...
    isequal(size(face.Origin), size(face.Normal)) && ...
    size(face.OffsetToLocalCoefficients, 1) == size(face.Origin) - 1 && ...
    size(face.OffsetToLocalCoefficients, 2) == size(face.Origin);
