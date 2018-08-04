function xyz = components(xyz)

import contracts.issame

narginchk(1, 1)

if iscell(xyz)
    % Already in component form
    assert(all(cellfun(@isnumeric, xyz)))
    assert(ismember(numel(xyz), 2 : 3))
    assert(issame(@size, xyz{:}))
    return
end

if isnumeric(xyz)
    assert(ismatrix(xyz))
    assert(ismember(size(xyz, 2), 2 : 3))
    xyz = num2cell(xyz, 1);
    return
end

if isgraphics(xyz) % patch | 
    if isempty(xyz.ZData)
        xyz = {xyz.XData, xyz.YData};
    else
        xyz = {xyz.XData, xyz.YData, xyz.ZData};
    end
    return
end

error(contracts.msgid(mfilename, 'UnsupportedType'), ...
    'Arguments of type %s are not currently supported.', class(xyz))
