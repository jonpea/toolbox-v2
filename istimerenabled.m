function result = istimerenabled
%ISTIMERENABLED Returns true if stopwatch timer is enabled.
% This function is intended only for internal use.
global TIMER_IS_ENABLED
assert(isempty(TIMER_IS_ENABLED) || ...
    (islogical(TIMER_IS_ENABLED) && isscalar(TIMER_IS_ENABLED)))
result = isequal(TIMER_IS_ENABLED, true);
