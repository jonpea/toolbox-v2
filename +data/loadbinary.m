function [contents, count] = loadbinary(fid, varargin)
%LOADBINARY Read binary data from file.
% This is simply a user-friendly version of FREAD.
% Default settings are consistent with those of FREAD.
% Example:
% >> data = loadbinary('tower8.adb', ...
%                      'InputPrecision', 'float', ...
%                      'OutputPrecision', 'double');
% See also FREAD.

parser = inputParser;
parser.addParameter('Size', inf, @(s) isround(s) && 2 <= numel(s))
parser.addParameter('InputPrecision', 'uint8', @(c) ischar(c) && exist(c)) %#ok<*EXIST>
parser.addParameter('OutputPrecision', 'double', @(c) ischar(c) && exist(c))
parser.addParameter('Skip', 0, @(n) isscalar(n) && isround(n) && 0 <= n)
parser.addParameter('MachineFormat', 'native', @ischar)
parser.parse(varargin{:})
options = parser.Results;

if ischar(fid)
    fid = fopen(fid, 'r');
    cleaner = onCleanup(@() fclose(fid));
end

[contents, count] = fread(fid, ...
    options.Size, ...
    sprintf('%s=>%s', options.InputPrecision, options.OutputPrecision), ...
    options.Skip, ...
    validatestring(options.MachineFormat, machineformat));

function result = machineformat
result = {
    'native'; % This system's byte ordering
    'ieee-be'; % Big-endian ordering
    'ieee-le'; % Little-endian ordering
    'ieee-be.l64'; % Big-endian ordering, 64-bit long data type
    'ieee-le.l64'; % Little-endian ordering, 64-bit long data type
    };
