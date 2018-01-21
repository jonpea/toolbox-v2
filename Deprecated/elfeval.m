function elfeval(fun, varargin)
%
% See section "Querying the Interpolant" in MATLAB's documentation
% on "Interpolating Gridded Data".
%

narginchk(1, nargin)

if iscell(varargin{1})
    vectors = varargin{1};
    varargin = cell(1, numel(vectors));
    [varargin{:}] = sx.ndgrid(vectors{:});
end
