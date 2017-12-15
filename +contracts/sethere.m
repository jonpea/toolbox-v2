function cleaner = sethere(handle, varargin)
%SETHERE Temporarily modify the state of a handle.
%   CLEANER = SETHERE(H,NAME,VALUE) sets the property NAME of handle H to
%   VALUE temporarily in the current context; the state is restored
%   automatically once CLEANER goes out of scope and is deleted.
%
%   See also SET, ONCLEANUP.

narginchk(1, nargin)
nargoutchk(1, 1) % force client to store instance of onCleanup

currentstate = get(handle);
cleaner = onCleanup(@() set(handle, currentstate));
set(handle, varargin{:})
