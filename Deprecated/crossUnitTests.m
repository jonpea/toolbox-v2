classdef crossUnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        % Arrays of dimension 2 to 4
        % NB: CROSS requires that one dimension is equal to 3.
        sz1 = {0, 1, 5}
        sz2 = {0, 1, 5}
        sz3 = {0, 1, 5}
        sz4 = {0, 1, 5}
        
        % Dimension of application, including one greater than the
        % max number of actually dimensions (which always has size 1).
        dim = {1, 2, 3, 4, 5}
        
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function crossStandardTest(testCase, sz1, sz2, sz3, sz4, dim)
            
            % Shape of operand arrays
            shape = [sz1, sz2, sz3, sz4];
            
            % Ensure that CROSS can be applied in specified dimension
            shape(dim) = 3;
            
            % Generate (arbitrary) conforming operands
            elements = 1 : prod(shape);
            a = reshape(elements, shape);
            b = reshape(fliplr(elements), shape);
            
            % Compare with MATLAB's built-in function
            actual = matfun.cross(a, b, dim);
            expected = cross(a, b, dim);            
            testCase.verifyEqual(actual, expected)
            
        end
        
        function crossSingletonTest(testCase, sz1, sz2, sz3, sz4, dim)
            
            % First operand, arbitrary values
            aShape = [sz1, sz2, sz3, sz4];
            aShape(dim) = 3; % safe for CROSS
            a = reshape(1 : prod(aShape), aShape);

            % Second operand is singleton in the non-zero dimensions
            bShape = zeros(size(aShape));
            bShape(aShape ~= 0) = 1;
            bShape(dim) = 3;
            b = reshape(1 : prod(bShape), bShape); % either "1:0" or "1:3"

            % Compare with MATLAB's built-in function
            actual = matfun.cross(a, b, dim);
            [aa, bb] = sx.expand(a, b);
            expected = cross(aa, bb, dim);
            testCase.verifyEqual(actual, expected)
            
        end
        
    end
    
end
