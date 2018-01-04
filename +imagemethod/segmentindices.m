function result = segmentindices(chunksizes)
%SEGMENTINDICES Helper function to index ray segments.

indices = 1 : numel(chunksizes);

chunks = arrayfun( ...
    @(value, length) repmat(value, length, 1), ...
    indices(:), ...
    chunksizes(:), ...
    'UniformOutput', false);

result = vertcat(chunks{:});

% Post-conditions
import contracts.ndebug
assert(ndebug || numel(result) == sum(chunksizes))
assert(ndebug || all(ismember(unique(result), indices(:))))