function result = reflectionstatistics(gain, arities)
%REFLECTIONSTATISTICS Distribution of power over reflection arities.

narginchk(1, 2)
if isstruct(gain)
    gain = gain.GainComponents; % watts/watt
end
assert(isnumeric(gain))
assert(ndims(gain) <= 3)
if nargin < 2
    arities = 0 : size(gain, 3) - 1;
end

arityGain = squeeze(sum(sum(gain, 1), 2)); % total Gain at each arity
totalGain = sum(arityGain);
relativeGain = arityGain ./ totalGain;
select = arities(:) + 1;
result = struct( ...
    'NumReflections', arities(:), ...
    'Gain', arityGain(select), ...
    'RelativeGain', relativeGain(select));
