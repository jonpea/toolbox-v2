function id = msgid(varargin)
%MSGID Create message identifier from its components.
%   MSGID('COMPONENT1','COMPONENT2',...,'MNEMONIC') creates
%   a standard message identifier of the form
%    'COMPONENT1:COMPONENT2:...:MNEMONIC', 
%   suitable for use with ERROR and WARNING.
%
%  See also WARNING, ERROR.

narginchk(2, nargin)
id = cell2mat(join(varargin, ':'));
