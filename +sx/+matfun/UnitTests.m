classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        % Vector norms, including min/max norm
        p = {1, 2, 3, -inf, inf} 
        
        % Arrays of dimension 2 to 4
        sz1 = {0, 1, 3}
        sz2 = {0, 1, 3}
        sz3 = {0, 1, 3}
        sz4 = {1, 1, 3}
        
        % Dimension of application, including one greater than the 
        % max number of actually dimensions (which always has size 1).
        dim = {1, 2, 3, 4, 5}
        
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function normTest(testCase, p, sz1, sz2, sz3, sz4, dim)
            a = data(sz1, sz2, sz3, sz4);
            actual = sx.matfun.norm(a, p, dim);
            expected = cellfun(@(v) norm(squeeze(v), p), num2cell(a, dim));
            if 1e-6 < norm(actual(:) - expected(:))
               []; 
            end
            testCase.verifyEqual(actual, expected, ...
                'AbsTol', 1e-10, 'RelTol', 1e-10)
        end
        
        function unitTest(testCase, sz1, sz2, sz3, sz4, dim)
            a = data(sz1, sz2, sz3, sz4);
            actual = sx.matfun.unit(a, dim);
            norms = cellfun(@(v) norm(squeeze(v)), num2cell(a, dim));
            expected = a./norms;
            testCase.verifyEqual(actual, expected, 'AbsTol', 1e-10)
        end
        
    end
    
end

function a = data(varargin)
shape = cell2mat(varargin);
a = reshape(1 : prod(shape), shape);
end
