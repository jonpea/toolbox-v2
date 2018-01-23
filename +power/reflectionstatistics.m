function result = reflectionstatistics(powers, arities)

narginchk(1, 2)
if isstruct(powers)
    powers = powers.GainComponents;
end
if nargin < 2
    arities = 0 : size(powers, 3) - 1;
end

arityPower = squeeze(sum(sum(powers, 1), 2)); % total power at each arity
totalPower = sum(arityPower);
relativePower = arityPower ./ totalPower;
select = arities(:) + 1;
result = struct( ...
    'NumReflections', arities(:), ...
    'PowerWatts', arityPower(select), ...
    'PowerRelative', relativePower(select), ...
    'PowerNanoWatts', arityPower(select)/1e-9, ...
    'PowerRelativePercent', relativePower(select)*100);
