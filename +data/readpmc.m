function [gains, attributes] = readpmc(fid, varargin)
%READPMC Read propagation measurement campaign data file.
% See Chapter 4 of 
%   The Deployment and Performance of Indoor/Outdoor DS-CDMA 
%    Systems with Multiuser Detection
%   by Adrian Victor Pais
%       Electrical and Electronic Engineering,
%        The University of Auckland, 2007.

if ischar(fid)
    % Caller may provide file name instead of file identifier
    fid = fopen(fid, varargin{:});
    cleaner = onCleanup(@() fclose(fid));
end

% Date and time
dateformat = 'HH:MM PM dddd, mmmm dd, yyyy';
attributes.Date = datenum(nextline(fid), dateformat);

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
attributes.ScanFrequencyValues = vertcat(allvalues{:});
attributes.ScanFrequencyUnit = validatehertz(frequencyunit{:});

% Preamplifier status
[prefix, status] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'preamplifier'))
status = validatestring(status, {'on', 'off'});
attributes.Preamplifier = status;

line = nextline(fid);
[prefix, value, unit] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'bandwidth:if'))
attributes.Bandwidth = str2double(value);
attributes.BandwidthUnit = validatehertz(unit);

line = nextline(fid);
[prefix, value, unit] = splittuple(line, {' ', ';'});
assert(strcmpi(prefix, 'specialfunc:samplingtime'))
attributes.SamplingDuration = str2double(value);
attributes.SamplineDurationUnit = validatesecond(unit);

assert(startsWith(nextline(fid), 'Sampling Time', 'IgnoreCase', true))
assert(startsWith(nextline(fid), 'Samples/Sec', 'IgnoreCase', true))

line = nextline(fid);
startstx = @(attributes) startsWith(attributes, 'TX', 'IgnoreCase', true);
assert(startstx(line))
headers = splitpurge(line);
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
gains = buffer';

end

function result = startswith(attributes, pattern)
% Case-insensitive version of built-in function
result = startsWith(attributes, pattern, 'IgnoreCase', true);
end

function result = splitpurge(varargin)
result = split(varargin{:});
result(cellfun(@isempty, result)) = []; % drop empty elements
end

function varargout = splittuple(tuple, varargin)
varargout = splitpurge(tuple, varargin{:});
assert(isscalar(varargout) || numel(varargout) == nargout) % caution'attributes sake
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
unit = validatestring(unit, {'ms', 'attributes'});
end
