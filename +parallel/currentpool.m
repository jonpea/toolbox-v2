function pool = currentpool(varargin)
%CURRENTPOOL Returns the current parallel pool.
%   CURRENTPOOL is equivalent to GCP if the Parallel Computing
%   Toolbox is installed and [] otherwise.
%
%   See also GCP.

persistent istoolboxinstalled
if isempty(istoolboxinstalled)
    istoolboxinstalled = exist('gcp', 'file');
end

if istoolboxinstalled
    pool = gcp(varargin{:});
else
    pool = [];
end
