function planarmirrormextest

numpoints = 10;
facenormal = rand(1, numdimensions);
faceoffset = rand(1);
points = rand(numpoints, numdimensions);
mirrorpoints = zeros(size(points));

[facenormal, scale] = unit(facenormal);
faceoffset = faceoffset/scale;

mirrorpoints = mirrorpoints';
scenes.mirrormex(facenormal, faceoffset, points', mirrorpoints);
mirrorpoints = mirrorpoints';

projection = 0.5*(points + mirrorpoints);
direction = unit(points - mirrorpoints);

compare(projection*facenormal', faceoffset)
compare(abs(direction*facenormal'), 1.0)

end

% -------------------------------------------------------------------------
function n = numdimensions
n = 3;
end

% -------------------------------------------------------------------------
function compare(actual, expected)
tol = 1e-12;
mismatch = abs(actual - expected);
scale = abs(expected) + 1.0;
assert(all(mismatch(:) < tol*scale(:)))
end

% -------------------------------------------------------------------------
function [x, normx] = unit(x)
normx = sqrt(sum(x.*x, 2));
x = x ./ normx;
end
