function h = heights(s)
import elmat.nrows
h = unique(structfun(@nrows, s));
