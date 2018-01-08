function result = loadcolumns(filename, format, separator)
%LOADCOLUMNS Read columnar data from a text file.
% Example:
%
% >> type loadcolumns.txt
% 
% name   height   active
% (char) (double) (logical)
% -------------------------
% Alice   1.65     1
% Belinda 1.72     0
% Carey   1.81     1
% 
% >> tabulardisp(loadcolumns('loadcolumns.txt', '%s %f %d', '-'))
%       name      height    active
%     ________    ______    ______
%     'George'    1.65      1     
%     'Alice'     1.72      0     
%     'Steven'    1.81      1     
%

narginchk(2, 3)
if nargin < 3 || isempty(separator)
    separator = '--';
end
assert(ischar(format))

[fid, cleaner] = iofun.fopen(filename, 'r'); %#ok<ASGLU>
headings = data.scanheader(fid);

% Chomp lines to separator
header = fgetl(fid);
while ~contains(header, separator)
    header = fgetl(fid);
end

columns = textscan(fid, format, 'HeaderLines', 0);
result = cell2struct(columns(:), headings(:), 1);

