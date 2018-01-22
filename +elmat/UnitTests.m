classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        array = {[], 1, 1 : 3}
        orientation = {'row', 'column'}
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
            row = rand(1, 3); % row vector
            
            % NB: Test requires that input is orthogonal to axis of rotation
            preimage = sum(null(row(:)'), 2)';
            
            rotor = elmat.rotor3(row, angle);
            image = preimage*rotor;
            
            % Rotation matrix is orthogonal
            verifyEqual(rotor'*rotor, eye(3))
            verifyEqual(norm(image), norm(preimage))
            
            % Rotation preserves angle relative to axis of rotation
            verifyEqual( ...
                dot(row, image), ...
                dot(row, preimage))
            verifyEqual(row*rotor, row)
            
            % Rotation is through the angle specified
            verifyEqual(subspace(preimage(:), image(:)), angle) % Cosine Rule
        end
        
        function insertTest(testCase, array)
            
            import elmat.insert
            value = 100;
            array = array(:)';
            for i = 1 : numel(array) + 1
                actual = insert(array, i, value);
                expected = [array(1 : i - 1), value, array(i : end)];
                testCase.verifyEqual(actual, expected)
            end
            
        end
        
    end
    
end
