function varargout = rows(a)
[varargout{1 : size(a, 2)}] = elmat.uncat(a, 1);
 
