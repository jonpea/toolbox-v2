function class = mexindexclass(archstr)

import contracts.ndebug

if nargin < 1
    archstr = computer;
end

assert(ndebug || ischar(archstr))
assert(ndebug || 2 < numel(archstr))

numbits = str2double(archstr(end - 1 : end)); % faster than num2str
assert(ndebug || ~isempty(numbits))
assert(ndebug || ismember(numbits, [32, 64]))

switch numbits
    case 32
        class = 'uint32';
    case 64
        class = 'uint64';
end
