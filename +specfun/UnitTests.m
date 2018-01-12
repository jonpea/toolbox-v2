classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        
        % Arrays of dimension 2 to 4
        sz1 = {0, 1, 4}
        sz2 = {0, 1, 4}
        sz3 = {0, 1, 4}
        sz4 = {0, 1, 4}
        
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
            actual = specfun.cross(a, b, dim);
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
            actual = specfun.cross(a, b, dim);
            [aa, bb] = sx.expand(a, b);
            expected = cross(aa, bb, dim);
            testCase.verifyEqual(actual, expected)
            
        end
        
        function wrapcircleTest(testCase)
            
            % Our interval is [0, full)
            full = 1 + rand; % an arbitrary non-zero value
            
            function verifyequal(input, expected)
                testCase.verifyEqual( ...
                    specfun.wrapcircle(input, full), ...
                    expected, ...
                    'AbsTol', 1e-14);
            end
            
            % Limits
            verifyequal(0.0, 0.0)
            verifyequal(full, 0.0)
            
            % Interval
            delta = 10*eps(full);
            interval = linspace(0, full - delta); % i.e. [0, full)
            verifyequal(interval, interval)
            
            % Wrapping
            verifyequal(interval + full, interval)
            verifyequal(interval + 2*full, interval)
            
        end
        
        function wrapintervalTest(testCase)
            
            % Our interval is [lower, upper)
            lower = -rand;
            upper = rand;
            
            function verifyequal(input, expected)
                testCase.verifyEqual( ...
                    specfun.wrapinterval(input, lower, upper), ...
                    expected, ...
                    'AbsTol', 1e-12);
            end
            
            % Limits
            verifyequal(lower, lower)
            verifyequal(upper, lower)
            
            % Interval
            width = upper - lower;
            delta = 10*eps(width);
            interval = linspace(lower, upper - delta);
            verifyequal(interval, interval)
            
            % Wrapping
            verifyequal(interval - 2*width, interval)
            verifyequal(interval - width, interval)
            verifyequal(interval + width, interval)
            verifyequal(interval + 2*width, interval)
            
        end
        
        function wrapquadrantTest(testCase)
            
            full = 1 + rand; % an arbitrary non-zero value
            
            function verifyequal(input, expected)
                testCase.verifyEqual( ...
                    specfun.wrapquadrant(input, full), ...
                    expected, ...
                    'AbsTol', 1e-14);
            end
            
            zero = 0.0;
            half = full/2;
            quarter = full/4;
            
            % Limits
            verifyequal(zero, zero)
            verifyequal(quarter, quarter)
            verifyequal(half, zero)
            verifyequal(1.5*half, quarter)
            verifyequal(full, zero)
            
            % Interval
            interval = linspace(0.0, quarter);
            verifyequal(interval, interval)
            
            % Wrapping
            verifyequal(interval + quarter, fliplr(interval))
            
        end
        
    end
    
end
