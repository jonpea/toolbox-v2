function [handle, fig] = tabbedaxes(varargin)
%TABBEDAXES 
%   See also GRAPHICS.TABBEDFIGURE.

[fig, varargin] = arguments.parsefirst( ...
    @(h) isgraphics(h, 'figure'), gcf, 0, varargin{:});

% By default, hide the figure...
fig.Visible = 'off'; 

% The caller can override initial visibility here
set(fig, varargin{:})

% ... until first use
newtab = graphics.tabbedfigure(fig, 'Visible', 'on'); 

    function ax = newAxes(tabtitle)
        ax = axes(newtab(tabtitle));
    end

handle = @newAxes;

end
