classdef UnitTests < matlab.unittest.TestCase
    %UNITTESTESTS Unit tests for candidate facet sequences.
    
    properties (TestParameter)
        maxNumPaths = {1e5}
        numFacets = {0, 1, 2, 3, 5, 8}
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function arityOneTest(testCase, numFacets)
            [numPaths, path] = paths(1, numFacets);
            % count = 0;
            % for i = facets(numFacets)
            %     count = count + 1;
            %     testCase.verifyEqual(path(count), i)
            % end
            count = arityOne(testCase, numFacets, path, 0);
            testCase.verifyEqual(numPaths, count)
        end
        
        function arityTwoTest(testCase, numFacets, maxNumPaths)
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
            count = arityTwo(testCase, numFacets, path, 0);
            testCase.verifyEqual(numPaths, count)
        end
        
        function arityThreeTest(testCase, numFacets, maxNumPaths)
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
            count = arityThree(testCase, numFacets, path, 0);
            testCase.verifyEqual(numPaths, count)
        end
        
        %         function arityFourTest(testCase, numFacets, maxNumPaths)
        %             [numPaths, path] = paths(4, numFacets);
        %             skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
        %             [allFacets, allFacetsExcept] = facets(numFacets);
        %             count = 0;
        %             for i = allFacets
        %                 for j = allFacetsExcept(i)
        %                     for k = allFacetsExcept(j)
        %                         for l = allFacetsExcept(k)
        %                             count = count + 1;
        %                             testCase.verifyEqual(path(count), [i j k l])
        %                         end
        %                     end
        %                 end
        %             end
        %             testCase.verifyEqual(numPaths, count)
        %         end
        %
        %         function arityFiveTest(testCase, numFacets, maxNumPaths)
        %             [numPaths, path] = paths(5, numFacets);
        %             skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
        %             [allFacets, allFacetsExcept] = facets(numFacets);
        %             count = 0;
        %             for i = allFacets
        %                 for j = allFacetsExcept(i)
        %                     for k = allFacetsExcept(j)
        %                         for l = allFacetsExcept(k)
        %                             for m = allFacetsExcept(l)
        %                                 count = count + 1;
        %                                 testCase.verifyEqual( ...
        %                                     path(count), [i j k l m])
        %                             end
        %                         end
        %                     end
        %                 end
        %             end
        %             testCase.verifyEqual(numPaths, count)
        %         end
        %
        %         function aritySixTest(testCase, numFacets, maxNumPaths)
        %             [numPaths, path] = paths(6, numFacets);
        %             skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
        %             [allFacets, allFacetsExcept] = facets(numFacets);
        %             count = 0;
        %             for i = allFacets
        %                 for j = allFacetsExcept(i)
        %                     for k = allFacetsExcept(j)
        %                         for l = allFacetsExcept(k)
        %                             for m = allFacetsExcept(l)
        %                                 for n = allFacetsExcept(m)
        %                                     count = count + 1;
        %                                     testCase.verifyEqual( ...
        %                                         path(count), [i j k l m n])
        %                                 end
        %                             end
        %                         end
        %                     end
        %                 end
        %             end
        %             testCase.verifyEqual(numPaths, count)
        %         end
        %
        %         function aritySevenTest(testCase, numFacets, maxNumPaths)
        %             [numPaths, path] = paths(7, numFacets);
        %             skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
        %             [allFacets, allFacetsExcept] = facets(numFacets);
        %             count = 0;
        %             for i = allFacets
        %                 for j = allFacetsExcept(i)
        %                     for k = allFacetsExcept(j)
        %                         for l = allFacetsExcept(k)
        %                             for m = allFacetsExcept(l)
        %                                 for n = allFacetsExcept(m)
        %                                     for o = allFacetsExcept(n)
        %                                         count = count + 1;
        %                                         testCase.verifyEqual( ...
        %                                             path(count), [i j k l m n o])
        %                                     end
        %                                 end
        %                             end
        %                         end
        %                     end
        %                 end
        %             end
        %             testCase.verifyEqual(numPaths, count)
        %         end
        %
        %         function arityEightTest(testCase, numFacets, maxNumPaths)
        %             [numPaths, path] = paths(8, numFacets);
        %             skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
        %             [allFacets, allFacetsExcept] = facets(numFacets);
        %             count = 0;
        %             for i = allFacets
        %                 for j = allFacetsExcept(i)
        %                     for k = allFacetsExcept(j)
        %                         for l = allFacetsExcept(k)
        %                             for m = allFacetsExcept(l)
        %                                 for n = allFacetsExcept(m)
        %                                     for o = allFacetsExcept(n)
        %                                         for p = allFacetsExcept(o)
        %                                             count = count + 1;
        %                                             testCase.verifyEqual( ...
        %                                                 path(count), ...
        %                                                 [i j k l m n o p])
        %                                         end
        %                                     end
        %                                 end
        %                             end
        %                         end
        %                     end
        %                 end
        %             end
        %             testCase.verifyEqual(numPaths, count)
        %         end
        %
    end
    
end

function [allFacets, allFacetsExcept] = facets(numFacets)
allFacets = 1 : numFacets;
allFacetsExcept = @(i) setdiff(allFacets, i);
end

function [numPaths, path] = paths(arity, numFacets)
import rayoptics.imagemethodcardinality
import rayoptics.imagemethodsequence
numPaths = imagemethodcardinality(numFacets, arity);
path = @(i) imagemethodsequence(i, numFacets, arity);
end

function skipExpensiveTest(testCase, numFacets, numPaths, maxNumPaths)
testCase.assumeLessThan(numPaths, maxNumPaths, sprintf( ...
    'With numFacets=%u, numPaths=%u exceeds maxNumPaths=%u.', ...
    numFacets, numPaths, maxNumPaths))
end

% -------------------------------------------------------------------------
function count = arityOne(testCase, numFacets, path, count)
for i = facets(numFacets)
    count = count + 1;
    testCase.verifyEqual(path(count), i)
end
end

function count = arityTwo(testCase, numFacets, path, count)
[allFacets, allFacetsExcept] = facets(numFacets);
for i = allFacets
    for j = allFacetsExcept(i)
        count = count + 1;
        testCase.verifyEqual(path(count), [i j])
    end
end
end

function count = arityThree(testCase, numFacets, path, count)
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
