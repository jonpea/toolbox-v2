function s = quote(s)
% Do note use sprintf: It would regard each Windows path separator
% as part of an escape sequence
s = strcat('"', s, '"');
