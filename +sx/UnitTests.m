classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        numDimensions = {2, 3, 4}
        nonsingletonValue = {0, 2}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function leaddimTest(testCase, numDimensions, nonsingletonValue)
            
            testCase.assertTrue(2 <= numDimensions)
            testCase.assertTrue(1 ~= nonsingletonValue)
            
            function testFor(numSingletons, expectedLeadDim)
                
                import sx.leaddim
                
                % Test search for leading non-singleton dimension
                nonOnes = @(n) repmat(nonsingletonValue, 1, n);
                array = someArray([ ...
                    ones(1, numSingletons) ... % leading singletons
                    nonOnes(numDimensions - numSingletons) % trailing non-singletons
                    ]);
                testCase.verifyEqual( ...
                    leaddim(array), ...
                    expectedLeadDim)
                
                % Test "manual override" via optional second argument
                array = ones(1, numDimensions);
                testCase.verifyEqual( ...
                    leaddim(array, expectedLeadDim), ...
                    expectedLeadDim)
                
            end
            
            arrayfun(@testFor, 0 : numDimensions, [1 : numDimensions, 1])
            
        end
        
        function iscompatibleTest(testCase)
                        
            function testFor(shape1, shape2, expected)
                import sx.iscompatible
                testCase.verifyEqual( ...
                    iscompatible(someArray(shape1), someArray(shape2)), ...
                    expected)
            end
            
            m = 2;
            n = 3;
            
            % Scalars are compatible with anything
            testFor(1, [n n], true)
            testFor(1, [n n n], true)
            
            % 2 dimensions
            testFor([m 1], [1 1], true)
            testFor([m 1], [1 n], true)
            testFor([m 1], [n 1], false)            
            testFor([1 m], [1 1], true)
            testFor([1 m], [n 1], true)
            testFor([1 m], [1 n], false)
            testFor([m m], [n n], false)
            
            % 3 dimensions
            testFor([1 n n], [n 1], true)
            testFor([1 n n n], [n n n], true)
            
        end
        
    end
    
end

function array = someArray(varargin)
% Any generator e.g. ones/nan/rand/zeros
array = nan(varargin{:});
end
