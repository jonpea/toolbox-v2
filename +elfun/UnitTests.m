classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        className = {'single', 'double'}
        numPeriods = {3}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function sawTest(testCase, className, numPeriods)
            
            period = cast(2.0, className);
            delta = absTol(className);
            
            % Points on interior of principal half-period
            x0 = cast(linspace(delta, 0.5*period - delta), className);
            
            for i = 0 : numPeriods
                
                testCase.verifyEqual( ...
                    elfun.saw(x0 + i*period), x0, ...
                    'AbsTol', absTol(className));
                
                testCase.verifyEqual( ...
                    elfun.saw(-x0 - i*period), -x0, ...
                    'AbsTol', absTol(className));
            end
            
        end
        
        function triTest(testCase, className, numPeriods)
            
            period = cast(2.0, className);
            delta = absTol(className);
            
            % Points on interior of principal half-period
            x0 = cast(linspace(delta, 0.5*period - delta), className);
            
            for i = 0 : numPeriods
                
                testCase.verifyEqual( ...
                    elfun.tri(x0 + i*period), x0, ...
                    'AbsTol', absTol(className));
                
                testCase.verifyEqual( ...
                    elfun.tri(-x0 - i*period), x0, ...
                    'AbsTol', absTol(className));
                
            end
        end
        
    end
    
end

function tol = absTol(className)
tol = 100*eps(className);
end
