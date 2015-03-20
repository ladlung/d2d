% Plot models and datasets
%
% arPlot(saveToFile, fastPlot, silent, evalfun, doLegends, dynamics)
%
% saveToFile    [false]
% fastPlot      [false]
% silent        [false]
% evalfun       [true]
% doLegends     [true]
% dynamics:     [true]

function arPlot2(saveToFile, fastPlot, silent, evalfun, doLegends, dynamics)

global ar

if(isempty(ar))
    error('please initialize by arInit')
end

if(~exist('saveToFile','var'))
    saveToFile = false;
end
if(~exist('fastPlot','var'))
    fastPlot = false;
end
if(~exist('silent','var'))
    silent = false;
end
if(~exist('evalfun','var'))
    evalfun = true;
end
if(~exist('doLegends','var'))
    doLegends = true;
end
if(~exist('dynamics','var'))
    dynamics = true;
end

matVer = ver('MATLAB');

if(evalfun)
    try
        arSimu(false, true, dynamics);
    catch err_id
        if(~silent)
            disp(err_id.message);
        end
    end
    try
        if(silent)
            arChi2(false, [], dynamics);
        else
            arChi2;
        end
    catch err_id
        if(~silent)
            disp(err_id.message);
        end
    end
end

if(~isfield(ar.model, 'qPlotYs'))
    for jm=1:length(ar.model)
        if(length(ar.model(jm).plot) > 5)
            fprintf('Automatic plotting disabled for model %i. Please use arTuner for plotting.\n', jm);
            ar.model(jm).qPlotYs = false(1,length(ar.model(jm).plot));
            ar.model(jm).qPlotXs = false(1,length(ar.model(jm).plot));
            ar.model(jm).qPlotVs = false(1,length(ar.model(jm).plot));
        else
            ar.model(jm).qPlotYs = true(1,length(ar.model(jm).plot));
            ar.model(jm).qPlotXs = false(1,length(ar.model(jm).plot));
            ar.model(jm).qPlotVs = false(1,length(ar.model(jm).plot));
        end
    end
end

if(isfield(ar.config,'nfine_dr_plot'))
    nfine_dr_plot = ar.config.nfine_dr_plot;
    nfine_dr_method = ar.config.nfine_dr_method;
else
    nfine_dr_plot = 1;
    nfine_dr_method = 'spline';
end

