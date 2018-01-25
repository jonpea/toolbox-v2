classdef UnitTests < matlab.unittest.TestCase
    %UNITTESTESTS Unit tests for candidate facet sequences.
    
    properties (TestParameter)
        maxNumPaths = {1e5}
        %numFacets = {1, 2, 3} %, 5} %, 8}
        %packet = {[0 1], [2 1], [1 2]}
        numFacets = {1}
        packet = {[1 2]}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
%{
        function lengthZeroTest(testCase, numFacets)
            [numPaths, path] = paths(0, numFacets);
            count = lengthZeroLoop(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthOneTest(testCase, numFacets)
            [numPaths, path] = paths(1, numFacets);
            % count = 0;
            % for i = facets(numFacets)
            %     count = count + 1;
            %     testCase.verifyEqual(path(count), i)
            % end
            count = lengthOneLoop(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthTwoTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(2, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         count = count + 1;
            %         testCase.verifyEqual(path(count), [i j])
            %     end
            % end
            count = lengthTwoLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthThreeTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(3, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            %[allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             count = count + 1;
            %             testCase.verifyEqual(path(count), [i j k])
            %         end
            %     end
            % end
            count = lengthThreeLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFourTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(4, numFacets);
            skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
            % count = 0;
            % [allFacets, allFacetsExcept] = facets(numFacets);
            % for i = allFacets
            %     for j = allFacetsExcept(i)
            %         for k = allFacetsExcept(j)
            %             for l = allFacetsExcept(k)
            %                 count = count + 1;
            %                 testCase.verifyEqual(path(count), [i j k l])
            %             end
            %         end
            %     end
            % end
            count = lengthFourLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthFiveTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(5, numFacets);
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
            %                         path(count), [i j k l m])
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthFiveLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSixTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(6, numFacets);
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
            %                             path(count), [i j k l m n])
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthSixLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthSevenTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(7, numFacets);
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
            %                                 path(count), [i j k l m n o])
            %                         end
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthSevenLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
        
        function lengthEightTest(testCase, numFacets, maxNumPaths)
            [numPaths, path] = paths(8, numFacets);
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
            %                                     path(count), ...
            %                                     [i j k l m n o p])
            %                             end
            %                         end
            %                     end
            %                 end
            %             end
            %         end
            %     end
            % end
            count = lengthEightLoops(testCase, numFacets, path);
            testCase.verifyEqual(numPaths, count)
        end
%}

        function multiTest(testCase, numFacets, packet)
            fprintf('--- numFacets: %u, packet: %s ---\n', numFacets, mat2str(packet))
            upperSequence = sequence.ArraySequence(packet);
            function sequence = generateLowerSequence(length)
                % Input argument is current element in "upper sequence"
                fprintf('    new sequence of length = %u\n', length)
                sequence = imagemethod.FacetSequence(numFacets, length);
            end
            function sequence = extractFromLower(counter, length, sequence)
                contracts.unused(counter, length)
                fprintf('    counter = %u: length = %u, sequence = %s\n', ...
                    counter, length, mat2str(sequence))
            end
            tasks = sequence.NestedSequence( ...
                upperSequence, ...
                @generateLowerSequence, ...
                @extractFromLower);
            %%%
            while tasks.hasnext()
                tasks.getnext()
            end
            %%%
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
                fprintf(' -- loopLength: %u\n', loopLength)
                feval(loops{1 + loopLength}, ...
                    testCase, numFacets, @(~) tasks.getnext());
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

function [numPaths, path] = paths(length, numFacets)
import rayoptics.imagemethodcardinality
import rayoptics.imagemethodsequence
numPaths = imagemethodcardinality(numFacets, length);
path = @(i) imagemethodsequence(i, numFacets, length);
end

function skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
testCase.assumeLessThan(numPaths, maxNumPaths, sprintf( ...
    'With numFacets=%u, numPaths=%u exceeds maxNumPaths=%u.', ...
    numFacets, numPaths, maxNumPaths))
end

% -------------------------------------------------------------------------
function count = lengthZeroLoop(testCase, numFacets, path)
% A single direct path - no facet interaction
count = 1;
actual = path(count);
expected = [];
% Here, we treat 0x0, 0x1, and 1x0 etc. as equivalent
testCase.verifyEqual(actual(:), expected(:));
contracts.unused(numFacets)
end

function count = lengthOneLoop(testCase, numFacets, path)
count = 0;
for i = facets(numFacets)
    count = count + 1;
    testCase.verifyEqual(path(count), i)
end
end

function count = lengthTwoLoops(testCase, numFacets, path)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        count = count + 1;
        testCase.verifyEqual(path(count), [i j])
    end
end
end

function count = lengthThreeLoops(testCase, numFacets, path)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            count = count + 1;
            testCase.verifyEqual(path(count), [i j k])
        end
    end
end
end

function count = lengthFourLoops(testCase, numFacets, path)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                count = count + 1;
                testCase.verifyEqual(path(count), [i j k l])
            end
        end
    end
end
end

function count = lengthFiveLoops(testCase, numFacets, path)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    count = count + 1;
                    testCase.verifyEqual(path(count), [i j k l m])
                end
            end
        end
    end
end
end

function count = lengthSixLoops(testCase, numFacets, path)
count = 0;
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        for k = allFacetsExcept(j)
            for l = allFacetsExcept(k)
                for m = allFacetsExcept(l)
                    for n = allFacetsExcept(m)
                        count = count + 1;
                        testCase.verifyEqual(path(count), [i j k l m n])
                    end
                end
            end
        end
    end
end
end

function count = lengthSevenLoops(testCase, numFacets, path)
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
                                path(count), [i j k l m n o])
                        end
                    end
                end
            end
        end
    end
end
end

function count = lengthEightLoops(testCase, numFacets, path)
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
                                    path(count), [i j k l m n o p])
                            end
                        end
                    end
                end
            end
        end
    end
end
end
