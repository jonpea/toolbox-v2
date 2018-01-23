function result = numworkers(pool)
%NUMWORKERS Number of workers in parallel pool.
%   NUMWORKERS(P) returns the number of workers in parallel pool P, or the
%   value 1 if P is empty.
%
%   NUMWORKERS() is equivalent to NUMWORKERS(GCP()).
%
%   See also TASKINDEX, GCP.

narginchk(0, 1)

if nargin < 1
    pool = gcp;
end

assert(numel(pool) <= 1)

if isscalar(pool)
	assert(isa(pool, 'parallel.Pool'))
    result = pool.NumWorkers;
else
    result = 1;
end
