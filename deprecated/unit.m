function x = unit(x)
%UNIT Unit vector associated with argument.
narginchk(1, 1)
assert(isvector(x))
x = x/norm(x);
end
