classdef Environment < matlab.mixin.Copyable
    
    properties (Hidden = true, SetAccess = private)
        % Key WyFy arrays (legacy numeric tables)
        WallTable = zeros(0, 8)
        MobileTable = zeros(0, 13)
        AccessPointTable = zeros(0, 13)
        GHPtr = 12  % column pointer to first graphic handle
        
        % Replacements (structs)
        AccessPointList
        MobileList
        WallList
    end
    
    properties (Hidden = true, SetAccess = private)
        % Graphics handles
        AxesHandle
        ContourHandle
        FigureHandle
        LinkHandles
        TitleHandle
        
        % Verification using legacy implementation
        VerifyCalculations
        
        % Interactive state
        EditModes = interactive.EditModes.None % AccessPoint | Mobile | None
        EditRow = 0
        EditMotion = false
        
        % Internal parameters
        ClickRadius = 0.5
        ContourColorMap
    end
    
    properties (SetAccess = private)
        % Static scalar parameters
        MinimumDiscernableSignal % [dBW]
        NumContourMapSamples % >10 for reasonable results
        SINRThreshold % [dB]
        Wavelength % [m]
    end
    
    properties (SetAccess = private)
        ContourAxisRange
        DownlinkSINR
        ContourGridX
        ContourGridY
    end
    
    properties (SetAccess = private)
        % Access points and mobiles
        AccessPoints
        Mobiles
        
        % Scene geometry
        Faces
        Vertices
        Scene
        
        % Gain functions
        FreeGain
        SourceGain
        ReflectionGain
        TransmissionGain
        SinkGain
        
        % Maximum number of reflections in a ray path
        ReflectionArity
    end
    
    % Constructor
    methods (Access = public)
        
        function obj = Environment(faces, vertices, accesspoints, mobiles, varargin)
            
            warning('This class is deprecated: Use class <strong>interactive</strong> instead')
            
            narginchk(3, nargin)
            
            if nargin < 4 || isempty(mobiles)
                mobiles = vertices([], :); % no mobiles
            end
            
            assert(ismember(size(faces, 2), 2 : 3))
            assert(isround(faces))
            assert(max(faces(:)) <= size(vertices, 1))
            assert(ismember(size(vertices, 2), 2 : 3))
            assert(size(vertices, 2) == size(accesspoints, 2))
            assert(size(vertices, 2) == size(mobiles, 2))
            
            numfaces = size(faces, 1);
            numaccesspoints = size(accesspoints, 1);
            nummobiles = size(mobiles, 1);
            
            parser = inputParser;
            parser.addParameter('AccessPointGains', zeros(numaccesspoints, 1), @(g) isscalar(g) || numel(g) == numaccesspoints) % [dBW]
            parser.addParameter('AccessPointChannels', ones(numaccesspoints, 1), @(g) isscalar(g) || numel(g) == numaccesspoints)
            parser.addParameter('ContourMap', 'on', @(s) ismember(s, {'on', 'off'}))
            parser.addParameter('ContourColorMap', twocolormap, @(m) ismatrix(m) && size(m, 2) == 3)
            parser.addParameter('FigureHandle', gcf, @(h) isa(h, 'matlab.ui.Figure'))
            parser.addParameter('MinimumDiscernableSignal', minimumdiscernablesignal, @(x) isscalar(x) && x < 0) % [dBW]
            parser.addParameter('MobileGains', zeros(nummobiles, 1), @(g) isscalar(g) || numel(g) == nummobiles) % [dBW]
            parser.addParameter('NumContourMapSamples', 10, @(x) isscalar(x) && 0 < x)
            parser.addParameter('ReflectionArity', 0, @(x) isscalar(x) && 0 <= x)
            parser.addParameter('SignalFrequency', centerfrequency, @(x) isscalar(x) && 0 < x) % [1/s]
            parser.addParameter('SignalToInterferenceRatioThreshold', 10, @(x) isscalar(x) && 0 < x) % [dB]
            parser.addParameter('TransmissionGains', zeros(numfaces, 1), @(g) isvector(g) && numel(g) == numfaces) % [dB]
            parser.addParameter('VerifyCalculations', [], @(b) isscalar(b) && islogical(b))
            parser.addParameter('Wavelength', speedoflight/centerfrequency, @(lambda) isscalar(lambda) && 0 < lambda)
            parser.parse(varargin{:});
            options = parser.Results;
            
            if isempty(options.VerifyCalculations)
                % Default value depends on another options
                options.VerifyCalculations = ...
                    isequal(options.ReflectionArity, 0);
            end
            assert( ...
                ~options.VerifyCalculations || ...
                isequal(options.ReflectionArity, 0), ...
                'Legacy code does not support reflections')
            
            obj.ContourColorMap = options.ContourColorMap;
            obj.MinimumDiscernableSignal = options.MinimumDiscernableSignal;
            obj.ReflectionArity = options.ReflectionArity;
            obj.SINRThreshold = options.SignalToInterferenceRatioThreshold;
            obj.VerifyCalculations = options.VerifyCalculations;
            obj.Wavelength = options.Wavelength;
            
            % Graphics handles
            fig = options.FigureHandle;
            clf(fig, 'reset')
            ax = axes(fig, 'SortMethod', 'depth');
            obj.FigureHandle = fig;
            obj.AxesHandle = ax;
            obj.TitleHandle = title(ax, blankplaceholder, 'Parent', ax);
            
            % Initial canvas
            set(obj.FigureHandle, ...
                'Color', 'white', ...
                'WindowButtonDownFcn', {@obj.windowButtonDown})
            obj.setTitle
            xlabel(ax, 'x (m)')
            ylabel(ax, 'y (m)')
            axis(ax, 'equal')
            hold(ax, 'on')
            
            % Scene geometry
            [x1, y1, x2, y2] = facevertextolines(faces, vertices);
            arrayfun(@obj.addWall, ...
                x1(:), y1(:), x2(:), y2(:), options.TransmissionGains(:));
            % NB: Update NumContourMapSamples *before* call to @setAxesAndGrid
            obj.NumContourMapSamples = options.NumContourMapSamples;
            [obj.ContourAxisRange, obj.ContourGridX, obj.ContourGridY] = ...
                canvasbounds(vertices);
            obj.paint(@axis, obj.ContourAxisRange)
            
            function [axisrange, gridx, gridy] = canvasbounds(vertices)
                
                % Axis-aligned bounds
                function result = aggregate(fun, column)
                    result = fun(vertices(:, column));
                end
                xmin = aggregate(@min, 1);
                xmax = aggregate(@max, 1);
                ymin = aggregate(@min, 2);
                ymax = aggregate(@max, 2);
                
                % Expand ranges by a small fraction on all sides
                delta = 0.05;
                function [min, max, ticks] = expand(min, max, delta)
                    range = max - min;
                    min = min - delta*range;
                    max = max + delta*range;
                    ticks = linspace(min, max, obj.NumContourMapSamples);
                end
                [xmin, xmax, xticks] = expand(xmin, xmax, delta);
                [ymin, ymax, yticks] = expand(ymin, ymax, delta);
                axisrange = [xmin, xmax, ymin, ymax];
                [gridx, gridy] = meshgrid(xticks, yticks);
                
            end
            
            % Create contour plot for downlink SINR
            switch validatestring(options.ContourMap, {'on', 'off'})
                
                case 'off'
                    obj.ContourHandle = nullhandle;
                    
                case 'on'
                    % Disable "Contour not rendered for constant ZData"
                    state = warning;
                    warning('off', 'MATLAB:contour:ConstantData')
                    cleaner = onCleanup(@() warning(state));
                    
                    [~, obj.ContourHandle] = obj.paint(@contourf, ...
                        obj.ContourGridX, obj.ContourGridY, ...
                        zeros(size(obj.ContourGridX)), ...
                        [
                        obj.SINRThreshold - 100, ...
                        obj.SINRThreshold + 0.001
                        ]); % Watch min - may need to set to minimum of data
                    
                    colormap(obj.ContourColorMap)
                    uistack(obj.ContourHandle, 'bottom');
                    
            end
            
            % Scene geometry
            obj.Faces = faces;
            obj.Vertices = vertices;
            obj.Scene = planarmultifacet(faces, vertices);
            assert(size(obj.WallTable, 1) == size(obj.Faces, 1))
            
            % Gain functions
            obj.FreeGain = antennae.friisfunction(options.SignalFrequency);
            obj.SinkGain = isofunction(options.MobileGains);
            obj.SourceGain = isofunction(options.AccessPointGains);
            obj.TransmissionGain = isofunction(options.TransmissionGains);
            
            % Initialize access points
            obj.AccessPoints = struct( ...
                'Channel', makevector(options.AccessPointChannels, numaccesspoints), ...
                'Position', accesspoints, ...
                'Power', makevector(options.AccessPointGains, numaccesspoints));
            arrayfun( ...
                @obj.addAccessPoint, ...
                obj.AccessPoints.Position(:, 1), ...
                obj.AccessPoints.Position(:, 2), ...
                obj.AccessPoints.Power(:), ...
                obj.AccessPoints.Channel(:));
            
            % Initialize mobiles
            obj.Mobiles = struct( ...
                'Position', mobiles, ...
                'Power', makevector(options.MobileGains, nummobiles));
            arrayfun( ...
                @obj.addMobile, ...
                obj.Mobiles.Position(:, 1), ...
                obj.Mobiles.Position(:, 2), ...
                obj.Mobiles.Power);
            
            % Sanity check
            obj.checkTables
            
            % Render model
            obj.updateLinks
            obj.refreshDisplay
            
        end
        
    end
    
    % Methods for refreshing the graphical display
    methods (Access = private)
        
        function setTitle(obj, varargin)
            % Set plot title.
            if nargin == 1
                banner = blankplaceholder; % for vertical spacing
            else
                banner = sprintf(varargin{:});
            end
            set(obj.TitleHandle, 'String', banner)
        end
        
        function refreshDisplayAccessPoints(obj)
            % Refresh markers and labels of access points.
            
            obj.checkAccessPoints
            
            currentmode = obj.EditModes;
            currentidentifier = obj.EditRow;
            
            function refreshdisplay(accesspoint)
                summary = sprintf( ...
                    'AP%d(%d)', ...
                    accesspoint.Index, ...
                    accesspoint.Channel);
                if currentmode == interactive.EditModes.AccessPoint && ...
                        currentidentifier == accesspoint.Index
                    summary = sprintf( ...
                        '%s (%0.3g, %0.3g)', ...
                        summary, ...
                        accesspoint.PositionX, ...
                        accesspoint.PositionY);
                end
                set(accesspoint.MarkerHandle, ...
                    'XData', accesspoint.PositionX, ...
                    'YData', accesspoint.PositionY)
                set(accesspoint.TextHandle, ...
                    'String', summary, ...
                    'Position', shiftedposition(accesspoint))
                uistack(accesspoint.TextHandle, 'top')
            end
            
            arrayfun(@refreshdisplay, obj.AccessPointList)
            
        end
        
        function refreshDisplayMobiles(obj)
            % Refresh markers and labels of mobiles.
            
            obj.checkMobiles
            
            accesspoints = obj.AccessPointList;
            currentmode = obj.EditModes;
            currentidentifier = obj.EditRow;
            sinrthreshold = obj.SINRThreshold;
            
            function refreshdisplay(mobile)
                accesspoint = accesspoints(mobile.AccessPoint);
                if mobile.DownlinkSINR < sinrthreshold
                    % Downlink failure
                    marker = 'v';
                    color = 'red';
                elseif mobile.UplinkSINR < sinrthreshold
                    % Uplink failure
                    marker = '^';
                    color = 'red';
                else
                    % Success
                    marker = 's';
                    color = 'black';
                end
                set(mobile.MarkerHandle, 'Marker', marker, 'Color', color)
                if currentmode == interactive.EditModes.Mobile && ...
                        currentidentifier == mobile.Index
                    summary = {
                        sprintf( ...
                        'MOB%d (%0.3g, %0.3g)\\rightarrow AP%d(%0.3g)', ...
                        mobile.Index, ...
                        mobile.PositionX, ...
                        mobile.PositionY, ...
                        accesspoint.Index, ...
                        accesspoint.Channel);
                        sprintf( ...
                        '  \\downarrow Pt %0.3gdBW, Pr %0.3gdBW, I+NP %0.3gdBW, SINR %0.3gdB', ...
                        accesspoint.Power, ...
                        mobile.DownlinkReceivedPower, ...
                        mobile.DownlinkINP, ...
                        mobile.DownlinkSINR);
                        sprintf( ...
                        '  \\uparrow Pt %0.3gdBW, Pr %0.3gdBW, I+NP %0.3gdBW, SINR %0.3gdB', ...
                        mobile.TransmissionPower, ...
                        mobile.UplinkReceivedPower, ...
                        mobile.UplinkINP, ...
                        mobile.UplinkSINR);
                        };
                else
                    summary = sprintf( ...
                        'MOB%d\\rightarrow  AP%0.3g', ...
                        mobile.Index, ...
                        accesspoint.Index);
                end
                set(mobile.MarkerHandle, ...
                    'XData', mobile.PositionX, 'YData', mobile.PositionY)
                set(mobile.TextHandle, ...
                    'String', summary, ...
                    'Position', shiftedposition(mobile))
                uistack(mobile.TextHandle, 'top')
            end
            
            arrayfun(@refreshdisplay, obj.MobileList)
            
        end
        
        function refreshDisplayWalls(obj)
            % Refresh plan walls on plot.
            
            obj.checkWalls
            
            function refreshdisplay(wall)
                % Set thickness to reflect attenuation
                gain = abs(wall.Gain);
                function result = iswithin(x, lower, upper)
                    result = lower <= x && x < upper;
                end
                if iswithin(gain, 20, realmax)
                    width = 4;
                elseif iswithin(gain, 10, 20)
                    width = 3;
                elseif iswithin(gain, 5, 10)
                    width = 2;
                elseif iswithin(gain, 3, 5)
                    width = 1;
                else
                    width = 0.5;
                end
                set(wall.LineHandle, ...
                    'LineWidth', width, 'Color', rgbgray(0.6))
            end
            
            arrayfun(@refreshdisplay, obj.WallList)
            
        end
        
        function refreshDisplayLinks(obj)
            % Refresh lines depicting links between mobiles & access points.
            
            obj.checkTables
            
            % Line widths
            thin = 2;
            thick = 3;
            
            % First purge all existing links
            obj.purgeLinks
            
            function drawlink(entity1, entity2, color, width)
                obj.LinkHandles(end + 1) = obj.paint(@plot,  ...
                    [entity1.PositionX, entity2.PositionX], ...
                    [entity1.PositionY, entity2.PositionY], ...
                    'Color', color, 'LineStyle', '-', 'LineWidth', width);
            end
            
            switch obj.EditModes
                
                case interactive.EditModes.None
                    return
                    
                case interactive.EditModes.Mobile
                    mobile = obj.MobileList(obj.EditRow);
                    assignedaccesspoint = obj.AccessPointList(mobile.AccessPoint);
                    drawlink(mobile, assignedaccesspoint, 'green', thick)
                    for accesspoint = obj.AccessPointList
                        if isinterferingpair(accesspoint, assignedaccesspoint)
                            drawlink(mobile, accesspoint, 'red', thin)
                        end
                    end
                    
                case interactive.EditModes.AccessPoint
                    accesspoint = obj.AccessPointList(obj.EditRow);
                    for mobile = obj.MobileList
                        mobileaccesspoint = obj.AccessPointList(mobile.AccessPoint);
                        if mobile.AccessPoint == obj.EditRow
                            % Mobile connected to this access point
                            color = 'green';
                            width = thick;
                        elseif mobileaccesspoint.Channel == accesspoint.Channel
                            % Mobile connected to a different
                            % access point on same channel as this one
                            color = 'red';
                            width = thin;
                        else
                            continue % nothing to plot
                        end
                        drawlink(accesspoint, mobile, color, width)
                    end
                    
                otherwise
                    assert(false, illegalstatemessage)
            end
            
        end
        
        function refreshDisplay(obj, updatecontours)
            % Refresh graphical representation of all entities.
            
            if nargin < 2
                updatecontours = true;
            end
            
            obj.checkTables
            
            % Contours of downlink SINR
            if ~isequal(obj.ContourHandle, nullhandle) && updatecontours
                obj.DownlinkSINR = ...
                    obj.calculateDownlinkSINR( ...
                    obj.ContourGridX, obj.ContourGridY);
                set(obj.ContourHandle, ...
                    'XData', obj.ContourGridX, ...
                    'YData', obj.ContourGridY, ...
                    'ZData', obj.DownlinkSINR)
                obj.paint(@caxis, [
                    min(min(obj.DownlinkSINR(:)) + obj.SINRThreshold, 0), ...
                    obj.SINRThreshold + 0.001
                    ])
            end
            
            % System entities
            obj.refreshDisplayAccessPoints
            obj.refreshDisplayMobiles
            obj.refreshDisplayWalls
            obj.refreshDisplayLinks
            
            obj.checkTables
            
            % Ensure that the most recently edited entity
            % and its label are both clearly visible
            switch obj.EditModes
                case interactive.EditModes.AccessPoint
                    showontop(obj.AccessPointList)
                case interactive.EditModes.Mobile
                    showontop(obj.MobileList)
                case interactive.EditModes.None
                    return
                otherwise
                    assert(false, illegalstatemessage)
            end
            
            function showontop(entities)
                entity = entities(obj.EditRow);
                uistack(entity.MarkerHandle, 'top')
                uistack(entity.TextHandle, 'top')
            end
            
        end
        
    end
    
    % Methods for textual display
    methods (Access = private)
        
        function echoAccessPoint(obj, id)
            % Echo access point to command window
            obj.checkAccessPoints
            accesspoint = obj.AccessPointList(id);
            fprintf( ...
                'wyfy: AP%d (%g, %g), Pt = %g dBW, Channel %d\n', ...
                accesspoint.Index, ...
                accesspoint.PositionX, ...
                accesspoint.PositionY, ...
                accesspoint.Power, ...
                accesspoint.Channel);
        end
        
        function echoMobile(obj, id)
            % Echo mobile to command window
            obj.checkMobiles
            mobile = obj.MobileList(id);
            fprintf('wyfy: MOB%d (%g, %g), Pt = %g dBW\n', ...
                mobile.Index, ...
                mobile.PositionX, ...
                mobile.PositionY, ...
                mobile.TransmissionPower);
        end
        
    end
    
    % Methods for adding new entities.
    methods (Access = private)
        
        function addAccessPoint(obj, x, y, powerindbw, channel)
            markerhandle = obj.paint(@plot, x, y, 'bx', 'MarkerSize', 12);
            texthandle = obj.paint(@text, ...
                x, y, blankplaceholder, 'VerticalAlignment', 'top');
            id = newidentifier(obj.AccessPointTable(:, 1));
            columns = [
                1 : 5, ...
                obj.markerHandleColumn, obj.textHandleColumn
                ];
            values = [
                id, x, y, powerindbw, channel, ...
                double(markerhandle), double(texthandle)
                ];
            obj.AccessPointTable(end + 1, columns) = values;
            appendstruct(obj, 'AccessPointList', struct( ...
                'Index', id, ...
                'PositionX', x, ...
                'PositionY', y, ...
                'Power', powerindbw, ...
                'Channel', channel, ...
                'MarkerHandle', markerhandle, ...
                'TextHandle', texthandle))
            obj.echoAccessPoint(id)
            obj.checkAccessPoints
        end
        
        function addMobile(obj, x, y, pdbw)
            markerhandle = obj.paint(@plot, x, y, 'ks', 'MarkerSize', 12);
            texthandle = obj.paint(@text, x, y, blankplaceholder, ...
                'VerticalAlignment', 'top', ...
                'horizontalalignment', 'center');
            id = newidentifier(obj.MobileTable(:, 1));
            columns = [
                1, 2, 3, 8, ...
                obj.markerHandleColumn, obj.textHandleColumn
                ];
            values = [
                id, x, y, pdbw, ...
                double(markerhandle), double(texthandle)
                ];
            temporary = repmat(unknownvalue, 1, size(obj.MobileTable, 2));
            temporary(columns) = values;
            obj.MobileTable(end + 1, :) = temporary;
            appendstruct(obj, 'MobileList', struct( ...
                'Index', id, ... % 1
                'PositionX', x, ... % 2
                'PositionY', y, ... % 3
                'DownlinkReceivedPower', unknownvalue, ... %4
                'AccessPoint', unknownvalue, ... % 5
                'DownlinkINP', unknownvalue, ... % 6 [dBW]
                'DownlinkSINR', unknownvalue, ... % 7 [dB]
                'TransmissionPower', pdbw, ... % 8
                'UplinkReceivedPower', unknownvalue, ... % 9
                'UplinkINP', unknownvalue, ... % 10
                'UplinkSINR', unknownvalue, ... % 11
                'MarkerHandle', markerhandle, ... % 12 [dB]
                'TextHandle', texthandle)) % 13
            obj.echoMobile(id)
            obj.checkMobiles
        end
        
        function addWall(obj, x1, y1, x2, y2, gain)
            % Add a normal wall
            id = newidentifier(obj.WallTable(:, 1));
            handle = obj.paint(@plot, [x1, x2], [y1, y2], 'k');
            obj.WallTable(end + 1, :) = [
                id, 1, x1, y1, x2, y2, gain, double(handle)
                ];
            appendstruct(obj, 'WallList', struct( ...
                'Index', id, ...
                'Tail', [x1, y1], ...
                'Head', [x2, y2], ...
                'Gain', gain, ...
                'LineHandle', handle))
            obj.checkWalls
        end
        
    end
    
    % Methods for modifying entities.
    methods (Access = private)
        
        function modifyAccessPoint(obj, id, parm, varargin)
            % Modify an access point
            obj.checkAccessPoints
            assert(1 <= id && id <= numel(obj.AccessPointList))
            idr = findrow(obj.AccessPointTable, id);
            accesspoint = obj.AccessPointList(id);
            assert(accesspoint.Index == id)
            switch validatestring(parm, {'Channel', 'Position', 'Power'})
                case 'Power'
                    assert(numel(varargin) == 1)
                    obj.AccessPointTable(idr, 4) = varargin{1};
                    accesspoint.Power = varargin{1};
                    obj.AccessPoints.Power(id) = varargin{1};
                case 'Channel'
                    assert(numel(varargin) == 1)
                    obj.AccessPointTable(idr, 5) = varargin{1};
                    accesspoint.Channel = varargin{1};
                    obj.AccessPoints.Channel(id) = varargin{1};
                case 'Position'
                    assert(numel(varargin) == 2)
                    obj.AccessPointTable(idr, 2 : 3) = [varargin{:}];
                    accesspoint.PositionX = varargin{1};
                    accesspoint.PositionY = varargin{2};
                    set(accesspoint.MarkerHandle, ...
                        'XData', varargin{1}, 'YData', varargin{2})
                    obj.AccessPoints.Position(id, :) = [varargin{:}];
                    
            end
            obj.AccessPointList(id) = accesspoint;
            obj.echoAccessPoint(id)
            obj.checkAccessPoints
            assert( ...
                isequal(obj.AccessPoints, ...
                struct( ...
                'Channel', obj.AccessPointTable(:, 5), ...
                'Position', [obj.AccessPointTable(:, 2), obj.AccessPointTable(:, 3)], ...
                'Power', obj.AccessPointTable(:, 4))))
        end
        
        function modifyMobile(obj, id, parm, varargin)
            % Modify a mobile
            assert(1 <= id && id <= numel(obj.MobileList))
            idr = findrow(obj.MobileTable, id);
            mobile = obj.MobileList(id);
            switch validatestring(parm, {'Position'})
                case 'Position'
                    xy = [varargin{:}];
                    obj.MobileTable(idr, 2 : 3) = xy;
                    mobile.PositionX = xy(1);
                    mobile.PositionY = xy(2);
                    set(mobile.MarkerHandle, ...
                        'XData', xy(1), 'YData', xy(2))
                    obj.Mobiles.Position(id, :) = xy;
            end
            obj.MobileList(id) = mobile;
            obj.echoMobile(id)
            obj.checkMobiles
            assert(isequal( ...
                obj.Mobiles, ...
                struct( ...
                'Position', obj.MobileTable(:, 2 : 3), ...
                'Power', obj.MobileTable(:, 8))))
        end
        
    end
    
    methods
        
        function updateLinks(obj)
            
            [dlinks2, ulinks2] = analyze( ...
                obj.AccessPoints.Position, ...
                obj.Mobiles.Position, ...
                obj.Scene, ...
                'AccessPointChannel', obj.AccessPoints.Channel, ...
                'ReflectionArities', 0 : obj.ReflectionArity, ...
                'FreeGain', obj.FreeGain, ...
                'SourceGain', obj.SourceGain, ...
                'TransmissionGain', obj.TransmissionGain, ...
                'SinkGain', obj.SinkGain, ...
                'Reporting', true, ...
                'MinimumDiscernableSignal', obj.MinimumDiscernableSignal);
            
            [downlinkgains, uplinkgains] = tracescenenew( ...
                obj.AccessPoints.Position, ...
                obj.Mobiles.Position, ...
                obj.Scene, ...
                'ReflectionArities', 0 : obj.ReflectionArity, ...
                'FreeGain', obj.FreeGain, ...
                'SourceGain', obj.SourceGain, ...
                'TransmissionGain', obj.TransmissionGain, ...
                'SinkGain', obj.SinkGain, ...
                'Reporting', true);
            
            downlinkgain = sum(downlinkgains, 3);
            uplinkgain = sum(uplinkgains, 3);
            
            dlinks = dlinksinr( ...
                todb(downlinkgain), ...
                obj.AccessPoints.Channel, ...
                obj.MinimumDiscernableSignal);
            
            ulinks = ulinksinr( ...
                todb(uplinkgain), ...
                dlinks.AccessPoint, ...
                obj.AccessPoints.Channel, ...
                obj.MinimumDiscernableSignal);
            
            % ----->>
            compare(dlinks.AccessPoint, dlinks2.AccessPoint)
            compare(dlinks.Channel, dlinks2.Channel)
            compare(dlinks.INGainDBW, dlinks2.INGainDBW)
            compare(dlinks.SINRatio, dlinks2.SINRatio)
            compare(dlinks.SGainDBW, dlinks2.SGainDBW)
            compare(downlinkgains, dlinks2.PowerComponentsWatts)
            compare(downlinkgain, fromdb(dlinks2.PowerDBW))
            
            compare(ulinks.INGainDBW, ulinks2.INGainDBW)
            compare(ulinks.SINRatio, ulinks2.SINRatio)
            compare(ulinks.SGainDBW, ulinks2.SGainDBW)
            compare(uplinkgains, ulinks2.PowerComponentsWatts)
            compare(uplinkgain, fromdb(ulinks2.PowerDBW))
            % <<-----
            
            receivedpower = transpose(todb(downlinkgain));
            
            function transfer(column, name, values)
                obj.MobileTable(:, column) = values;
                obj.MobileList = ...
                    arrayfun(@update, obj.MobileList, values(:)');
                function mobile = update(mobile, value)
                    mobile.(name) = value;
                end
            end
            
            if ~obj.VerifyCalculations
                % Downlink attributes
                transfer(4, 'DownlinkReceivedPower', dlinks.SGainDBW)
                transfer(5, 'AccessPoint', dlinks.AccessPoint)
                transfer(6, 'DownlinkINP', dlinks.INGainDBW)
                transfer(7, 'DownlinkSINR', dlinks.SINRatio)
                % Uplink attributes
                transfer(9, 'UplinkReceivedPower', ulinks.SGainDBW)
                transfer(10, 'UplinkINP', ulinks.INGainDBW)
                transfer(11, 'UplinkSINR', ulinks.SINRatio)
            end
            
            if obj.VerifyCalculations
                
                fprintf('######## Recomputing Links ########\n')
                objin = copy(obj);
                [receivedpowerold, pathgainold] = obj.updateLinksOld;
                [receivedpowernew, pathgainnew] = updateLinksNew(objin);
                compare(receivedpowerold, receivedpowernew, 'links receivedpower.old vs receivedpower.new')
                compare(pathgainold, pathgainnew, 'links pathgain.old vs pathgain.new')
                compare(receivedpowerold, todb(downlinkgain'), 'rxpower.old vs downlinkgain')
                fprintf('  comparing fields')
                cellfun(@comparefield, ...
                    struct2cell(obj.MobileList), ...
                    struct2cell(objin.MobileList));
                fprintf(' OK\n')
                obj.checkTables
                
                compare(pathgainold, pathgainnew, ...
                    'mobile pathgain.old vs pathgain.new')
                compare(receivedpowerold, receivedpower, ...
                    'mobile receivedpower.old vs receivedpower.trace')
                
                compare(dlinks.AccessPoint, ...
                    vertcat(obj.MobileList.AccessPoint), ...
                    'AccessPoint')
                compare(dlinks.SGainDBW, ...
                    vertcat(obj.MobileList.DownlinkReceivedPower), ...
                    'DownlinkReceivedPower')
                compare(dlinks.INGainDBW, ...
                    vertcat(obj.MobileList.DownlinkINP), ...
                    'DownlinkINP')
                compare(dlinks.SINRatio, ...
                    vertcat(obj.MobileList.DownlinkSINR), ...
                    'DownlinkSINR')
                
                compare(ulinks.SGainDBW, ...
                    vertcat(obj.MobileList.UplinkReceivedPower), ...
                    'UplinkReceivedPower')
                compare(ulinks.INGainDBW(:), ...
                    vertcat(obj.MobileList.UplinkINP), ...
                    'UplinkINP')
                compare(ulinks.SINRatio, ...
                    vertcat(obj.MobileList.UplinkSINR), ...
                    'UplinkSINR')
                
                obj.checkTables
                
            end
            
            function comparefield(a, b)
                fprintf('.')
                if isnumeric(a)
                    compare(a, b)
                else
                    assert(isequal(a, b))
                end
            end
            
        end
        
        function [receivedpower, pathgain] = updateLinksOld(obj)
            % [PR,PG] = WYFY_CALCULATE(OBJ) computes
            % * received power PR and
            % * path gains PG.
            obj.checkTables
            [receivedpower, pathgain, obj.MobileTable, obj.MobileList] = ...
                updatelinks_legacy( ...
                obj.AccessPointTable, ...
                obj.MobileTable, ...
                obj.MobileList, ...
                obj.WallTable, ...
                obj.Wavelength, ...
                obj.MinimumDiscernableSignal);
        end
        
        function varargout = updateLinksNew(obj)
            [obj.MobileList, receivedpower, pathgain] = ...
                updatelinks_structs( ...
                obj.WallList, ...
                obj.AccessPointList, ...
                obj.MobileList, ...
                'MinimumDiscernableSignal', obj.MinimumDiscernableSignal, ...
                'Wavelength', obj.Wavelength);
            if nargout ~= 0
                varargout = {receivedpower, pathgain};
            end
        end
        
    end
    
    methods (Access = private)
        
        function dsinr = calculateDownlinkSINR(obj, xfield, yfield)
            
            links2 = analyze( ...
                obj.AccessPoints.Position, ...
                [xfield(:), yfield(:)], ...
                obj.Scene, ...
                'AccessPointChannel', obj.AccessPoints.Channel, ...
                'ReflectionArities', 0 : obj.ReflectionArity, ...
                'FreeGain', obj.FreeGain, ...
                'SourceGain', obj.SourceGain, ...
                'TransmissionGain', obj.TransmissionGain, ...
                'SinkGain', isofunction(0.0), ... % NB: zero on downlinks
                'Reporting', false);
            
            temporary = tracescene( ...
                obj.AccessPoints.Position, ...
                [xfield(:), yfield(:)], ...
                obj.Scene, ...
                'PathArities', 0 : obj.ReflectionArity, ...
                'FreeGain', obj.FreeGain, ...
                'SourceGain', obj.SourceGain, ...
                'TransmissionGain', obj.TransmissionGain, ...
                'SinkGain', isofunction(0.0), ... % NB: zero on downlinks
                'Reporting', false);
            
            downlinkgains = tracescenenew( ...
                obj.AccessPoints.Position, ...
                [xfield(:), yfield(:)], ...
                obj.Scene, ...
                'ReflectionArities', 0 : obj.ReflectionArity, ...
                'FreeGain', obj.FreeGain, ...
                'SourceGain', obj.SourceGain, ...
                'TransmissionGain', obj.TransmissionGain, ...
                'SinkGain', isofunction(0.0), ... % NB: zero on downlinks
                'Reporting', false);
            
            compare(temporary, downlinkgains, ...
                'tracescene vs tracescenenew')
            
            downlinkgain = sum(downlinkgains, 3);
            
            links = dlinksinr( ...
                todb(downlinkgain), ...
                obj.AccessPoints.Channel, ...
                obj.MinimumDiscernableSignal);
            
            % ----->>
            compare(links.AccessPoint, links2.AccessPoint)
            compare(links.Channel, links2.Channel)
            compare(links.INGainDBW, links2.INGainDBW)
            compare(links.SINRatio, links2.SINRatio)
            compare(links.SGainDBW, links2.SGainDBW)
            compare(downlinkgains, links2.PowerComponentsWatts)
            compare(downlinkgain, fromdb(links2.PowerDBW))
            % <<-----
            
            dsinr = reshape(links.SINRatio, size(xfield));
            
            figure(obj.extrafigure), colormap(jet), clf, hold on
            show = @(fig, numfigs, values, label) suppress({
                subplot(1, numfigs, fig);
                void(@() cla('reset'));
                surf(xfield, yfield, values, 'EdgeAlpha', 0.1, 'FaceColor', 'interp');
                title(label);
                xlabel('x');
                ylabel('y');
                void(@() axis('tight'));
                void(@() grid('off'));
                void(@() rotate3d('on'));
                void(@() view(2));
                void(@() colorbar('Location', 'northoutside'));
                void(@() set(gca, 'ZScale', 'log', 'Color', rgbgray));
                });
            
            rxpower = reshape(downlinkgain, ...
                size(xfield, 1), size(xfield, 2), []);
            
            if obj.VerifyCalculations
                
                fprintf('######## Recomputing Downlink SINR ########\n')
                
                [dsinr_old, intermediate] = calculateDownlinkSINROld(obj, xfield, yfield);
                dsinr_new = obj.calculateDownlinkSINRNew(xfield, yfield);
                compare(dsinr_old, dsinr_new, 'dsinr.old vs dsinr.new')
                compare(dsinr_old, dsinr, 'dsinr.old vs dsinr.trace')
                show(1, 2, todb(sum(intermediate.RxPower, 3)), 'todb(sum(rxpower, 3))')
                show(2, 2, max(abs(intermediate.RxPower - rxpower), [], 3), 'max(abs(rxpower error), [], 3)')
                compare(intermediate.RxPower, rxpower, 'rxpower.old vs rxpower.trace')
            else
                show(1, 1, todb(sum(rxpower, 3)), 'todb(sum(rxpower, 3))')
            end
            
        end
        
        function [dsinr, intermediate] = calculateDownlinkSINROld(obj, xmobile, ymobile)
            [dsinr, intermediate] = downlinksinr_legacy( ...
                xmobile, ymobile, ...
                obj.AccessPointTable, ...
                obj.WallTable, ...
                obj.Wavelength, ...
                obj.MinimumDiscernableSignal);
        end
        
        function sinr = calculateDownlinkSINRNew(obj, xmobile, ymobile)
            obj.checkTables
            sinr = downlinksinr_structs( ...
                obj.WallList, ...
                obj.AccessPointList, ...
                xmobile, ymobile, ...
                'MinimumDiscernableSignal', obj.MinimumDiscernableSignal, ...
                'Wavelength', obj.Wavelength);
        end
        
    end
    
    methods (Access = private)
        
        function windowButtonDown(obj, handle, ~)
            % Executes when the mouse button is pressed
            
            obj.checkTables
            
            setappdata(handle, ...
                'TestGuiCallbacks', struct( ...
                'WindowButtonMotionFcn', get(handle, 'WindowButtonMotionFcn'), ...
                'WindowButtonUpFcn', get(handle, 'WindowButtonUpFcn')))
            
            set(handle, ...
                'WindowButtonMotionFcn', {@obj.windowButtonMotion}, ...
                'WindowButtonUpFcn', {@obj.windowButtonUp})
            
            % Get location of mouse at button down
            [xcurrent, ycurrent] = obj.cursorPosition;
            
            % Identify closest object
            obj.EditRow = unknownvalue;
            obj.EditModes = interactive.EditModes.None;
            obj.EditMotion = false; % "selected, but not yet moved"
            minimumdistance = realmax; % unattainable upper bound
            function checkcandidates(entities, mode)
                for entity = entities
                    dist = distance(entity, xcurrent, ycurrent);
                    if dist < min(minimumdistance, obj.ClickRadius)
                        minimumdistance = dist;
                        obj.EditModes = mode;
                        obj.EditRow = entity.Index;
                    end
                end
            end
            checkcandidates(obj.AccessPointList, interactive.EditModes.AccessPoint)
            checkcandidates(obj.MobileList, interactive.EditModes.Mobile)
            
            % Update location and refresh display
            switch obj.EditModes
                case interactive.EditModes.None
                    assert(obj.EditRow == unknownvalue)
                    return % no need to update display, below
                case interactive.EditModes.AccessPoint
                    obj.modifyAccessPoint(obj.EditRow, 'Position', xcurrent, ycurrent)
                    obj.setTitle('Selected AP%d...', obj.EditRow)
                case interactive.EditModes.Mobile
                    obj.modifyMobile(obj.EditRow, 'Position', xcurrent, ycurrent)
                    obj.setTitle('Selected MOB%d...', obj.EditRow)
                otherwise
                    assert(false, illegalstatemessage)
            end
            obj.updateLinks
            obj.refreshDisplay(false)
            obj.checkTables
        end
        
        
        function windowButtonUp(obj, handle, ~)
            % Executes when the mouse button is released
            
            set(handle, getappdata(handle, 'TestGuiCallbacks'))
            
            if isequal(obj.EditModes, interactive.EditModes.None)
                return
            end
            
            % NB: Before updating edit mode
            refreshcontours = obj.EditMotion && ...
                obj.EditModes == interactive.EditModes.AccessPoint;
            
            % NB: before refreshing display!
            obj.EditModes = interactive.EditModes.None;
            
            % Recompute contour plot if and only if
            % an access point (cf. a mobile) has
            % actually moved (cf. merely been selected).
            obj.refreshDisplay(refreshcontours)
            
            obj.purgeLinks
            obj.EditMotion = false;
            obj.EditRow = 0;
            obj.setTitle
            
        end
        
        function windowButtonMotion(obj, ~, ~)
            % Executes while the mouse moves
            [x, y] = obj.cursorPosition;
            switch obj.EditModes
                case interactive.EditModes.None
                    return % no need to refresh display, below
                case interactive.EditModes.AccessPoint
                    obj.modifyAccessPoint(obj.EditRow, 'Position', x, y)
                    obj.setTitle('Moving AP%d...', obj.EditRow)
                case interactive.EditModes.Mobile
                    obj.modifyMobile(obj.EditRow, 'Position', x, y)
                    obj.setTitle('Moving MOB%d...', obj.EditRow)
                otherwise
                    assert(false, illegalstatemessage)
            end
            obj.EditMotion = true;
            obj.updateLinks
            obj.refreshDisplay(false)
        end
        
    end
    
    methods (Access = private)
        
        function purgeLinks(obj)
            assert(all(arrayfun(@isgraphics, obj.LinkHandles)))
            arrayfun(@delete, obj.LinkHandles);
            obj.LinkHandles = [];
        end
        
        function [x, y] = cursorPosition(obj)
            frontback = get(obj.AxesHandle, 'CurrentPoint');
            x = frontback(1, 1); % NB: index first row of two, not one
            y = frontback(1, 2);
        end
        
    end
    
    methods (Access = private)
        
        function checkAccessPoints(obj)
            if isempty(obj.AccessPointTable) && isempty(obj.AccessPointList)
                return
            end
            table = tabularvertcat(obj.AccessPointList);
            function check(column, value)
                assert(isequal(obj.AccessPointTable(:, column), value))
            end
            n = numel(obj.AccessPointList);
            assert(isequal(table.Index(:)', 1 : n))
            check(1, table.Index)
            check(2, table.PositionX)
            check(3, table.PositionY)
            check(4, table.Power)
            check(5, table.Channel)
            check(6 : 11, zeros(size(obj.AccessPointTable, 1), 6))
            check(12, double(table.MarkerHandle))
            check(13, double(table.TextHandle))
            assert(size(obj.AccessPointTable, 2) == 13)
        end
        
        function checkMobiles(obj)
            if isempty(obj.MobileTable) && isempty(obj.MobileList)
                return
            end
            table = tabularvertcat(obj.MobileList);
            function check(column, value)
                assert(isequal(obj.MobileTable(:, column), value))
            end
            n = numel(obj.MobileList);
            assert(isequal(table.Index(:)', 1 : n))
            check(1, table.Index)
            check(2, table.PositionX)
            check(3, table.PositionY)
            check(4, table.DownlinkReceivedPower)
            check(5, table.AccessPoint)
            check(6, table.DownlinkINP)
            check(7, table.DownlinkSINR)
            check(8, table.TransmissionPower)
            check(9, table.UplinkReceivedPower)
            check(10, table.UplinkINP)
            check(11, table.UplinkSINR)
            check(12, double(table.MarkerHandle))
            check(13, double(table.TextHandle))
            assert(size(obj.MobileTable, 2) == 13)
        end
        
        function checkWalls(obj)
            if isempty(obj.WallTable) && isempty(obj.WallList)
                return
            end
            table = tabularvertcat(obj.WallList);
            function check(column, value)
                assert(isequal(obj.WallTable(:, column), value))
            end
            check(1, table.Index)
            check(2, ones(size(obj.WallTable, 1), 1))
            check(3 : 4, table.Tail)
            check(5 : 6, table.Head)
            check(7, table.Gain)
            check(8, double(table.LineHandle))
            assert(size(obj.WallTable, 2) == 8)
        end
        
        function checkTables(obj)
            checkAccessPoints(obj)
            checkMobiles(obj)
            checkWalls(obj)
        end
        
        function fig = extrafigure(obj, offset)
            if nargin < 2 || isempty(offset)
                offset = 1;
            end
            fig = obj.FigureHandle.Number + offset;
        end
        
        function varargout = paint(obj, painter, varargin)
            [varargout{1 : nargout}] = painter(obj.AxesHandle, varargin{:});
        end
        
        function column = markerHandleColumn(obj)
            assert(obj.GHPtr == 12) % invariant
            column = obj.GHPtr;
        end
        
        function column = textHandleColumn(obj)
            column = obj.markerHandleColumn + 1;
        end
        
    end
    
end

% -------------------------------------------------------------------------
function map = twocolormap
map = [
    1, 0.8, 0.8; % salmon pink
    0.8, 1, 0.8; % lime green
    ];
end

% -------------------------------------------------------------------------
function id = newidentifier(oldids)
assert(isvector(oldids))
if isempty(oldids)
    id = 1;
else
    id = max(oldids) + 1;
end
end

% -------------------------------------------------------------------------
function position = shiftedposition(entity)
extents = get(entity.TextHandle, 'Extent');
textheight = extents(4); % extents is 1x4
position = [
    entity.PositionX, ...
    entity.PositionY - 0.5*textheight, ...
    0
    ];
end

% -------------------------------------------------------------------------
function d = distance(entity, x, y)
narginchk(2, 3)
if isstruct(x)
    assert(nargin == 2)
    [x, y] = deal(x.PositionX, x.PositionY);
end
d = hypot(entity.PositionX - x, entity.PositionY - y);
end

% -------------------------------------------------------------------------
function result = isinterferingpair(accesspoint1, accesspoint2)
% Distict access points on the same channel cause interference
result = ...
    accesspoint1.Index ~= accesspoint2.Index && ...
    accesspoint1.Channel == accesspoint2.Channel;
end

% -------------------------------------------------------------------------
function result = isunit(x)
result = 0 <= x && x <= 1;
end

function result = testintersection(s, t)
result = isunit(s) && isunit(t);
if ~result
    if permissive(s) && permissive(t)
        cprintf('*red', 'Near miss: s = %g, t = %g\n', s, t)
    end
end
    function result = permissive(x)
        tol = 1e-6;
        result = -tol <= x && x <= 1 + tol;
    end
end

% -------------------------------------------------------------------------
function row = findrow(table, id)
assert(1 <= size(table, 2))
row = find(table(:, 1) == id);
assert(isscalar(row), 'Invalid identifier: %d', id)
assert(row == id) % the present function is, in fact, unnecessary!
end

% -------------------------------------------------------------------------
function appendstruct(obj, name, value)
current = obj.(name);
% This test is required because MATLAB doesn't
% allow us to append to an empty struct (with no fields)
if isempty(current)
    current = value;
else
    current(end + 1) = value;
end
obj.(name) = current;
end

% -------------------------------------------------------------------------
function s = blankplaceholder
s = ' ';
end

function x = unknownvalue
% Readily recognized as un-initialized and not a valid index
x = -7777;
end

function h = nullhandle
h = unknownvalue;
end

% -------------------------------------------------------------------------
function x = makevector(x, n)
% Uniform means of reshaping a vector (columnwise) or replicating a scalar
if isscalar(x)
    x = repmat(x, n, 1);
end
assert(numel(x) == n)
x = x(:);
end

% -------------------------------------------------------------------------
function message = illegalstatemessage
message = 'Unexpected internal state: Please contact maintainers';
end

% =========================================================================
% Core Routines: New versions based on lists of structs
% =========================================================================
function [s, t] = wallintersection(xa, ya, xb, yb, xc, yc, xd, yd)
% Evaluate wall intersection parameters s and t for walls
% (xa, ya)->(xb, yb) and (xc, yc)->(xd, yd)

s = -(-xc * ya + xd * ya + xa * yc - xd * yc - xa * yd + xc * yd)/(xc * ya - xd * ya - xc * yb + xd * yb - xa * yc + xb * yc + xa * yd - xb * yd);
t = -(-xb * ya + xc * ya + xa * yb - xc * yb - xa * yc + xb * yc)/(-xc * ya + xd * ya + xc * yb - xd * yb + xa * yc - xb * yc - xa * yd + xb * yd);
end

% -------------------------------------------------------------------------
function sinr = downlinksinr_structs(walls, accesspoints, xmobile, ymobile, varargin)
%DOWNLINKSINR Downlink signal to interference-plus-noise ratio in dB

narginchk(4, nargin)
assert(isstruct(walls))
assert(isstruct(accesspoints))
assert(isnumeric(xmobile) && ismatrix(xmobile))
assert(isnumeric(ymobile) && ismatrix(ymobile))

parser = inputParser;
parser.addParameter('MinimumDiscernableSignal', minimumdiscernablesignal, @(x) isscalar(x) && x < 0) % [dBW]
parser.addParameter('Wavelength', speedoflight/centerfrequency, @(lambda) isscalar(lambda) && 0 < lambda)
parser.parse(varargin{:})
options = parser.Results;

sinr = zeros(size(xmobile)); % pre-allocate result

for i = 1 : size(xmobile, 1)
    for j = 1 : size(xmobile, 2)
        
        % Coordinates of current field point
        x = xmobile(i, j);
        y = ymobile(i, j);
        
        % Storage for power (in watts) that is received at
        % the current field point from each of the transmitters
        receivedpower = zeros(size(accesspoints));
        
        for accesspoint = accesspoints
            
            % Received power in the absence of wall attenuation
            powerdb = ...
                accesspoint.Power + ... % transmitted power
                friisdb(distance(accesspoint, x, y)); % free-space attenuation
            
            % Attenuation due to transmission through walls
            for wall = walls
                [s, t] = wallintersection( ...
                    wall.Tail(1), wall.Tail(2), ...
                    wall.Head(1), wall.Head(2), ...
                    accesspoint.PositionX, ...
                    accesspoint.PositionY, ...
                    x, y);
                if testintersection(s, t)
                    powerdb = powerdb + wall.Gain;
                end
            end
            
            % Store in watts for forthcoming interference sum
            receivedpower(accesspoint.Index) = fromdb(powerdb);
            
        end
        
        % Determine access point that maximizes
        % the power received at the current field point
        [maxreceivedpower, selectedidentifier] = max(receivedpower);
        assignedaccesspoint = accesspoints(selectedidentifier);
        
        % Total interference-plus-noise power for current field point
        interferencepower = fromdb(options.MinimumDiscernableSignal); % "noise"
        for accesspoint = accesspoints
            if isinterferingpair(accesspoint, assignedaccesspoint)
                interferencepower = interferencepower + ...
                    receivedpower(accesspoint.Index); % "interference contribution"
            end
        end
        
        % Signal to Interference-plus-Noise Ratio in dB
        sinr(i, j) = todb(maxreceivedpower, interferencepower);
        
    end
end

    function attenuation = friisdb(distance)
        % Friis free-space attenuation in dB at distance
        attenuation = 2*todb(options.Wavelength, 4*pi*distance);
    end

end

% -------------------------------------------------------------------------
function [mobiles, receivedpower, pathgain] = ...
    updatelinks_structs(walls, accesspoints, mobiles, varargin)

narginchk(3, nargin)
assert(isstruct(walls))
assert(isstruct(accesspoints))
assert(isstruct(mobiles))

parser = inputParser;
parser.addParameter('MinimumDiscernableSignal', minimumdiscernablesignal, @(x) isscalar(x) && x < 0) % [dBW]
parser.addParameter('Wavelength', speedoflight/centerfrequency, @(lambda) isscalar(lambda) && 0 < lambda)
parser.parse(varargin{:})
options = parser.Results;

% Pre-allocate storage
[receivedpower, pathgain] = deal( ...
    zeros(numel(accesspoints), numel(mobiles)));

% First task is to calculate all of the received powers
for accesspoint = accesspoints
    for mobile = mobiles
        
        d = distance(accesspoint, mobile);
        pathgainsum = 2*todb(options.Wavelength, 4*pi*d);
        
        % Now scan through all walls and compensate for wall
        % attenuation if wall intersects line of sight path
        for wall = walls
            [s, t] = wallintersection( ...
                wall.Tail(1), wall.Tail(2), ...
                wall.Head(1), wall.Head(2), ...
                accesspoint.PositionX, ...
                accesspoint.PositionY, ...
                mobile.PositionX, ...
                mobile.PositionY);
            if testintersection(s, t)
                pathgainsum = pathgainsum + wall.Gain;
            end
        end
        
        iap = accesspoint.Index;
        imob = mobile.Index;
        pathgain(iap, imob) = pathgainsum;
        receivedpower(iap, imob) = accesspoint.Power + pathgainsum;
    end
end

for mobile = mobiles
    
    % 1. Downlink calculations
    % 1.1. Assign access point that maximizes received power
    [maxpower, id] = max(receivedpower(:, mobile.Index));
    mobile.DownlinkReceivedPower = maxpower;
    mobile.AccessPoint = id;
    assignedaccesspoint = accesspoints(id);
    
    % 1.2. Calculate total interfering power
    % "Total Downlink Interference-plus-Noise Power"
    pdit = fromdb(options.MinimumDiscernableSignal);
    for accesspoint = accesspoints
        if isinterferingpair(accesspoint, assignedaccesspoint)
            pdit = pdit + fromdb(receivedpower( ...
                accesspoint.Index, mobile.Index));
        end
    end
    mobile.DownlinkINP = todb(pdit);
    mobile.DownlinkSINR = mobile.DownlinkReceivedPower - mobile.DownlinkINP;
    
    % 2. Uplink calculations
    % Must be done after downlink calculations, as access-point
    % assignments are determined by downlink received power.
    mobile.UplinkReceivedPower = ...
        mobile.TransmissionPower + ...
        pathgain(mobile.AccessPoint, mobile.Index);
    
    % Write updated state back to persistent storage
    mobiles(mobile.Index) = mobile;
    
end

% Now need to iterate over APs to determine total interfering
% power which comes from MOBs which are on the same channel but
% are allocated to other APs. MOBs which are allocated to this
% AP are not interferers, and their contentions will be handles
% at the MAC layer.
for accesspoint = accesspoints
    % "TIP" = Total uplink Interference+Noise Power
    tinpwatts = fromdb(options.MinimumDiscernableSignal);
    for mobile = mobiles
        assignedaccesspoint = accesspoints(mobile.AccessPoint);
        if isinterferingpair(accesspoint, assignedaccesspoint)
            tinpwatts = tinpwatts + ...
                fromdb( ...
                mobile.TransmissionPower + ...
                pathgain(accesspoint.Index, mobile.Index));
        end
    end
    
    tinpdb = todb(tinpwatts);
    
    % Store uplink INP of current access poin in all connected mobiles
    for mobile = mobiles
        if mobile.AccessPoint == accesspoint.Index
            mobile.UplinkINP = tinpdb;
            mobile.UplinkSINR = mobile.UplinkReceivedPower - tinpdb;
        end
        mobiles(mobile.Index) = mobile;
    end
    
end

end

% =========================================================================
% Core Routines: Legacy versions based on homogeneous numeric arrays/tables
% =========================================================================
function [dsinr, intermediate] = downlinksinr_legacy( ...
    xmobile, ymobile, aptable, walltable, wavelength, mds)

narginchk(6, 6)
assert(~isempty(aptable), 'Expected at least one access point')
assert(isscalar(wavelength))
assert(isscalar(mds))

[nr, nc] = size(xmobile);
nrap = size(aptable, 1);
nrwalls = size(walltable, 1);

dsinr = zeros(size(xmobile));
[friis, rxpower, transmission] = deal(zeros(nr, nc, nrap));

for ii = 1 : nr
    for jj = 1 : nc
        x = xmobile(ii, jj); % "test" receiver location
        y = ymobile(ii, jj);
        
        % Now build vector prx with powers (W) from all ap
        prx = zeros(nrap, 1);
        for kk = 1 : nrap
            
            d = norm(aptable(kk, 2 : 3) - [x, y]);
            
            % Received power assuming no wall attenuation
            prx(kk) = 10^(aptable(kk, 4)/10)*(wavelength/(4*pi*d))^2;
            
            % --- Added by Jon --->>
            distance(ii, jj, kk) = d; %#ok<AGROW,NASGU>
            friis(ii, jj, kk) = prx(kk);
            friisdb(ii, jj, kk) = aptable(kk, 4) + 20*(log10(wavelength) - log10(4*pi*d)); %#ok<AGROW>
            temporary = 1.0;
            temporarydb = 0.0;
            % <<--- Added by Jon ---
            
            % Scan through all walls
            if nrwalls > 0
                for ll = 1 : nrwalls
                    [s, t] = wallintersection( ...
                        walltable(ll, 3), ...
                        walltable(ll, 4), ...
                        walltable(ll, 5), ...
                        walltable(ll, 6), ...
                        aptable(kk, 2), ...
                        aptable(kk, 3), ...
                        x, y);
                    if isunit(s) && isunit(t)
                        prx(kk) = prx(kk)*10^(walltable(ll, 7)/10);
                        % --- Added by Jon --->>
                        temporary = temporary * 10^(walltable(ll, 7)/10);
                        temporarydb = temporarydb + walltable(ll, 7);
                        % <<--- Added by Jon ---
                    end
                end
            end
            
            % --- Added by Jon --->>
            transmission(ii, jj, kk) = temporary;
            transmissiondb(ii, jj, kk) = temporarydb; %#ok<AGROW>
            rxpower(ii, jj, kk) = prx(kk);
            rxpowerdb(ii, jj, kk) = todb(prx(kk)); %#ok<AGROW>
            % <<--- Added by Jon ---
            
        end
        
        % prx(kk) is the received power from AP kk at location (x,y)
        
        % Now work our max power and where it came from
        [prmax, apr] = max(prx);
        chan = aptable(apr, 5); % desired channel
        
        % Now evaluate total interference + noise power
        pint = 10^(mds/10);
        for kk = 1 : nrap
            if (kk ~= apr) && (aptable(kk, 5) == chan)
                pint = pint + prx(kk);
            end
        end
        
        dsinr(ii, jj) = 10*log10(prmax / pint);
    end
end

% --- Added by Jon --->>
compare(rxpower, friis .* transmission)
compare(rxpowerdb, friisdb + transmissiondb)
compare(todb(rxpower), rxpowerdb)
intermediate = struct( ...
    'RxPower', rxpower, ...
    'Friis', friis, ...
    'Transmission', transmission);
% <<--- Added by Jon ---

end

% -------------------------------------------------------------------------
function [receivedpower, pathgain, mobiletable, mobilelist] = ...
    updatelinks_legacy(accesspointtable, mobiletable, mobilelist, walltable, wavelength, mds)

% First task is to calculate all of the received powers
nrap = size(accesspointtable, 1);
nrmob = size(mobiletable, 1);
nrwalls = size(walltable, 1);

receivedpower = zeros(nrap, nrmob); % Store received powers
pathgain = zeros(nrap, nrmob); % Also store path gains

for ii = 1 : nrap
    for jj = 1 : nrmob
        
        d = norm(accesspointtable(ii, 2 : 3) - mobiletable(jj, 2 : 3));
        pathgain(ii, jj) = 20*log10(wavelength/(4*pi*d));
        
        % Now scan through all walls and compensate for wall
        % attenuation if wall intersects line of sight path
        if nrwalls > 0
            for kk = 1 : nrwalls
                [s, t] = wallintersection( ...
                    walltable(kk, 3), ...
                    walltable(kk, 4), ...
                    walltable(kk, 5), ...
                    walltable(kk, 6), ...
                    accesspointtable(ii, 2), ...
                    accesspointtable(ii, 3), ...
                    mobiletable(jj, 2), ...
                    mobiletable(jj, 3));
                if isunit(s) && isunit(t)
                    pathgain(ii, jj) = pathgain(ii, jj) + walltable(kk, 7);
                end
            end
        end
        
        % "received power = pt + path gain"
        receivedpower(ii, jj) = accesspointtable(ii, 4) + pathgain(ii, jj);
    end
end

% DOWNLINK
% For each MOB, determine maximum received power
% and store this + index of AP
for jj = 1 : nrmob
    [maxpow, apr] = max(receivedpower(:, jj));  % max of column
    mobiletable(jj, 4) = maxpow;  % Store index and power in mob
    mobiletable(jj, 5) = apr;
    mobilelist(jj).DownlinkReceivedPower = maxpow;
    mobilelist(jj).AccessPoint = apr;
    
    % Now calculate total interfering power
    pdit = 10^(mds/10);  % initialise net total downlink inteference power to MDS
    for ii = 1 : nrap
        if (accesspointtable(ii, 5) == accesspointtable(apr, 5)) && (ii ~= apr)  % If the ii th ap is on the same channel as the desired and is not the apr'th
            pdit = pdit + 10^(receivedpower(ii, jj)/10);  % Add interfering power to sum
        end
    end
    mobiletable(jj, 6) = 10*log10(pdit);   % Total INP in dBW
    mobiletable(jj, 7) = mobiletable(jj, 4) - mobiletable(jj, 6);  % SINR in dB
    mobilelist(jj).DownlinkINP = 10*log10(pdit);
    mobilelist(jj).DownlinkSINR = mobiletable(jj, 4) - mobiletable(jj, 6);
end

% UPLINK
% This must be done after downlink, as desired AP is determined
% by max downlink received power.  Most of this data needs to
% be stored in MOB as it it mob specific.
for jj = 1 : nrmob
    % Uplink received power is easy: mob transmit + path gain
    mobiletable(jj, 9) = mobiletable(jj, 8) + pathgain(mobiletable(jj, 5), jj);
    mobilelist(jj).UplinkReceivedPower = ...
        mobilelist(jj).TransmissionPower + ...
        pathgain(mobilelist(jj).AccessPoint, jj);
end

% Now need to iterate over APs to determine total interfering
% power which comes from MOBs which are on the same channel but
% are allocated to other APs. MOBs which are allocated to this
% AP are not interferers, and their contentions will be handles
% at the MAC layer.
for ii = 1 : nrap
    apchan = accesspointtable(ii, 5);
    tip = 10^(mds/10);  % Total uplink interference power
    for jj = 1 : nrmob
        mobchan = accesspointtable(mobiletable(jj, 5), 5);
        if (mobiletable(jj, 5) ~= ii) && (apchan == mobchan)  % MOB is not connected to this AP but on the same channel so must be an interferer
            tip = tip + 10^((mobiletable(jj, 8) + pathgain(ii, jj))/10);
        end
    end
    tip = 10*log10(tip);
    
    % tip is now the total uplink interference power for AP ii.  Now store
    % this in all connected MOBs
    for jj = 1 : nrmob
        if mobiletable(jj, 5) == ii
            mobiletable(jj, 10) = tip;
            mobiletable(jj, 11) = mobiletable(jj, 9) - mobiletable(jj, 10); % USINR
            mobilelist(jj).UplinkINP = tip;
            mobilelist(jj).UplinkSINR = ...
                mobilelist(jj).UplinkReceivedPower ...
                - mobilelist(jj).UplinkINP; % USINR
        end
    end
    
end

end
