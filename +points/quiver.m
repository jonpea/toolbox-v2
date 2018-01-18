function varargout = quiver(varargin)
%QUIVER Quiver plot.
%   QUIVER(X,V) plots velocity vectors as arrows with components V
%   at the points X.  The matrices X,V must have either 2 or 3 columns and
%   must have identical size and contain corresponding position and
%   velocity components. QUIVER automatically scales the arrows to fit
%   within the grid. 
%    
%   QUIVER(X,V,S) automatically scales the arrows to fit within the 
%   grid and then stretches them by S.  Use S=0 to plot the arrows 
%   without the automatic scaling. 
%
%   QUIVER(AX,...) plots into AX instead of GCA.
%
%   See also QUIVER, PLOT.

[~, xyz, ~] = arguments.parsefirst(@datatypes.isaxes, gca, 1, varargin{:});

assert(ismatrix(xyz))
assert(isnumeric(xyz))
assert(ismember(size(xyz, 2), 2 : 3))

switch size(xyz, 2)
    case 2
        plotter = @quiver;
    case 3
        plotter = @quiver3;
end

[varargout{1 : nargout}] = binary(plotter, varargin{:});
