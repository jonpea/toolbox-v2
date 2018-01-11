function varargout = cols(a)
[varargout{1 : size(a, 2)}] = elmat.uncat(a, 2);
 
