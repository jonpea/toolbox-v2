function callback = clone(fun, prototype, varargin)
%CLONE 
narginchk(2, nargin)

parameters = varargin; % re-name to prevent clash with inner varargin
    function new = cloneAndTransform(varargin)
        new = prototype;
        new.Vertices = fun(new.Vertices, varargin{:}, parameters{:});
    end
callback = @cloneAndTransform;

end
