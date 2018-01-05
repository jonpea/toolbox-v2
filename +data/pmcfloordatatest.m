function pmcfloordatatest(verbose)

narginchk(0, 1)
if nargin < 1 || isempty(verbose)
    verbose = true;
end
assert(isscalar(verbose) && islogical(verbose))

floorindex = 8;
txindex = 1 : 12;
rxindex = [2, 4, 6];

txpositions = paistxpositions(txindex);

folderpath = fullfile('.', 'data', 'pais', sprintf('Level %d', floorindex));
filenames = compose('%d_%02d.xls', floorindex, rxindex);

[pairings, gains, txfrequencies] = pmcfloordata( ...
    filenames, ...
    'TransmitterIdentifiers', txindex, ...
    'FilePath', folderpath, ...
    'NumDimensions', 3, ...
    ... % Reducers, all free of rounding error
    'Min', @min, ...
    'Median', @median, ...
    'Max', @max);

if verbose
    tabulardisp(tabularcolumns(pairings, {
        'Source'
        'Transmitter'
        'Min'
        'Mean'
        'Median'
        'Max'
        'FrequencyHz'
        }))
    whos pairings gains txpositions rxpositions
end

assert(isequal(vec(min(gains, [], 3)), pairings.Min))
assert(isequal(vec(max(gains, [], 3)), pairings.Max))
assert(isequal(vec(median(gains, 3)), pairings.Median))
assert(numel(txfrequencies) == size(txpositions, 1))
