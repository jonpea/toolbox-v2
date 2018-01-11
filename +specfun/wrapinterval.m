function result = wrapinterval(x, min, max)
%WRAPINTERVAL Principle value on a cyclic interval.
%
% Example:
% >> wrapinterval([-370 -10 10 370], 0, 360)
% ans =
%    350   350    10    10
%
% >> wrapinterval([5 10 15 20 25], 10, 20)
% ans =
%     15    10    15    10    15
%

narginchk(3, 3)
assert(isscalar(min))
assert(isscalar(max))

% Courtesy of Tim ?as: 
% http://stackoverflow.com/questions/4633177/c-how-to-wrap-a-float-to-the-interval-pi-pi
result = min + wrapmax(x - min, max - min);

% figure(3), clf
% ticks = 1 : numel(x);
% plot(ticks(:), x(:), '.', ticks(:), result(:), '.')
% [];

function result = wrapmax(x, max)
result = mod(max + mod(x, max), max);
