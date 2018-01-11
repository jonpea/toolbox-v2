function [options, unmatched] = tracesceneargumentsnew(varargin)

parser = inputParser;
parser.KeepUnmatched = true;

parser.addRequired('Scene', @(s) isstruct(s) || isobject(s))
% Relating to model fidelity
parser.addParameter('ReflectionArities', 0, @(a) isequal(fix(a), a) && all(0 <= a))
% Gain coefficient functions
import datatypes.isfunction
parser.addParameter('FreeGain', power.friisfunction, @isfunction)
parser.addParameter('SourceGain', power.isofunction, @isfunction)
parser.addParameter('SinkGain', power.isofunction, @isfunction)
parser.addParameter('ReflectionGain', power.isofunction, @isfunction)
parser.addParameter('TransmissionGain', power.isofunction, @isfunction)
% Verbosity of textual output
parser.addParameter('Reporting', false, @(b) isscalar(b) && islogical(b))

if nargin == 1 && isstruct(varargin{1})    
    % inputParser must received required arguments first
    options = varargin{1};
    assert(isfield(options, 'Scene'))
    varargin = {options.Scene, rmfield(options, 'Scene')};
end
    
parser.parse(varargin{:})
options = parser.Results;
unmatched = parser.Unmatched;

% Duplicate reflection arities imply duplicate work
arities = options.ReflectionArities;
if numel(unique(arities)) < numel(arities)
    warning('TraceScene:DuplicateArities', ...
        'ReflectionArities array contains duplicate entries')
end
