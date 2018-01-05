function headings = scanheader(fid)
%SCANHEADER String headings in the first line of a text file.
% SCANHEADER(FILENAME) and SCANHEADER(FOPEN(FILENAME)) returns a cell array
% containing the strings in the first line of the file named FILENAME.
% See also FOPEN, FCLOSE, FGETL.
if ischar(fid)
    [fid, cleaner] = openfile(fid, 'r'); %#ok<ASGLU>
end
headings = split(fgetl(fid));

% This is a work-around for inconsistent behaviour in R2016b, 
% which returns a string array rather than a cell array
headings = cellstr(headings); 
