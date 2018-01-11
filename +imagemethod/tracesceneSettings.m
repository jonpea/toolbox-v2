function [options, unmatched] = tracesceneSettings(varargin)

parser = inputParser;
parser.KeepUnmatched = true;

%parser.addRequired('Scene', @(s) isstruct(s) || isobject(s))

% Relating to model fidelity:
% By default, only direct rays are computed.
parser.addParameter('ReflectionArities', 0, @(a) isequal(fix(a), a) && all(0 <= a))

% Gain coefficient functions:
% By default, only free-space losses are computed.
import datatypes.isfunction
parser.addParameter('FreeGain', power.friisfunction, @isfunction)
parser.addParameter('SourceGain', power.isofunction, @isfunction)
parser.addParameter('SinkGain', power.isofunction, @isfunction)
parser.addParameter('ReflectionGain', power.isofunction, @isfunction)
parser.addParameter('TransmissionGain', power.isofunction, @isfunction)

% Verbosity of textual output
% By default, a complete record of all interactions is not stored.
parser.addParameter('Reporting', false, @(b) isscalar(b) && islogical(b))

% if nargin == 1 && isstruct(varargin{1})    
%     % inputParser must received required arguments first
%     options = varargin{1};
%     assert(isfield(options, 'Scene'))
%     varargin = {options.Scene, rmfield(options, 'Scene')};
% end
    
parser.parse(varargin{:})
options = parser.Results;
unmatched = parser.Unmatched;

% Duplicate reflection arities imply duplicate work
arities = options.ReflectionArities;
if numel(unique(arities)) < numel(arities)
    warning('TraceScene:DuplicateArities', ...
        'ReflectionArities array contains duplicate entries')
end
