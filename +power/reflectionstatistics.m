function result = reflectionstatistics(powers, arities)

narginchk(1, 2)
if isstruct(powers)
    powers = powers.PowerComponentsWatts;
end

if nargin < 2
    arities = 0 : size(powers, 3) - 1;
end

aritypower = squeeze(sum(sum(powers, 1), 2)); % total power at each arity
totalpower = sum(aritypower);
relativepower = aritypower ./ totalpower;
select = arities(:) + 1;
result = struct( ...
    'NumReflections', arities(:), ...
    'PowerWatts', aritypower(select), ...
    'PowerRelative', relativepower(select), ...
    'PowerNanoWatts', aritypower(select)/1e-9, ...
    'PowerRelativePercent', relativepower(select)*100);
