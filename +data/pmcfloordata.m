function [pairings, gains, txfrequencies] = pmcfloordata(filenames, varargin)

narginchk(1, nargin)

if ischar(filenames)
    % Accommodate a single name in place of a cellstr of file names
    filenames = {filenames};
end

assert(iscellstr(filenames))

parser = inputParser;
parser.KeepUnmatched = true;
parser.addParameter('TransmitterIndices', ':', @isindex)
parser.addParameter('ReceiverIdentifiers', (1 : numel(filenames))', @(a) numel(a) == numel(filenames))
parser.addParameter('FilePath', '', @ischar)
parser.addParameter('NumDimensions', 3, @(n) ismember(n, 2 : 3))
parser.parse(varargin{:})
options = parser.Results;
reducers = parser.Unmatched;

% Add default reducer
assert(all(structfun(@isfunction, reducers))) 
assert(~isfield(reducers, 'Mean'))
reducers.Mean = @(a) todb(mean(fromdb(a)));

% Transmitter-specific data
txindices = options.TransmitterIndices;
txoffsets = 1 : numel(txindices);

% Transmitter-receiver pairings
for i = 1 : numel(filenames)
    
    % Extract floor data from file
    [record, pairinggain] = pmcload(fullfile(options.FilePath, filenames{i}));
    
    % Compute statistics over samples
    cellfun(@applyreducer, fieldnames(reducers))
    
    % Retain data only for transmitters of interest
    record = tabularrows(record, txindices);
    
    % These are singleton entries
    record.Source = filenames{i}; 
    record.ReceiverOffset = i; 
    record.ReceiverIdentifier = options.ReceiverIdentifiers(i);
    
    record.Transmitter = compose('TX%d', txindices);
    record.TransmitterOffset = txoffsets(:);
    record.TransmitterIdentifier = txindices(:);
    
    pairings(i) = record; %#ok<AGROW>
    gains{i} = pairinggain(txindices, :); %#ok<AGROW>
    
end

    function applyreducer(name)
        % Sanity check: Don't overwrite existing fields
        assert(~ismember(name, fieldnames(record)))
        % Reducer operates on first dimension, so transpose twice
        record.(name) = feval(reducers.(name), pairinggain')';
    end

pairings = tabularvertcat(pairings);
gains = permute(cat(3, gains{:}), [1 3 2]);

pairedfrequencies = accumarray( ...
    pairings.TransmitterOffset, pairings.FrequencyHz, [], @(f) {f});
assert(all(cellfun(@(a) isscalar(unique(a)), pairedfrequencies)), ...
    'Transmitter frequencies are not uniform across receivers')
txfrequencies = cellfun(@(a) a(1), pairedfrequencies);

end
