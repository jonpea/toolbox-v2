% startparpool.m
%
% Created by jantoreh, Nov. 2016
% Function to start/restart parallel pool on 'local' with 'n' workers
%
% Input:
% -------------
% n    - Number of wanted workers
%
% Output:
% -------------
% status - 0 or 1
%

function status = startparpool(n)

% Basic input check
if ~isscalar(n) || ~isnumeric(n) || rem(n,1)>0
    error('Input must be a scalar.')
end

nc = feature('numcores');
if n>2*nc % Logical cores typically 2 times the number of physical
    warning('The number of wanted workers are greater than the number of logical cores. Consider your hyper-threading options-')
end

c = gcp('nocreate'); % Get current parpool, if any

% Check if parpool is running
if isempty(c) % Create parpool
    p=parcluster('local');
    p.NumWorkers=n;
    parpool(n);
    status = 1; % Everything ok
elseif c.NumWorkers ~= n % Close pool and start new
    delete(c);
    p=parcluster('local');
    p.NumWorkers=n;
    parpool(n);
    status = 1; % Everything ok
else
    disp('Parpool already exists.')
    status = 0; % Nothing is done, parpool already exists
end


    
