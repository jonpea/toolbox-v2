function [a, b] = unsingleton(a, b)
%UNSINGLETON Inflates singleton row or either argument.

a = extend(a, b);
b = extend(b, a);

function a = extend(a, b)
if size(a, 1) == 1
    a = repmat(a, size(b, 1), 1);
end
