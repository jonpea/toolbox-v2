function sink = mobiletable(varargin)
%MOBILETABLE Create tabular struct representing mobile devices.

% Requirements of mobiles and access points are nearly identical
sink = rmfield( ...
    scenes_old.accesspointtable(varargin{:}, 'NamePrefix', 'MOB'), ...
    'Frequency');
