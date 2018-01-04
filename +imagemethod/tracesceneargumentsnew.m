function [options, unmatched] = tracesceneargumentsnew(varargin)

parser = inputParser;
parser.KeepUnmatched = true;

parser.addRequired('Scene', @(s) isstruct(s) || isobject(s))
% Relating to model fidelity
parser.addParameter('ReflectionArities', 0, @(a) isround(a) && all(0 <= a))
% Gain coefficient functions
parser.addParameter('FreeGain', friisfunction, @isfunction)
parser.addParameter('SourceGain', isofunction, @isfunction)
parser.addParameter('SinkGain', isofunction, @isfunction)
parser.addParameter('ReflectionGain', isofunction, @isfunction)
parser.addParameter('TransmissionGain', isofunction, @isfunction)
% Parallel processing
parser.addParameter('SPMD', ~isempty(currentpool), @(b) isscalar(b) && islogical(b))
parser.addParameter('NumWorkers', numworkers(currentpool), @(n) isscalar(n) && 1 <= n)
% Verbosity of textual output
parser.addParameter('NDEBUG', ndebug, @(b) isscalar(b) && islogical(b))
parser.addParameter('Reporting', false, @(b) isscalar(b) && islogical(b))
parser.addParameter('Verbosity', 0, @(n) isscalar(n) && isround(n) && 0 <= n)
% Development support
parser.addParameter('Private', struct, @isstruct)

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
