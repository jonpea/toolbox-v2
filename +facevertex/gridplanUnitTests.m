classdef gridplanUnitTests < matlab.unittest.TestCase
    %UNITTESTESTS Unit tests for candidate facet sequences.
    
    properties (TestParameter)
        % "1x1, Mx1, 1xN, MxN"
        numXTicks = {1, 3, 1, 3, 5}
        numYTicks = {1, 1, 3, 3, 3}
        showPlot = {false}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function basicTest(testCase, numXTicks, numYTicks, showPlot)
            
            % Arbitrary - but distinct - arrays of axis ticks
            xticks = 1 + (0 : numXTicks);
            yticks = 10 + (0 : numYTicks);
            
            [faces, vertices] = facevertex.gridplan(xticks, yticks);
            
            if showPlot
                ax = axes(figure(1));
                clf(ax, 'reset')
                hold(ax, 'on')
                axis(ax, 'equal'), axis(ax, 'off')
                patch(ax, 'Faces', faces, 'Vertices', vertices);
                points.text(ax, vertices, 'Color', 'blue')
                points.text(ax, facevertex.reduce(@mean, faces, vertices), 'Color', 'red')
                title(ax, sprintf('%ux%u', numXTicks, numYTicks))
            end
            
            % Number of line segments in each direction
            shape = [numel(xticks), numel(yticks)];
            
            % Sum of vertical- and horizontal line segments
            numfaces = sum(shape);
            
            % Note that duplicate corner points have been omitted
            numvertices = 2*(sum(shape) - 2);
            
            % Check array of faces
            testCase.verifyEqual(size(faces, 1), numfaces)
            testCase.verifyEqual(size(faces, 2), 2)
            testCase.verifyEqual(size(unique(faces, 'rows')), size(faces))
            
            % Check array of vertices
            testCase.verifyEqual(size(vertices, 1), numvertices)
            testCase.verifyEqual(size(vertices, 2), 2)
            testCase.verifyEqual(size(unique(vertices, 'rows')), size(vertices))
            
        end
    end
    
end
