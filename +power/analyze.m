function [dlinks, ulinks, hits, durations] = ...
    analyze(reflect, transmit, numfacets, origins, targets, varargin)

[traceoptions, unmatched] = imagemethod.tracesceneSettings(varargin{:});

% Augment optional settings
parser = inputParser;
parser.addParameter( ...
    'AccessPointChannel', ...
    ones(size(origins, 1), 1), ...
    @(c) isnumeric(c) && numel(c) == size(origins, 1) && 1 <= min(c(:)))
parser.addParameter( ...
    'MinimumDiscernableSignal', ...
    minimumdiscernablesignal, ... % [dBW]
    @(x) isnumeric(x) && isscalar(x) && x < 0)
parser.parse(unmatched)
linkoptions = parser.Results;

[downlinkGainComponents, uplinkGainComponents, hits, durations] = ...
    rayoptics.tracescene( ...
    reflect, transmit, numfacets, origins, targets, traceoptions);

% Received gain (in dBW): Rows for access points, columns for mobiles
downlinkGainDBW = specfun.todb(sum(downlinkGainComponents, 3));

% Downlink calculations
dlinks = power.downlinkSINR( ...
    downlinkGainDBW, ...
    linkoptions.AccessPointChannel, ...
    linkoptions.MinimumDiscernableSignal);
dlinks.GainComponents = downlinkGainComponents;
dlinks.GainDBW = downlinkGainDBW;

dlinks = orderfields(dlinks, {
    'GainDBW' ...
    'GainComponents' ...
    'SINRatio' ...
    'INGainDBW' ...
    'SGainDBW' ...
    'AccessPoint' ...
    'Channel' ...
    });

if nargout < 2
    return % uplink calculations are not required
end

% Received gain (in watts), rows for receivers
uplinkGain = sum(uplinkGainComponents, 3);
uplinkGainDBW = specfun.todb(uplinkGain);

% Uplink calculations
ulinks = power.uplinkSINR( ...
    uplinkGainDBW, ...
    dlinks.AccessPoint, ...
    linkoptions.AccessPointChannel, ...
    linkoptions.MinimumDiscernableSignal);
ulinks.GainComponents = uplinkGainComponents;
ulinks.GainDBW = uplinkGainDBW;

ulinks = orderfields(ulinks, {
    'GainDBW' ...
    'GainComponents' ...
    'SINRatio' ...
    'INGainDBW' ...
    'SGainDBW' ...
    });

% -------------------------------------------------------------------------
function mds = minimumdiscernablesignal(options)
% MINIMUMDISCERNABLESIGNAL Minimum discernable signal in dBw

if nargin == 1
    assert(isstruct(options))
    fieldname = 'MinimumDiscernableSignal';
    if isfield(options, fieldname)
        mds = options.(fieldname);
        return
    end
end

mds = -100; % [dBW]
