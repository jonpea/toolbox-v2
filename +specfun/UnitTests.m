classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
                
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