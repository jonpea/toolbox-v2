function [handle, fig] = tabbedaxes(varargin)
%TABBEDAXES
%   See also GRAPHICS.TABBEDFIGURE.

[fig, varargin] = arguments.parsefirst( ...
    @(h) isgraphics(h, 'figure'), gcf, 0, varargin{:});

set(fig, ...
    'Visible', 'off', ... % by default, hide the figure... [*]
    varargin{:}); % (or override visility here)

% [*] ... until first use
newtab = graphics.tabbedfigure(fig, 'Visible', 'on');

    function ax = newAxes(tabTitle)
        ax = axes(newtab(tabTitle));
    end

handle = @newAxes;

end
