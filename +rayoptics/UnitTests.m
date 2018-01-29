classdef UnitTests < matlab.unittest.TestCase
    %UNITTES Unit tests for candidate facet sequences.
    %   Tests that our random-access generation of candidate facet
    %   sequences matches those generated by direct loops, for sequences of
    %   uniform length and for compound sequences of varying length.
    %
    %   See also IMAGEMMETHODCARDINALITY, IMAGEMETHODSEQUENCE.
    
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
        sequenceLengths = {0, 1, 2, [0 1], [2 1 0], [4 0 2]}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function lengthZeroTest(testCase, numFacets)
            [numPaths, getNext] = paths(0, numFacets);
            count = lengthZeroLoop(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthOneTest(testCase, numFacets)
            [numPaths, getNext] = paths(1, numFacets);
            count = lengthOneLoop(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthTwoTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(2, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthTwoLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthThreeTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(3, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthThreeLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFourTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(4, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthFourLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFiveTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(5, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthFiveLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSixTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(6, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthSixLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSevenTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(7, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthSevenLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthEightTest(testCase, numFacets, maxNumPaths)
            [numPaths, getNext] = paths(8, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            count = lengthEightLoops(testCase, numFacets, getNext);
            testCase.verifyEqual(numPaths, count)
        end
        
        function multiTest(testCase, numFacets, sequenceLengths)
            allTasks = rayoptics.taskSequence(numFacets, sequenceLengths);
            function sequence = getNext
                % Modifies interface to conform to other tests
                task = allTasks.getnext();
                [counter, sequence] = task{:};
                arguments.unused(counter)
            end
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
            function runLoop(sequenceLength)
                feval(loops{1 + sequenceLength}, ...
                    testCase, numFacets, @getNext);
            end
            arrayfun(@runLoop, sequenceLengths)
            testCase.verifyFalse(allTasks.hasnext())
        end
        
    end
    
end

function [allFacets, allFacetsExcept] = facets(numFacets)
allFacets = 1 : numFacets;
allFacetsExcept = @(i) setdiff(allFacets, i);
end

function [numPaths, getNext] = paths(length, numFacets)
import rayoptics.imagemethodcardinality
import rayoptics.imagemethodsequence
numPaths = imagemethodcardinality(numFacets, length);
counter = 0;
    function path = getNextSequence
        counter = counter + 1;
        path = rayoptics.imagemethodsequence(counter, numFacets, length);
    end
getNext = @getNextSequence;
end

function skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
testCase.assumeLessThan(numPaths, maxNumPaths, sprintf( ...
    'With numFacets=%u, numPaths=%u exceeds maxNumPaths=%u.', ...
    numFacets, numPaths, maxNumPaths))
end

% -------------------------------------------------------------------------
function count = lengthZeroLoop(testCase, numFacets, getNext)
% A single direct path - no facet interaction
count = 1;
actual = getNext();
expected = [];
% Here, we treat 0x0, 0x1, and 1x0 etc. as equivalent
testCase.verifyEqual(actual(:), expected(:));
arguments.unused(numFacets)
end

function count = lengthOneLoop(testCase, numFacets, getNext)
count = 0;
for i = facets(numFacets)
    count = count + 1;
    testCase.verifyEqual(getNext(), i)
end
end

function count = lengthTwoLoops(testCase, numFacets, getNext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        count = count + 1;
        testCase.verifyEqual(getNext(), [i j])
    end
end
end

function count = lengthThreeLoops(testCase, numFacets, getNext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            count = count + 1;
            testCase.verifyEqual(getNext(), [i j k])
        end
    end
end
end

function count = lengthFourLoops(testCase, numFacets, getNext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                count = count + 1;
                testCase.verifyEqual(getNext(), [i j k l])
            end
        end
    end
end
end

function count = lengthFiveLoops(testCase, numFacets, getNext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    count = count + 1;
                    testCase.verifyEqual(getNext(), [i j k l m])
                end
            end
        end
    end
end
end

function count = lengthSixLoops(testCase, numFacets, getNext)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    for n = allFacetsExcept(m)
                        count = count + 1;
                        testCase.verifyEqual(getNext(), [i j k l m n])
                    end
                end
            end
        end
    end
end
end

function count = lengthSevenLoops(testCase, numFacets, getNext)
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
                                getNext(), [i j k l m n o])
                        end
                    end
                end
            end
        end
    end
end
end

function count = lengthEightLoops(testCase, numFacets, getNext)
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
                                    getNext(), [i j k l m n o p])
                            end
                        end
                    end
                end
            end
        end
    end
end
end
