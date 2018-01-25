classdef UnitTests < matlab.unittest.TestCase
    %UNITTESTESTS Unit tests for candidate facet sequences.
    
    properties (TestParameter)
        
        % Upper limit on the size of the sequence that is tested;
        % larger instances are simply skipped
        maxNumPaths = {1e5}
        
        % Number of facets in the model.
        % Ensure that {0, 1, >1} are tested
        numFacets = {0, 1, 2, 3, 6}
        
        % Note to Maintainer:
        % It is essential that we test combinations wherein:
        % 1. value is {>, ==, < } number of facets
        % 2. gaps appear
        % 3. values are not contiguous
        packet = {0, 1, 2, [0 1], [2 1 0 ], [4 0 2]}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function lengthZeroTest(testCase, numFacets)
            [numPaths, getnext] = paths(0, numFacets);
            count = lengthZeroLoop(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthOneTest(testCase, numFacets)
            [numPaths, getnext] = paths(1, numFacets);
            % count = 0;
            % for i = facets(numFacets)
            %     count = count + 1;
            %     testCase.verifyEqual(getnext(), i)
            % end
            count = lengthOneLoop(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthTwoTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(2, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         count = count + 1;
            %         testCase.verifyEqual(getnext(), [i j])
            %     end
            % end
            count = lengthTwoLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthThreeTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(3, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            %[allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             count = count + 1;
            %             testCase.verifyEqual(getnext(), [i j k])
            %         end
            %     end
            % end
            count = lengthThreeLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFourTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(4, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 count = count + 1;
            %                 testCase.verifyEqual(getnext(), [i j k l])
            %             end
            %         end
            %     end
            % end
            count = lengthFourLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFiveTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(5, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 for m = allFacetsExcept(l)
            %                     count = count + 1;
            %                     testCase.verifyEqual( ...
            %                         getnext(), [i j k l m])
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthFiveLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSixTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(6, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 for m = allFacetsExcept(l)
            %                     for n = allFacetsExcept(m)
            %                         count = count + 1;
            %                         testCase.verifyEqual( ...
            %                             getnext(), [i j k l m n])
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthSixLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSevenTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(7, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 for m = allFacetsExcept(l)
            %                     for n = allFacetsExcept(m)
            %                         for o = allFacetsExcept(n)
            %                             count = count + 1;
            %                             testCase.verifyEqual( ...
            %                                 getnext(), [i j k l m n o])
            %                         end
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthSevenLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthEightTest(testCase, numFacets, maxNumPaths)
            [numPaths, getnext] = paths(8, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % count = 0;
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 for m = allFacetsExcept(l)
            %                     for n = allFacetsExcept(m)
            %                         for o = allFacetsExcept(n)
            %                             for p = allFacetsExcept(o)
            %                                 count = count + 1;
            %                                 testCase.verifyEqual( ...
            %                                     getnext(), ...
            %                                     [i j k l m n o p])
            %                             end
            %                         end
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthEightLoops(testCase, numFacets, getnext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function multiTest(testCase, numFacets, packet)
            fprintf('multi\n')
            upperSequence = sequence.ArraySequence(packet);
            function sequence = generateLowerSequence(length)
                % Input argument is current element in "upper sequence"
                sequence = imagemethod.FacetSequence(numFacets, length);
            end
            function sequence = extractFromLower(counter, length, sequence)
                contracts.unused(counter, length)
            end
            tasks = sequence.NestedSequence( ...
                upperSequence, ...
                @generateLowerSequence, ...
                @extractFromLower);
            loops = {
                @lengthZeroLoop
                @lengthOneLoop
                @lengthTwoLoops
                @lengthThreeLoops
                @lengthFourLoops
                @lengthFiveLoops
                @lengthSixLoops
                @lengthSevenLoops
                @lengthEightLoops
                };
            function runLoop(loopLength)
                feval(loops{1 + loopLength}, ...
                    testCase, numFacets, @tasks.getnext);
            end
            arrayfun(@runLoop, packet)
            testCase.verifyFalse(tasks.hasnext())
        end
        
    end
    
end

function [allFacets, allFacetsExcept] = facets(numFacets)
allFacets = 1 : numFacets;
allFacetsExcept = @(i) setdiff(allFacets, i);
end

function [numPaths, getnext] = paths(length, numFacets)
import rayoptics.imagemethodcardinality
import rayoptics.imagemethodsequence
numPaths = imagemethodcardinality(numFacets, length);
counter = 0;
    function path = getNext
        counter = counter + 1;
        path = rayoptics.imagemethodsequence(counter, numFacets, length);
    end
getnext = @getNext;
end

function skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
testCase.assumeLessThan(numPaths, maxNumPaths, sprintf( ...
    'With numFacets=%u, numPaths=%u exceeds maxNumPaths=%u.', ...
    numFacets, numPaths, maxNumPaths))
end

% -------------------------------------------------------------------------
function count = lengthZeroLoop(testCase, numFacets, getnext)
% A single direct path - no facet interaction
count = 1;
actual = getnext();
expected = [];
% Here, we treat 0x0, 0x1, and 1x0 etc. as equivalent
testCase.verifyEqual(actual(:), expected(:));
contracts.unused(numFacets)
end

function count = lengthOneLoop(testCase, numFacets, getnext)
count = 0;
for i = facets(numFacets)
    count = count + 1;
    testCase.verifyEqual(getnext(), i)
end
end

function count = lengthTwoLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        count = count + 1;
        testCase.verifyEqual(getnext(), [i j])
    end
end
end

function count = lengthThreeLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            count = count + 1;
            testCase.verifyEqual(getnext(), [i j k])
        end
    end
end
end

function count = lengthFourLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                count = count + 1;
                testCase.verifyEqual(getnext(), [i j k l])
            end
        end
    end
end
end

function count = lengthFiveLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    count = count + 1;
                    testCase.verifyEqual(getnext(), [i j k l m])
                end
            end
        end
    end
end
end

function count = lengthSixLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    for n = allFacetsExcept(m)
                        count = count + 1;
                        testCase.verifyEqual(getnext(), [i j k l m n])
                    end
                end
            end
        end
    end
end
end

function count = lengthSevenLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    for n = allFacetsExcept(m)
                        for o = allFacetsExcept(n)
                            count = count + 1;
                            testCase.verifyEqual( ...
                                getnext(), [i j k l m n o])
                        end
                    end
                end
            end
        end
    end
end
end

function count = lengthEightLoops(testCase, numFacets, getnext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    for n = allFacetsExcept(m)
                        for o = allFacetsExcept(n)
                            for p = allFacetsExcept(o)
                                count = count + 1;
                                testCase.verifyEqual( ...
                                    getnext(), [i j k l m n o p])
                            end
                        end
                    end
                end
            end
        end
    end
end
end
