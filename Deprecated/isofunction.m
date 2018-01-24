function evaluator = isofunction(gain)

if nargin < 1 || isempty(gain)
    gain = 0.0;
end

gain = gain(:);

if isscalar(gain)
    % One coefficient common to all faces
    evaluator = @evaluate;
else
    % Coefficients assigned to individual faces
    evaluator = @evaluateeach;
    %[uniquegain, ~, facetogain] = unique(gain);
end

    function result = evaluateeach(rows, varargin)
        result = gain(rows, :);
        %result = uniquegain(facetogain(rows, :), :);
    end

    function result = evaluate(rows, varargin)
        result = repmat(gain, numel(rows), 1);
    end

end
