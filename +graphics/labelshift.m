function shift = labelshift(ax, extents)
%LABELSHIFT Shift to apply to labels
% See also TEXT
scale = 3;
shift = (scale/100)*extents/get(ax, 'FontSize');
% Letters are taller than they are wide
shift(2 : end) = -1.75*shift(2 : end);
