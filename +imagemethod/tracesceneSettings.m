function [options, unmatched] = tracesceneSettings(varargin)

parser = inputParser;

% Relating to model fidelity:
% By default, only direct rays are computed.
parser.addParameter('ReflectionArities', 0, @(a) isequal(fix(a), a) && all(0 <= a))

% Gain coefficient functions:
% By default, only free-space losses are computed.
import datatypes.isfunction
parser.addParameter('FreeGain', antennae.friisfunction, @isfunction)
parser.addParameter('SourceGain', antennae.isopattern, @isfunction)
parser.addParameter('SinkGain', antennae.isopattern, @isfunction)
parser.addParameter('ReflectionGain', antennae.isopattern, @isfunction)
parser.addParameter('TransmissionGain', antennae.isopattern, @isfunction)

% Verbosity of textual output:
% By default, a complete record of all interactions is not stored.
parser.addParameter('Reporting', false, @(b) isscalar(b) && islogical(b))

parser.KeepUnmatched = true;
parser.parse(varargin{:})
options = parser.Results;
unmatched = parser.Unmatched;

% Duplicate reflection arities imply duplicate work
arities = options.ReflectionArities;
if numel(unique(arities)) < numel(arities)
    warning(contracts.msgid(mfilename, 'DuplicateArities'), ...
        'ReflectionArities array contains duplicate entries')
end
