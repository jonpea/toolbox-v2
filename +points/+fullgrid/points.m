function p = points(g)
%POINTS Convert full grid to points matrix.
assert(isgrid(g))
columns = cellfun(@vec, struct2cell(g), 'UniformOutput', false);
p = [columns{:}];

function x = vec(x)
x = x(:);