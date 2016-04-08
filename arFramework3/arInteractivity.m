% Function used to control some additional interactivity enhancement
% callbacks. Since these may slow down the plots on some systems, they are
% off by default. Activate them by calling "interactivity on".
%
% Note that interactivity has to be on when the plot is created for the
% callbacks to be registered. This is to keep the profile low when
% interactivity is not desired.
%
% Currently supported interactive modes:
%   plePlot =>  Click on the individual parameter curves to change legend
%               entries.


function interactive = arInteractivity( varargin )

    global arInteractivityStruct;
    
    if ( isempty( arInteractivityStruct ) )
        initInteractivity;
    end
    
    % No arguments means we want to know whether the interactivity system
    % is operational
    if (nargin == 0)
        interactive = arInteractivityStruct.active;
        return;
    end
    
    if ( ~ischar( varargin{1} ) )
        error( 'First argument should be a string' );
    end    

    if strcmpi( varargin{1}, 'on' )
        arInteractivityStruct.active = 1;
        disp( 'Interactivity mode activated' );
    end
    if strcmpi( varargin{1}, 'off' )
        arInteractivityStruct.active = 0;
        disp( 'Interactivity mode disabled' );
    end
    
    % PLE interactivity functions
    if strcmp( varargin{1}, 'ple' );
        arInteractivityStruct.ple.legend = varargin{2};
        set(gcf,'WindowButtonDownFcn', @(hObject, eventData)pleFcn2(hObject, eventData) );
    end
    
    % arCompareModel interactivity functions
    if strcmp( varargin{1}, 'arCompareModel' )
        arInteractivityStruct.arCompareModel.dataFiles      = varargin{2};
        arInteractivityStruct.arCompareModel.observables    = varargin{3};
        arInteractivityStruct.arCompareModel.ar1            = varargin{4};
        arInteractivityStruct.arCompareModel.m1             = varargin{5};
        arInteractivityStruct.arCompareModel.ar2            = varargin{6};
        arInteractivityStruct.arCompareModel.m2             = varargin{7};
        arInteractivityStruct.arCompareModel.plotIDs1       = varargin{8};
        arInteractivityStruct.arCompareModel.plotIDs2       = varargin{9};
        set(gcf,'WindowButtonDownFcn', @(hObject, eventData)arCompareModelFcn2(hObject, eventData) );
    end
end

function initInteractivity()
    global arInteractivityStruct;
    
    arInteractivityStruct.active = 0;
end

function pleFcn2(hObject, eventData) %#ok
    global arInteractivityStruct;

    if ( ~isempty( arInteractivityStruct ) && arInteractivityStruct.active && isfield( arInteractivityStruct, 'ple' ) )
        userData = arInteractivityStruct.ple.legend;
        try
            name = userData.legends( gco == userData.handles );
            if ( ~isempty( name ) )
                userData.currentLegend.handles(userData.currentLegend.ID) = gco;
                userData.currentLegend.legends(userData.currentLegend.ID) = name;
                userData.currentLegend.ID = mod( userData.currentLegend.ID, 5 ) + 1;
                legend( gca, userData.currentLegend.handles, userData.currentLegend.legends );
            end
        catch
            error( 'Unknown interactivity error in callback' );
        end
        arInteractivityStruct.ple.legend = userData;
    end
end

function arCompareModelFcn2(hObject, eventData) %#ok
    global arInteractivityStruct;
    if ( ~isempty( arInteractivityStruct ) && arInteractivityStruct.active && isfield( arInteractivityStruct, 'arCompareModel' ) )
        userData    = arInteractivityStruct.arCompareModel;
        cp          = get(gca, 'CurrentPoint');

        global ar;              %#ok
        global arOutputLevel;   %#ok
        arOld = ar;
            
        % Find corresponding plots
        obs = floor( cp(1,1) ) + 1;
        dat = floor( cp(1,2) );
        if ( arOutputLevel > 2 )
            fprintf( 'Clicked data ID %d, observable %d\n', dat, obs );
        end
        
        % Early out when not clicking inside the image
        if ( ( dat < 1 ) || ( dat > length( userData.plotIDs1 ) ) )
            return;
        end
        
        ar = userData.ar1; %#ok
        plotCurve( userData.m1, userData.plotIDs1{dat} );
        set(gcf, 'Name', sprintf( '[%s]: %s', userData.ar1.model(userData.m1).name, get(gcf, 'Name') ) );
        
        ar = userData.ar2; %#ok
        plotCurve( userData.m2, userData.plotIDs2{dat} );
        set(gcf, 'Name', sprintf( '[%s]: %s', userData.ar2.model(userData.m2).name, get(gcf, 'Name') ) );
        
        ar = arOld;
    end
end

function plotCurve( m, plot )
    global ar;
    
    % Turn only a single plot on but backup the user's settings
    for jm = 1 : length( ar.model )
        old{jm} = ar.model(jm).qPlotYs; %#ok
        ar.model(jm).qPlotYs = zeros( size( ar.model(jm).qPlotYs) );
    end
    ar.model(m).qPlotYs(plot) = 1;
    
    % Plot
    arPlotY(false, 2, true);
    
    % Return user settings
    for jm = 1 : length( ar.model )
        ar.model(jm).qPlotYs = old{jm};
    end
end