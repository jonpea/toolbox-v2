function msg = unreachable
%UNREACHABLE For use in guards of OTHERWISE branches.
%   UNREACHABLE returns mesage string suitable for use in assertion guards
%   on the OTHERWISE branch of SWITCH blocks whose other branches are
%   believed to be exhaustive.
%
%   Example:
%     switch lower(tasktag)
%         case 'run'
%             x = update(x);
%         case 'stop'
%             break
%         otherwise
%             assert(false, unreachable)
%     end
%
%   See also ASSERT, SWITCH, OTHERWISE.

msg = 'Executed line was marked unreachable';
