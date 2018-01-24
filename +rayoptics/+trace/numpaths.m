function n = numpaths(trace)
%NUMPATHS Number of unique paths.
n = numel(unique(trace.Data.Identifier));