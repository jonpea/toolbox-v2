function [newtab, alltabs] = tabbedfigure(fig, varargin)
%TABBEDFIGURE Generator for uitab elements in a figure.
% NEWTAB = TABBEDFIGURE(FIG) with figure handle FIG returns a function
% handle such that
% See also UITAB, UITABGROUP, FIGURE.

if nargin == 0 || isempty(fig)
    fig = gcf; % defaults to current figure
end

assert(isgraphics(fig, 'figure'))
assert(mod(numel(varargin), 2) == 0, ...
    'Optional arguments must appear in key-value pairs.')

% List of tab handles; captured by the inner function
tabs = [];

    function tab = makeTab(title, select)
        
        import datatypes.isfunction

        narginchk(0, 2)
        
        if isempty(tabs)
            tabs = uitabgroup(fig);
            % Set figure properties on first use: This allows for the
            % figure to remain hidden in a published script until the
            % first tab is actually added.
            set(fig, varargin{:});
        end
        
        tabIndex = numel(tabs.Children) + 1;
        
        if nargin < 1 || isempty(title)
            title = sprintf('Tab %d', tabIndex);
        elseif isfunction(title)
            title = title(tabIndex);
        end
        
        if nargin < 2 || isempty(select)
            select = true; % default value
        end
        
        assert(ischar(title) && isrow(title))
        assert(islogical(select) && isscalar(select))
        
        tab = uitab(tabs, 'Title', title);
        
        if select
            tabs.SelectedTab = tab;
        end
        
    end

    function handle = getTabs
        handle = tabs;
    end

newtab = @makeTab;
alltabs = @getTabs;

end
