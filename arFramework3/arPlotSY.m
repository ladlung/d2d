% Plot Y models sensitivities
%
% arPlotSY

function arPlotSY

global ar

if(isempty(ar))
    error('please initialize by arInit')
end

fcount = 1;
for jm = 1:length(ar.model)
    nd = length(ar.model(jm).data);
    for jd = 1:nd
        myRaiseFigure(jm, ['SY: ' ar.model(jm).data(jd).name ' - ' ar.model(jm).data(jd).checkstr], fcount);
        
        % rows and cols
        [ncols, nrows, ny] = myColsAndRows(jm, jd);
        
        np = length(ar.model(jm).data(jd).p);
        for jy = 1:ny
            g = subplot(nrows,ncols,jy);
            arSubplotStyle(g);
            
            legendhandle = zeros(1,np);
            
            for jp = 1:np
                linestyle = myLineStyle(np,jp);
                ltmp = plot(g, ar.model(jm).data(jd).tFine, ar.model(jm).data(jd).syFineSimu(:,jy,jp), linestyle{:});
                legendhandle(jp) = ltmp;
                hold(g, 'on');
                if(isfield(ar.model(jm).data(jd), 'syExpSimuFD'))
                    plot(g, ar.model(jm).data(jd).tExp, ar.model(jm).data(jd).syExpSimuFD(:,jy,jp), linestyle{:}, 'Marker', '*');
                end
            end
            hold(g, 'off');
            
            arSpacedAxisLimits(g);
            title(g, arNameTrafo(ar.model(jm).data(jd).y{jy}));
            if(jy == 1)
                legend(g, legendhandle, arNameTrafo(ar.model(jm).data(jd).p));
            end
            
            if(jy == (nrows-1)*ncols + 1)
                xlabel(g, sprintf('%s [%s]', ar.model(jm).data(jd).tUnits{3}, ar.model(jm).data(jd).tUnits{2}));
                ylabel(g, 'sensitivity');
            end
        end        
        fcount = fcount + 1; 
    end
end



%% sub-functions



function C = myLineStyle(n, j)
farben = lines(n);
zeichen = {':', '-', '--', '-.'};
zeichenindex = mod(floor((j-1)/7)+1, 4)+1;
C = cell(1,3);
C{1} = [zeichen{zeichenindex}];
C{2} = 'Color';
C{3} = farben(j,:);




function h = myRaiseFigure(m, figname, jf)
global ar
openfigs = get(0,'Children');

figcolor = [1 1 1];
figdist = 0.02;

ar.model(m).plots(jf).time = now;

if(isfield(ar.model(m).plots(jf), 'fighandel_sy') && ~isempty(ar.model(m).plots(jf).fighandel_sy) && ...
        ar.model(m).plots(jf).fighandel_sy ~= 0 && sum(ar.model(m).plots(jf).fighandel_sy==openfigs)>0 && ...
        strcmp(get(ar.model(m).plots(jf).fighandel_sy, 'Name'), figname))
    h = ar.model(m).plots(jf).fighandel_sy;
    figure(h);
else
    h = figure('Name', figname, 'NumberTitle','off', ...
        'Units', 'normalized', 'Position', ...
        [0.05+((jf-1)*figdist) 0.45-((jf-1)*figdist) 0.3 0.45]);
    set(h,'Color', figcolor);
    ar.model(m).plots(jf).fighandel_sy = h;
end



function [ncols, nrows, ny] = myColsAndRows(jm, jd)
global ar
ny = size(ar.model(jm).data(jd).y, 2);
[nrows, ncols] = arNtoColsAndRows(ny);





