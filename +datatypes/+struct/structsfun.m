function varargout = structsfun(fun, varargin)
%STRUCTSFUN Apply a function to each field of a list of structure.
%
%   [A,B,...] = STRUCSFUN(FUN,S1,S2,...,SN,'Param1',VAL1,'Param2,VAL2)
%   generalizes STRUCTFUN to multiple scalar structs S1,S2,...,SN
%   where N >= 1.FUN is applied to the intersection of the respective
%   fields of S1,S2,...,SN i.e. these structs needn't have identical fields.
%
%   See the documentation for STRUCTFUN for descriptions of the optional
%   parameters.
%
%   See also STRUCTFUN, ARRAYFUN, CELLFUN, GETSTRUCT, SETSTRUCT.

import arguments.nargoutfor
import datafun.reduce
import datatypes.isfunction

narginchk(2, nargin)

select = cellfun(@isstruct, varargin);

assert(isfunction(fun), ...
    'The first argument must be a function handle')
assert(~any(select(find(select, 1, 'last') + 1 : end)), ...
    'Arguments that are not structures must be string-value pairs.')

structs = varargin(select);
options = varargin(~select);

assert(1 <= numel(structs), ...
    'At least one scalar struct must be listed.')
assert(all(cellfun(@ischar, options(1 : 2 : end))), ...
    'Optional arguments should be listed in name-value pairs.')

% Number of outputs suitable for this handle
numout = nargoutfor(fun, nargout);

% Compute intersection of field names of the various arguments
allNames = cellfun(@fieldnames, structs, 'UniformOutput', false);
commonNames = reduce(@intersect, allNames);
[varargout{1 : numout}] = structfun(@apply, ...
    cell2struct(commonNames, commonNames), options{:});

    function varargout = apply(name)
        values = cellfun(@(s) s.(name), structs, 'UniformOutput', false);
        [varargout{1 : nargout}] = fun(values{:});
    end

end
