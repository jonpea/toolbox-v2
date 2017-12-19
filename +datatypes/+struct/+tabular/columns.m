function t = columns(t, varargin)
%COLUMNS Extract columns of a tabular structure.
%   COLUMNS(T,'A','B','C',...) for tabular struct T returns fields
%   T.A, T.B, T.C, ... etc. in another tabular struct.
%
%   See also TABULARROWS.

import datatypes.struct.getstruct

t = getstruct(t, varargin{:});
