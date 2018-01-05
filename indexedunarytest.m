function tests = indexedunarytest
tests = functiontests(localfunctions);
end

function test(testcase)

    function result = parentfunction(i, x, varargin)
        % This function allows for vectorized evaluation as an
        % independent check against the cell array of indexed functions.
        narginchk(2, nargin)
        assert(numel(i) == size(x, 1))
        result = i.*sumtrailing(x) + sum(cell2mat(varargin));
    end

    function functions = makefunctions(n)
        % Generates a cell array of distinct (affine-linear) functions
        functions = arrayfun( ...
            @(i) @(x, varargin) ...
            parentfunction(repmat(i, size(x, 1), 1), x, varargin{:}), ...
            1 : n, ...
            'UniformOutput', false);
    end

numcolumns = 3;
    function verify(numfunctions, map, varargin)
        x = randi(10, [numel(map), numcolumns]);
        functions = makefunctions(numfunctions);
        actual = indexedunary(functions, map, x, varargin{:});
        expected = parentfunction(map, x, varargin{:});
        testcase.verifyEqual(actual, expected)
    end

verify(0, zeros(0, 1)) % no functions
verify(1, zeros(0, 1)) % no inputs
verify(3, [2; 2; 2]) % some unused functions
verify(3, [3; 2; 1; 2; 3; 2; 1]) % non-contiguous indices

end

function result = naiveimplementation(functions, map, x, varargin)
% Naive ("obviously correct") implementatation.
assert(numel(map) == size(x, 1))
temporary = arrayfun( ...
    @(i) feval(functions{i}, x(i, :), varargin{:}), ...
    map(:), ...
    'UniformOutput', false);
result = vertcat(temporary{:});
end

function y = sumtrailing(x)
y = sum(sum(sum(x, 4), 3), 2);
end
