function rgb = gray(intensity)
%GRAY RGB color code for gray.
%   RGBGRAY returns the RGB color code of the shade of gray
%   employed in the background of MATLAB figures.
%
%   For further information:
%   >> web(fullfile(docroot, 'matlab/ref/chartline-properties.html'))
%
% See also GRAPH2D, GRAPH3D, SPECGRAPH.

if nargin < 1
    intensity = 'figure';
end

if ischar(intensity)
    switch intensity
        case 'figure'
            % Color intensity currently used for figure backgrounds:
            % >> clf('reset'), get(gcf, 'Color')
            % ans =
            %          0.94         0.94         0.94
            intensity = 0.94;
            
        case {'axis', 'grid', 'label', 'tick'}
            % See documentation on "Axes Properties" (R2017a)
            intensity = 0.15;
            
        otherwise
            error('Unknown descriptor: %s', intensity)
            
    end
end

rgb = repmat(intensity, 1, 3);
