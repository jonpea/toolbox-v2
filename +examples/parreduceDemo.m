function parreduceDemo(numTasks, targetDuration)
%% Demonstrates use of parllel reduce function |parreduce|

%%
narginchk(0, 3)
if nargin < 1
    numTasks = 1e3;
end
if nargin < 2
    targetDuration = parallel.numworkers(parallel.currentpool); % [seconds]
end

%%
fprintf('Running %u tasks over approx. %.2f seconds: Please wait...\n', ...
    numTasks, targetDuration)

dummies = compose('dummy%u', 1 : 3);
    function [labs, tasks] = work(taskidx, labs, tasks, varargin)
        %fprintf('taskidx = %u\n', taskidx)
        assert(isequal(dummies(:), varargin(:)))
        pause(targetDuration/numTasks)
        labs(end + 1, 1) = labindex;
        tasks(end + 1, 1) = taskidx;
    end

tasks = sequence.IndexSequence(numTasks);
    function [hasnext, next] = getNext()
        hasnext = tasks.hasnext();
        if hasnext
            next = tasks.getnext();
        else
            next = [];
        end
    end

spmd
    labIdx = zeros(0, 1);
    taskIdx = zeros(0, 1);
end

%% Process tasks in parallel
tStart = tic;
[labIdx, taskIdx, durations] = parallel.parreduce( ...
    @work, 2, @getNext, labIdx, taskIdx, 'Parameters', dummies);
actualDuration = toc(tStart);

assignments = struct( ...
    'LabIdx', vertcat(labIdx{:}), ...
    'TaskIdx', vertcat(taskIdx{:}));

%%
% Sanity check
assert(isequal(sort(assignments.TaskIdx), (1 : numTasks)'))

%% Profiling
numTasksPerWorker = accumarray( ...
    assignments.LabIdx, 1, [parallel.numworkers, 1]);

durations = vertcat(durations{:});
minDuration = min(durations);
maxDuration = max(durations);
disp('Statistics:')
disp(struct2table(struct( ...
    'LabIndex', (1 : parallel.numworkers)', ...
    'NumTasks', numTasksPerWorker, ...
    'NumTasksRelToMax', numTasksPerWorker/max(numTasksPerWorker), ...
    'Duration', durations, ...
    'DurationRelToMax', durations / maxDuration, ...
    'DurationRelToTotal', durations / actualDuration)))

%%
% Load-balance profile
numAvailableWorkers = parallel.numworkers - 1;
speedUp = targetDuration/actualDuration;
fprintf('<strong>Load balancing profile</strong>\n')
fprintf('target duration: %.2f\n', targetDuration)
fprintf('actual duration: %.2f\n', actualDuration)
fprintf('       speed-up: %.2f (cf. %u)\n', speedUp, numAvailableWorkers)
fprintf('     efficiency: %.2f%%\n', 100*speedUp/numAvailableWorkers)
fprintf('      imbalance: %.2g%% (cf. min. duration)\n', ...
    100*(maxDuration - minDuration)/minDuration)

end
