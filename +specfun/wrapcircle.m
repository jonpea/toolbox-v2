function y = wrapcircle(x, full)
narginchk(1, 2)
if nargin < 2
    full = 2*pi;
end
y = specfun.wrapinterval(x, 0, full);