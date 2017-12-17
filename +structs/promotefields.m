function s = promotefields(s, fields)
%PROMOTEFIELDS Set leading fields of a structure array.
%   SNEW = PROMOTFIELDS(S,{'F1','F2',...}) orders the fields of struct S
%   such that FIELDNAMES(SNEW) starts with {'F1';'F2';...}.
%   The remaining fields of S appear in the same order in SNEW.
%
%   SNEW = PROMOTEFIELDS(S,SS) where SS is a another struct promotes the
%   fields of S that also appear in SS. Fields of SS that are not
%   present in S are ignored.
%
%   SNEW = PROMOTEFIELDS(S,IDX) orders the fields in S so the leading
%   fields in the new structure SNEW are those at indices IDX of
%   FIELDNAMES(S). Any remaining fields of S follow in SNEW.
%
%   See also ORDERFIELDS.

import contracts.msgid

narginchk(2, 2)

allfields = fieldnames(s);

if isstruct(fields)
    otherfields = fieldnames(fields);
    [~, indices] = intersect(otherfields, allfields);
    fields = otherfields(sort(indices));
    
elseif isnumeric(fields)
    assert(all(1 <= fields & fields <= numel(allfields)))
    [~, indices] = unique(fields);
    fields = allfields(fields(sort(indices)));
    
elseif islogical(fields)
    assert(numel(fields) == numel(allfields))
    fields = allfields(fields);
    
elseif ~iscellstr(fields)
    % The identifier and message are copied from ORDERFIELDS
    error( ...
        msgid(mfilename, 'InvalidArg2'), ...
        ['Second argument must be a struct, a cell array' ...
        ' of character vectors, or a permutation vector.'])
end

[tailfields, indices] = setdiff(allfields, fields);
s = orderfields(s, [fields(:); tailfields(sort(indices))]);
