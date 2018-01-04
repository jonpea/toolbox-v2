function [contains, output] = intersect(face, x0, x1)

narginchk(3, 3)

assert(isframe(face))
assert(isrow(x0))
assert(isrow(x1))
assert(numel(x0) == numel(x1))
assert(numel(x0) == size(face.Origin, 2))
assert(isequal(class(x0), class(x1)))
assert(isequal(class(x0), class(frame.Origin)))

zero = zeros(classname);
one = ones(classname);
unitincludes = @(x) all(zero <= x & x <= one);

numerator = face.Offset - dot(face.Normal, x0);
denominator = dot(face.Normal, x1);
output.RayCoordinate = numerator/denominator;
output.Intersection = x0 + x1*output.RayCoordinate;
offset = output.Intersection - face.Origin; % offset
output.FaceCoordinates = face.OffsetToLocalCoefficients*offset;
contains = ...
    unitincludes(output.RayCoordinate) && ...
    unitincludes(output.FaceCoordinates);
