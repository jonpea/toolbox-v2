function t = tabularnormalize(t)
%TABULARNORMALIZE Expands singleton rows of a tabular struct.
% TABULARNORMALIZE(S) returns a bone fide tabular struct if S would
% be tabular but for a subset of its columns that contain single rows.
maxnumrows = max(structfun(@(a) size(a, 1), t));
t = structfun(@expand, t, 'UniformOutput', false);
    function a = expand(a)
        if size(a, 1) == 1
            if isfunction(a)
                % Nonscalar arrays of function handles are not allowed 
                % by MATLAB: Cell arrays must be used instead
                a = {a}; 
            end
            a = repmat(a, maxnumrows, 1);
        end
    end
end
