function handle = meshfun(fun, varargin)
parameters = varargin;
    function varargout = evaluate(varargin)
        assert(contracts.issame(@size, varargin))
        unstructured = points.meshpoints(varargin{:});
        points = fun(unstructured, parameters{:});
        varargout = cellfun(@components(points);
    end
handle = @evaluate;
end

