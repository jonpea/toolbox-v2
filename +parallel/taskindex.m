function id = taskindex
%TASKINDEX Rank of task object being evaluated in current worker session
%   TASKINDEX returns the ID of the task object that is currently being
%   evaluated by the worker session.
%
%   TASKINDEX returns 1 if the function is executed in a MATLAB session that
%   is not a worker (similar to the behavior of LABINDEX).
%
%   See also LABINDEX, GETCURRENTTASK.

id = get(getCurrentTask, 'ID');
if isempty(id)
    id = 1;
end

% NB: This (incorrect) alternative behaves *incorrectly* in parfor loops
% id = 1;
% if exist('labindex', 'builtin')
%     id = labindex;
% end
