function source = accesspointtable(varargin)
%ACCESSPOINTTABLE Create tabular struct encoding access points.
% Example:
% >> tabulardisp( ...
%     accesspointtable([1 2; 3 4; 5 6], 'Frequency', 7 : 9, 'Gain', 10))
%
%     Channel        Frame         Frequency    Name     Position
%     _______    ______________    _________    _____    ________
%     1          [1x2x2 double]    7            'AP1'    1    2  
%     1          [1x2x2 double]    8            'AP2'    3    4  
%     1          [1x2x2 double]    9            'AP3'    5    6  
%
% See also TABULARDISP

parser = inputParser;

parser.addRequired('Position', @ismatrix);
parser.addParameter('Frame', default, @(f) ndims(f) == 3);
parser.addParameter('Channel', 1, @isvector);
parser.addParameter('Gain', 0.0, @(g) isfunction(g) || isvector(g));
parser.addParameter('Frequency', centerfrequency, @isvector); % [Hz]
parser.addParameter('Name', default, @(s) (ismatrix(s) && ischar(s)) || iscellstr(s))
% Intended for internal use only
parser.addParameter('NamePrefix', 'AP', @(s) ischar(s) && isrow(s))

parser.parse(varargin{:});
source = orderfields(parser.Results);

[numsources, numdimensions] = size(source.Position);
assert(ismember(numdimensions, 2 : 3))
    function x = replicate(x)
        x = x(:); % column vector
        if isscalar(x)
            x = repmat(x, numsources, 1);
        end
        assert(numel(x) == numsources)
    end

% Frame vectors
if isdefault(source.Frame)
    % Default is the standard basis for each source
    source.Frame = reshape(eye(numdimensions), 1, numdimensions, []);
end
if size(source.Frame, 1) == 1
    % Duplicate a single prototype
    source.Frame = repmat(source.Frame, numsources, 1, 1);
end

if isdefault(source.Name)
    source.Name = arrayfun( ...
        @(id) sprintf('%s%d', source.NamePrefix, id), ...
        1 : size(source.Position, 1), ...
        'UniformOutput', false)';
end
source = rmfield(source, 'NamePrefix'); % Intended for internal use only

assert(ndims(source.Frame) == 3)
assert(size(source.Frame, 1) == numsources)
assert(size(source.Frame, 2) == numdimensions)
assert(size(source.Frame, 3) == numdimensions)

% Transmission frequency and channel
source.Frequency = replicate(source.Frequency);
source.Channel = replicate(source.Channel);

% Transmission gain
if isnumeric(source.Gain)
    source.Gain = isofunction(replicate(source.Gain));
end
isbinaryfunction = @(f) isfunction(f) && (nargin(f) < 0 || 2 <= nargin(f));
assert(isbinaryfunction(source.Gain))

% Post-condition
assert(istabular(source))

end

function result = default
result = struct(mfilename, mfilename);
end

function result = isdefault(x)
result = isequal(x, default);
end
