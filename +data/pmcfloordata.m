function [pairings, gains, txfrequencies] = pmcfloordata(filenames, varargin)

narginchk(1, nargin)

if ischar(filenames)
    % Accommodate a single name in place of a cellstr of file names
    filenames = {filenames};
end

assert(iscellstr(filenames))

parser = inputParser;
parser.KeepUnmatched = true;
parser.addParameter('TransmitterIndices', ':', @isnumeric)
parser.addParameter('ReceiverIdentifiers', (1 : numel(filenames))', @(a) numel(a) == numel(filenames))
parser.addParameter('FilePath', '', @ischar)
parser.addParameter('NumDimensions', 3, @(n) ismember(n, 2 : 3))
parser.parse(varargin{:})
options = parser.Results;
reducers = parser.Unmatched;

% Add default reducer
assert(all(structfun(@isfunction, reducers))) 
assert(~isfield(reducers, 'Mean'))
reducers.Mean = @(a) elfun.todb(mean(elfun.fromdb(a)));

% Transmitter-specific data
txindices = options.TransmitterIndices;
txoffsets = 1 : numel(txindices);

% Transmitter-receiver pairings
for i = 1 : numel(filenames)
    
    % Extract floor data from file
    [record, pairinggain] = data.pmcload(fullfile(options.FilePath, filenames{i}));
    
    % Compute statistics over samples
    cellfun(@applyreducer, fieldnames(reducers))
    
    % Retain data only for transmitters of interest
    import datatypes.struct.tabular.rows
    record.Data = rows(record.Data, txindices);
    record.Data.Transmitter = compose('TX%d', txindices(:));
    record.Data.TransmitterOffset = txoffsets(:);
    record.Data.TransmitterIdentifier = txindices(:);
    
    % These are singleton entries
    record.MetaData.Source = filenames{i}; 
    record.MetaData.ReceiverOffset = i; 
    record.MetaData.ReceiverIdentifier = options.ReceiverIdentifiers(i);

    % Note to Maintainer:
    % This seems needlessly complicated because the task of extending
    % singleton columns was, in an earlier iteration of this function, 
    % the responsibility of the "vertcat" routine for structs.
    import datatypes.struct.merge
    import datatypes.struct.tabular.height
    import datatypes.struct.tabular.rows
    record.MetaData = structfun(@charToCellstr, record.MetaData, 'UniformOutput', false);
    record.MetaData = rows(record.MetaData, ones(height(record.Data), 1));
    pairing = merge(record.Data, record.MetaData);
    
    %pairings(i) = record; %#ok<AGROW>
    pairings(i) = pairing; %#ok<AGROW>
    gains{i} = pairinggain(txindices, :); %#ok<AGROW>
    
end

    function applyreducer(name)
        % Sanity check: Don't overwrite existing fields
        assert(~ismember(name, fieldnames(record.Data)))
        % Reducer operates on first dimension, so transpose twice
        record.Data.(name) = feval(reducers.(name), pairinggain')';
    end

% Concatenate individual tables into a single table
pairings = datatypes.struct.structfun(@vertcat, pairings, 'UniformOutput', false);
%pairings = tabularvertcat(pairings);
gains = permute(cat(3, gains{:}), [1 3 2]);

pairedfrequencies = accumarray( ...
    pairings.TransmitterOffset, pairings.FrequencyHz, [], @(f) {f});
assert(all(cellfun(@(a) isscalar(unique(a)), pairedfrequencies)), ...
    'Transmitter frequencies are not uniform across receivers')
txfrequencies = cellfun(@(a) a(1), pairedfrequencies);

end

function x = charToCellstr(x)
if ischar(x)
    % Convert character array to cellstr if required
    x = cellstr(x);
end
end

