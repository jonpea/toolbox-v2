function varargout = parreduce(fun, numout, getnext, varargin)
%PARREDUCE Parallel accumulation.

%
% Note to Maintainer
% ------------------
% It is not possible to store instances of Composite in a cell
% array within an spmd block.
% e.g.
%  Invocation of function with variable argument lists inside SPMD block:
%   spmd
%     [varargout{1 : nargout}] = feval(fun, varargin{:});
%   end
%
%  Resulting error message:
%  ""
%  The Composite is invalid; it may have been saved and loaded,
%  which is not allowed, or the parallel pool has been shut down.
%  ""
%
% We work around this limitation by supporting a fixed maximum number
% "maxNumOutputs" (see function definition below) of input/output
% arguments and padding the actual arguments lists with additional
% (unused) arguments .
%
% To increase to N the supported number of accumulation variables:
% * In maxNumOutputs(): return N
% * In processFixedArgList(): Replace each instance of "a1, a2, ..."
%   with "a1, a2, ..., aN".
%

narginchk(3, nargin)
assert(datatypes.isfunction(fun))
assert(datatypes.isfunction(getnext))
assert(isscalar(numout) && isnumeric(numout) && 0 <= numout)
assert(0 <= numout && numout <= maxNumOutputs, ...
    'Between 0 and %u outputs are currently supported.', maxNumOutputs)

parser = inputParser;
parser.addParameter('Parameters', {}, @iscell)
parser.addParameter('Initialize', @tic, @datatypes.isfunction)
parser.addParameter('Finalize', @toc, @datatypes.isfunction)
parser.parse(varargin{numout + 1 : end})
options = parser.Results;

% Empty placeholders for unused accumulation slots
placeholders = cell(1, maxNumOutputs - numout);

% Return accumulated variables and {e.g. elapsed time on each worker}
varargout = cell(1, numout + 1);

[varargout{1 : numout}, placeholders{:}, varargout{end}] = ...
    processFixedArgList( ...
    options.Initialize, ...
    options.Finalize, ...
    fevalFixedArgList(fun, numout, options.Parameters), ...
    getnext, ...
    varargin{1 : numout}, ...
    placeholders{:});  %#ok<ASGLU>

end

% -------------------------------------------------------------------------
function n = maxNumOutputs
n = 4;
end

% -------------------------------------------------------------------------
function wrappedfun = fevalFixedArgList(fun, numout, parameters)
front = 1 : numout;
back = numout + 1 : maxNumOutputs;
    function varargout = evaluate(taskid, varargin)
        % NB: "back" before "front" to pre-allocate varargout
        varargout(back) = varargin(back);
        [varargout{front}] = feval(fun, taskid, varargin{front}, parameters{:});
    end
wrappedfun = @evaluate;
end

% -------------------------------------------------------------------------
function [a1, a2, a3, a4, elapsed] = ...
    processFixedArgList(init, final, fun, getnext, a1, a2, a3, a4)

assert(maxNumOutputs == 4)
narginchk(3 + maxNumOutputs, nargin)

% Disable warning about storing Composites inside a cell array,
% since we do not refer to such instances in the (only two) SPMD blocks
% in this function.
% ""
% Warning: A distributed array or Composite was used in the body of an
% SPMD block without appearing directly in the body of the block. This can
% happen if a distributed array or Composite is stored inside a container
% such as a cell array or structure. Distributed arrays or Composites
% stored like this will be unusable inside the body of the SPMD block.
% This warning will now be disabled, but can be re-enabled by executing
% warning on parallel:lang:spmd:RemoteTransfer.
% ""
state = warning('off', 'parallel:lang:spmd:RemoteTransfer');
cleaner = onCleanup(@() warning(state));

switch parallel.numworkers(parallel.currentpool)
    case 1
        %
        % Serial version:
        % When no slave workers are available, message passing
        % cannot be employed and we must use a separate loop.
        % Nonetheless, the (trivial) SPMD block is employed for type
        % stability of the function i.e. a Composite should still be
        % returned, albeit trivial with just one element.
        %
        spmd
            starttime = feval(init);
            while true
                [hasnext, task] = feval(getnext);
                if ~hasnext
                    break
                end
                [a1, a2, a3, a4] = fun(task, a1, a2, a3, a4);
            end
            elapsed = feval(final, starttime);
        end
        
    otherwise
        %
        % Parallel version:
        % One lab/worker is the master, the rest are slaves.
        %
        spmd
            starttime = feval(init);
            switch labindex
                case masterIndex()
                    masterLoop(getnext);
                otherwise
                    [a1, a2, a3, a4] = slaveLoop(fun, a1, a2, a3, a4);
            end
            elapsed = feval(final, starttime);
        end
        
end

end

% -------------------------------------------------------------------------
function masterLoop(getnext)
% Master worker: Allocates tasks to slave workers

RUN = runTag();
STOP = stopTag();
READY = readyTag();

numactiveslaves = numlabs - 1;

while 0 < numactiveslaves
    
    % Prepare task for next available slave...
    [hasnext, task] = feval(getnext);
    if hasnext
        tasktag = RUN;
    else
        tasktag = STOP;
    end
    
    % ... before blocking for next available slave
    [~, workeridx] = labReceive('any', READY);
    
    switch tasktag
        case RUN
        case STOP
            numactiveslaves = numactiveslaves - 1;
        otherwise
            assert(false, contracts.unreachable)
    end
    
    % Dispatch task
    labSend(task, workeridx, tasktag)
    
end

end

% -------------------------------------------------------------------------
function varargout = slaveLoop(fun, varargin)
% Slave worker: Assigned tasks by master worker

% Constants
RUN = runTag();
STOP = stopTag();
READY = readyTag();
MASTER = masterIndex();

while true
    labSend([], MASTER, READY)
    [task, ~, tasktag] = labReceive(MASTER);
    switch tasktag
        case RUN
            [varargin{:}] = fun(task, varargin{:});
        case STOP
            break
        otherwise
            assert(false, contracts.unreachable)
    end
end

varargout = varargin;

end

% -------------------------------------------------------------------------
function idx = masterIndex
idx = 1; % labindex() of the master lab/worker
end

% -------------------------------------------------------------------------
% Message tags
% * These bounds are consistent with [0, intmax('uint16')] since
%   "Valid tags have integer values in the range 0 <= tag <= 2147483647".
% * However, it seems that the Parallel Computing Toolbox requires them to
%   be of type double (uint16 doesn't work in R2017b).
function tag = readyTag
tag = 100;
end

function tag = runTag
tag = 200;
end

function tag = stopTag
tag = 300;
end
