function [newtab, alltabs] = tabbedfigure(fig, varargin)
%TABBEDFIGURE Generator for uitab elements in a figure.
% NEWTAB = TABBEDFIGURE(FIG) with figure handle FIG returns a function
% handle such that
% See also UITAB, UITABGROUP, FIGURE.

if nargin == 0 || isempty(fig)
    fig = gcf;
end

assert(isgraphics(fig))
assert(mod(numel(varargin), 2) == 0)

tabs = [];

    function tab = maketab(title, select)
        
        import datatypes.isfunction

        narginchk(0, 2)
        
        if isempty(tabs)
            tabs = uitabgroup(fig);
            % Set figure properties on first use: This allows for the
            % figure to remain hidden in a published script until the
            % first tab is actually added.
            set(fig, varargin{:});
        end
        
        tabindex = numel(tabs.Children) + 1;
        
        if nargin < 1 || isempty(title)
            title = sprintf('Tab %d', tabindex);
        elseif isfunction(title)
            title = title(tabindex);
        end
        
        if nargin < 2 || isempty(select)
            select = true;
        end
        
        assert(ischar(title) && isrow(title))
        assert(islogical(select) && isscalar(select))
        
        tab = uitab(tabs, 'Title', title);
        
        if select
            tabs.SelectedTab = tab;
        end
        
    end

    function handle = gettabs
        handle = tabs;
    end

newtab = @maketab;
alltabs = @gettabs;

end
