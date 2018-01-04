function result = mexindex(varargin)
import mex.*
result = classorcast(mexindexclass, varargin{:});
