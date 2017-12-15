function ndebug = ndebug(ndebug)
%NDEBUG Control selective assertions.
% NDEBUG returns FALSE if selective assertions are enabled and TRUE
% otherwise i.e. ASSERT(NDEBUG || ...) is
%      enabled when NDEBUG returns FALSE
% and disabled when NDEBUG returns TRUE.
% This behavior follows that of the C/C++ standard library
% cf. http://en.cppreference.com/w/c/error/assert.
%
% NDEBUG(TRUE) disables selective assertions.
% NDEBUG(FALSE) enables selective assertions.
%
% See also ASSERT.

persistent NDEBUG

if nargin == 0
    % Cautious default: Enable assertions
    ndebug = false;
end

if nargin == 1 || isempty(NDEBUG)
    % State needs to be set or updated
    assert(islogical(ndebug) && isscalar(ndebug))
    NDEBUG = ndebug;
end

ndebug = NDEBUG;
