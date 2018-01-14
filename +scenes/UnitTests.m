classdef UnitTests < matlab.unittest.TestCase
    
    properties (TestParameter)
        numdimensions = {3}
        numpoints = {10}
    end
       
    methods (Test, ParameterCombination = 'exhaustive')
        
        function mirrormexTest(testCase, numdimensions, numpoints)
            facenormal = rand(1, numdimensions);
            faceoffset = rand(1);
            points = rand(numpoints, numdimensions);
            mirrorpoints = zeros(size(points));
            
            [facenormal, scale] = unit(facenormal);
            faceoffset = faceoffset/scale;
            
            mirrorpoints = mirrorpoints';
            scenes.mirrormex(facenormal, faceoffset, points', mirrorpoints);
            mirrorpoints = mirrorpoints';
            
            projection = 0.5*(points + mirrorpoints);
            direction = unit(points - mirrorpoints);
            
            testCase.verifyEqual( ...
                projection*facenormal', ...
                repmat(faceoffset, numpoints, 1), ...
                'AbsTol', 1e-12)
            
            testCase.verifyEqual( ...
                abs(direction*facenormal'), ...
                ones(numpoints, 1), ...
                'AbsTol', 1e-12)
        end
        
    end
end

% -------------------------------------------------------------------------
function [x, normx] = unit(x)
normx = sqrt(sum(x.*x, 2));
x = x ./ normx;
end
