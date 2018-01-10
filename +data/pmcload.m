function [record, buffer] = pmcload(fid, varargin)
%PMCLOAD Read propagation measurement campaign data file.
% See Chapter 4 of 
%   The Deployment and Performance of Indoor/Outdoor DS-CDMA 
%    Systems with Multiuser Detection
%   by Adrian Victor Pais
%       Electrical and Electronic Engineering,
%        The University of Auckland, 2007.

if ischar(fid)
    % Caller may provide file name instead of file identifier
    assert(logical(exist(fid, 'file')), ...
        '%s does not exist or is not on the search path', fid)
    [fid, message] = fopen(fid, 'r');
    assert(fid ~= -1, message)
    cleaner = onCleanup(@() fclose(fid));
end

parser = inputParser;
parser.KeepUnmatched = true;
parser.parse(varargin{:});

% Date and time
dateformat = 'HH:MM PM dddd, mmmm dd, yyyy';
record.MetaData.DateNum = datenum(nextline(fid), dateformat);

% Scan list frequencies
scanlist = 'scan:list:frequencies';
numtransmitters = 0;
[allvalues, allunits] = deal({});
line = nextline(fid);
while startswith(line, scanlist)
    elements = splitpurge(line, {',', ';'});
    [prefix, count] = splittuple(elements{1});
    assert(startswith(prefix, scanlist))
    [values, units] = cellfun(@splittuple, elements(2 : end), 'UniformOutput', false);
    unit = unique(units);
    assert(isscalar(unit))
    numtransmitters = numtransmitters + str2double(count);
    allvalues{end + 1} = cellfun(@str2double, values);  %#ok<AGROW>
    allunits{end + 1} = unit{:}; %#ok<AGROW>
    line = nextline(fid);
end
frequencyunit = unique(allunits);
assert(isscalar(frequencyunit))
assert(isequal(validatehertz(frequencyunit{:}), 'MHz'))
record.Data.FrequencyHz = vertcat(allvalues{:})*1e6; % convert MHz to Hz

% Preamplifier status
[prefix, status] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'preamplifier'))
status = validatestring(status, {'on', 'off'});
record.MetaData.Preamplifier = status;

line = nextline(fid);
[prefix, value, unit] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'bandwidth:if'))
assert(isequal(validatehertz(unit), 'kHz'))
record.MetaData.BandwidthHz = str2double(value)*1e3; % convert kHz to Hz

line = nextline(fid);
[prefix, value, unit] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'specialfunc:samplingtime'))
record.MetaData.SamplingDurationSec = str2double(value)/1e3; % convert ms to sec
assert(isequal(validatesecond(unit), 'ms'))

assert(startsWith(nextline(fid), 'Sampling Time', 'IgnoreCase', true))
assert(startsWith(nextline(fid), 'Samples/Sec', 'IgnoreCase', true))

headerprefix = 'TX-';
line = nextline(fid);
startstx = @(record) startsWith(record, 'TX-', 'IgnoreCase', true);
assert(startstx(line))
headers = upper(splitpurge(line));
assert(all(cellfun(startstx, headers)))
assert(numel(headers) == numtransmitters)

% Note: Built-in function textscan doesn't directly handle empty lines
buffer = zeros(numtransmitters, 0);
while ~feof(fid)
    line = nextline(fid);
    assert(ischar(line)) % invariant
    if isempty(line)
        continue % admit blank line within data block
    end
    values = split(line);
    assert(numel(values) == numtransmitters)
    buffer(:, end + 1) = str2double(values); %#ok<AGROW>
end

% Transmitter names/identifiers are not necessarily in order
headerformat = [headerprefix '%d'];
transmitterindices = cellfun( ...
    @(header) sscanf(header, headerformat), headers);
record.Data.Transmitter = headers; % useful sanity-check
%record.TransmitterIndex = transmitterindices; % redundant after sorting

% Non-singleton entries
record.Data = orderfields(record.Data, {
    'Transmitter';
    'FrequencyHz';
    });

% Singleton entries
record.MetaData = orderfields(record.MetaData, {
    'BandwidthHz';
    'SamplingDurationSec';
    'Preamplifier';
    'DateNum';
    });

% Sort rows acording to transmitter index/name
[sortedindentifiers, permutation] = sort(transmitterindices);
assert(isequal(sortedindentifiers(:)', 1 : numtransmitters))
record.Data = datatypes.struct.tabular.rows(record.Data, permutation);
buffer = buffer(permutation, :);

end

function result = startswith(record, pattern)
% Case-insensitive version of built-in function
result = startsWith(record, pattern, 'IgnoreCase', true);
end

function result = splitpurge(varargin)
result = split(varargin{:});
% Work-around: In R2016b (and perhaps other versions pre-R2017a),
% function split() returns a string array rather than cell array.
result = cellstr(result); 
result(cellfun(@isempty, result)) = []; % drop empty elements
end

function varargout = splittuple(tuple, varargin)
varargout = splitpurge(tuple, varargin{:});
assert(isscalar(varargout) || numel(varargout) == nargout) % caution'record sake
end

function line = nextline(fid)
while true
    line = fgetl(fid);
    if ~isempty(line)
        break
    end
end
end

function unit = validatehertz(unit)
unit = validatestring(unit, {'Hz', 'kHz', 'MHz', 'GHz'});
end

function unit = validatesecond(unit)
unit = validatestring(unit, {'ms', 'record'});
end
