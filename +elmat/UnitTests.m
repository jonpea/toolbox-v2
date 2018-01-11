classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function rotor2Test(testCase)
            
            function verifyEqual(actual, expected)
                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-14);
            end
            
            angle = rand;
            preimage = rand(1, 2);
            rotor = elmat.rotor2(angle);
            image = preimage*rotor;
            
            % Rotation matrix is orthogonal
            verifyEqual(rotor'*rotor, eye(2))
            verifyEqual(norm(image), norm(preimage))
            
            % Rotation is through the angle specified
            verifyEqual(subspace(preimage(:), image(:)), angle) % Cosine Rule
        end
        
        function rotor3Test(testCase)
            
            function verifyEqual(actual, expected)
                testCase.verifyEqual(actual, expected, 'AbsTol', 1e-14);
            end
            
            angle = rand;
            orientation = rand(1, 3); % row vector
            
            % NB: Test requires that input is orthogonal to axis of rotation
            preimage = sum(null(orientation(:)'), 2)';
            
            rotor = elmat.rotor3(orientation, angle);
            image = preimage*rotor;
            
            % Rotation matrix is orthogonal
            verifyEqual(rotor'*rotor, eye(3))
            verifyEqual(norm(image), norm(preimage))
            
            % Rotation preserves angle relative to axis of rotation
            verifyEqual( ...
                dot(orientation, image), ...
                dot(orientation, preimage))
            verifyEqual(orientation*rotor, orientation)
            
            % Rotation is through the angle specified
            verifyEqual(subspace(preimage(:), image(:)), angle) % Cosine Rule
        end
        
    end
    
end
