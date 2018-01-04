function s = mexflag(head, tail)
s = strcat('-', head, mex.quote(tail));
