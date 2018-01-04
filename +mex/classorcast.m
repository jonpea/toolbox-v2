function result = classorcast(classid, varargin)
% Example:
% >> classorcast('int32')
% ans =
%     'int32'
% >> classorcast('int32', 12.3)
% ans =
%   int32
%    12
narginchk(1, nargin)
if nargin == 1
    if datatypes.isfunction(classid)
        classid = func2str(classid);
    end
    result = classid;
else
    result = feval(classid, varargin{:});
end