figcount = 1;
for jm = 1:length(ar.model)
    ar.model(jm).chi2 = 0;
    ar.model(jm).ndata = 0;
    
    for jplot = 1:length(ar.model(jm).plot)
        qDR = ar.model(jm).plot(jplot).doseresponse;
        
        % log 10 dose response axis
        if(isfield(ar.model(jm).plot(jplot), 'doseresponselog10xaxis'))
            logplotting_xaxis = ar.model(jm).plot(jplot).doseresponselog10xaxis;
        else
            logplotting_xaxis = true;
        end
        
        % chi^2, ndata and dr_times
        chi2 = zeros(1,ar.model(jm).plot(jplot).ny);
        ndata = zeros(1,ar.model(jm).plot(jplot).ny);
        dr_times = [];
        for jd = ar.model(jm).plot(jplot).dLink
            if(isfield(ar.model(jm),'data'))
                if(qDR)
                    dr_times = union(dr_times, ar.model(jm).data(jd).tExp); %R2013a compatible
                end
                
                ny = length(ar.model(jm).data(jd).y);
                for jy = 1:ny
                    % chi^2 & ndata
                    if(ar.model(jm).data(jd).qFit(jy)==1)
                        chi2(jy) = chi2(jy) + ar.model(jm).data(jd).chi2(jy);
                        ndata(jy) = ndata(jy) + ar.model(jm).data(jd).ndata(jy);
                        if(ar.config.fiterrors==1)
                            chi2(jy) = chi2(jy) + ar.model(jm).data(jd).chi2err(jy);
                        end
                    end
                end
            end
        end
        
        ar.model(jm).plot(jplot).chi2 = sum(chi2);
        ar.model(jm).plot(jplot).ndata = sum(ndata);
        
        ar.model(jm).chi2 = ar.model(jm).chi2 + sum(chi2);
        ar.model(jm).ndata = ar.model(jm).ndata + sum(ndata);
        
        if(isempty(dr_times)) % for non dose response
            dr_times = 0;
        end
        
        % conditions
        if(str2double(matVer.Version)>=8.1)
            [conditions, iconditions, jconditions] = ...
                unique(ar.model(jm).plot(jplot).condition,'legacy'); %#ok<ASGLU>
        else
            [conditions, iconditions, jconditions] = ...
                unique(ar.model(jm).plot(jplot).condition); %#ok<ASGLU>
        end
        
        fighandel_name = {'fighandel_y', 'fighandel_x', 'fighandel_v'};
        fig_name = {'Y: ', 'X: ', 'V: '};
        linehandle_name = {'y','x','v'};
        savepath_name = {'Y','X','V'};
        qplotname = {'qPlotYs', 'qPlotXs', 'qPlotVs'};
        
        didPlot = false;
        
        if(isfield(ar.model(jm),'data'))
            jtypes = 1:3;
        else
            jtypes = 2:3;
        end
        
        for jtype = jtypes
            
            % legends handles and labels
            Clegend = zeros(1,length(dr_times)*length(conditions));
            Clegendlabel = cell(1,length(dr_times)*length(conditions));
            
            if(ar.model(jm).(qplotname{jtype})(jplot)==1 && (jtype~=1 || ar.model(jm).plot(jplot).ny>0))
                didPlot = true;
                
                % setup figure
                if(ar.config.ploterrors == -1)
                    [h, fastPlotTmp] = arRaiseFigure(ar.model(jm).plot(jplot), ...
                        [fighandel_name{jtype} 'CI'], ['CI-' fig_name{jtype} ar.model(jm).plot(jplot).name], ...
                        figcount, fastPlot, jtype);
                    ar.model(jm).plot(jplot).([fighandel_name{jtype} 'CI']) = h;
                else
                    [h, fastPlotTmp] = arRaiseFigure(ar.model(jm).plot(jplot), ...
                        fighandel_name{jtype}, [fig_name{jtype} ar.model(jm).plot(jplot).name], ...
                        figcount, fastPlot, jtype);
                    ar.model(jm).plot(jplot).(fighandel_name{jtype}) = h;
                end
                
                % plotting
                ccount = 1;
                for jt = 1:length(dr_times)
                    if(isempty(conditions))
                        jcs = 1;
                    else
                        jcs = 1:length(conditions);
                    end
                    for jc = jcs
                        if(isempty(conditions))
                            ds = ar.model(jm).plot(jplot).dLink;
                        else
                            ds = ar.model(jm).plot(jplot).dLink(find(jconditions==jc)); %#ok<FNDSB>
                        end
                        
                        jd = ds(1);
                        
                        % get data
                        if(qDR)
                            [t, y, ystd, tExp, yExp, yExpStd, lb, ub, zero_break, qFit, yExpHl] = ...
                                arGetDataDoseResponse(jm, ds, dr_times(jt), ...
                                ar.model(jm).plot(jplot).dLink, logplotting_xaxis, jtype);
                            y_ssa = [];
                            y_ssa_lb = [];
                            y_ssa_ub = [];
                            dydt = [];
                        else
                            [t, y, ystd, tExp, yExp, yExpStd, lb, ub, yExpHl, dydt, ...
                                y_ssa, y_ssa_lb, y_ssa_ub, qFit] = arGetData(jm, jd, jtype);
                            t = t(2:end);
                            y = y(2:end,:);
                            ystd = ystd(2:end,:);
                            zero_break = [];
                        end
                        [tUnits, response_parameter, yLabel, yNames, yUnits, iy, ...
                            hys, hystds, hysss] = ...
                            arGetInfo(jm, jd, jtype, linehandle_name{jtype});
                        
                        % log10 plotting
                        if(jtype==1)
                            qUnlog = ar.model(jm).data(jd).logfitting & ...
                                ~ar.model(jm).data(jd).logplotting;
                            qLog = ar.model(jm).data(jd).logplotting;
                        else
                            qUnlog = false(size(yLabel));
                            qLog = false(size(yLabel));
                        end
                        
                        % call arPlotTrajectories
                        [hys, hystds, hysss, nrows, ncols] = arPlotTrajectories(ccount, ...
                            length(dr_times)*length(jcs), ...
                            t, y, ystd, lb, ub, nfine_dr_plot, ...
                            nfine_dr_method, tExp, yExp, yExpHl, yExpStd, ...
                            y_ssa, y_ssa_lb, y_ssa_ub, ...
                            ar.config.ploterrors, qUnlog, qLog, qFit, ...
                            zero_break, fastPlotTmp, hys, hystds, hysss, dydt, ...
                            jt==length(dr_times) && jc==jcs(end), qDR, ndata, chi2, ...
                            tUnits, response_parameter, yLabel, yNames, yUnits, ...
                            ar.config.fiterrors, logplotting_xaxis, iy);
                        
                        % save handels
                        if(jd~=0)
                            ar.model(jm).data(jd).plot.(linehandle_name{jtype}) = hys;
                            if(jtype == 1)
                                ar.model(jm).data(jd).plot.ystd = hystds;
                            end
                            if(jtype == 2)
                                if(jd~=0) % mean no data loaded
                                    ar.model(jm).data(jd).plot.xss = hysss;
                                else
                                    ar.model(jm).condition(jc).plot.xss = hysss;
                                end
                            end
                        else
                            ar.model(jm).plot.(linehandle_name{jtype}) = hys;
                            if(jtype == 1)
                                ar.model(jm).plot.ystd = hystds;
                            end
                            if(jtype == 2)
                                ar.model(jm).plot.xss = hysss;
                            end
                        end

                        
                        % legends
                        if(jtype == 1)
                            inonzero = find(hystds~=0);
                            Clegend(ccount) = hystds(inonzero(1));
                        else
                            inonzero = find(hys~=0);
                            Clegend(ccount) = hys(inonzero(1));
                        end
                        if(qDR)
                            if(~isempty(conditions) && ~isempty(conditions{jc}))
                                Clegendlabel{ccount} = sprintf('t=%g%s : %s', dr_times(jt), ...
                                    tUnits{2}, arNameTrafo(conditions{jc}));
                            else
                                Clegendlabel{ccount} = sprintf('t=%g%s', dr_times(jt), ...
                                    tUnits{2});
                            end
                        else
                            if(~isempty(conditions) && ~isempty(conditions{jc}))
                                Clegendlabel{ccount} = arNameTrafo(conditions{jc});
                            end
                        end
                        
                        ccount = ccount + 1;
                    end
                end
                
                % legend
                if(doLegends && ~fastPlot && (~isempty(conditions) || qDR))
                    g = subplot(nrows, ncols, nrows*ncols);
                    lpos = get(g,'Position');
                    delete(g);
                    g = subplot(nrows, ncols, 1);
                    hl = legend(g, Clegend, Clegendlabel, 'Location', 'SouthWest');
                    lpos2 = get(hl,'Position');
                    lpos2(1:2) = lpos(1:2);
                    set(hl, 'Position', lpos2);
                    box(hl,'off');
                end
                
                % optional suptitle
                if(~fastPlotTmp && exist('suptitle','file')==2 && ...
                        isfield(ar.config, 'useSuptitle') && ar.config.useSuptitle)
                    suptitle(arNameTrafo([ar.model(jm).name,': ',ar.model(jm).plot(jplot).name]))
                end
                
                % save figure
                if(saveToFile)
                    if(ar.config.ploterrors == -1)
                        ar.model(jm).plot(jplot).(['savePath_Fig' savepath_name{jtype} 'CI']) = ...
                            arSaveFigure(h, ...
                            ar.model(jm).plot(jplot).name, ['/FiguresCI/' savepath_name{jtype}]);
                    else
                        ar.model(jm).plot(jplot).(['savePath_Fig' savepath_name{jtype}]) = ...
                            arSaveFigure(h, ...
                            ar.model(jm).plot(jplot).name, ['/Figures/' savepath_name{jtype}]);
                    end
                end
            else
                try %#ok<TRYNC>
                    close(ar.model(jm).plot(jplot).(fighandel_name{jtype}))
                end
                ar.model(jm).plot(jplot).(fighandel_name{jtype}) = [];
            end
        end
        if(didPlot)
            figcount = figcount + 1;
        end
    end
end
