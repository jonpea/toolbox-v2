classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function todbTest(testCase)
            import elfun.todb
            testCase.verifyEqual(todb(1, 100), -20)
            testCase.verifyEqual(todb(1, 10), -10)
            testCase.verifyEqual(todb(1), 0)
            testCase.verifyEqual(todb(10), 10)
            testCase.verifyEqual(todb(100), 20)
        end
        
        function fromdbTest(testCase)
            import elfun.fromdb
            testCase.verifyEqual(fromdb(-20, 100), 1)
            testCase.verifyEqual(fromdb(-10, 10), 1)
            testCase.verifyEqual(fromdb(0), 1)
            testCase.verifyEqual(fromdb(10), 10)
            testCase.verifyEqual(fromdb(20), 100)
        end
                
    end
    
end
