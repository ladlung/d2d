% plot trajectories
%
% this function is experimental, please contact Andreas Raue for help

function arPlotMerged(saveToFile, condition_link_bool, only_inhib)

global ar

if(isempty(ar))
	error('please initialize by arInit')
end

if(~exist('saveToFile','var'))
	saveToFile = false;
end

if(~exist('only_inhib','var'))
	only_inhib = false;
end

if(~exist('condition_link_bool','var'))
	condition_link_bool = false;
end

ar.model.qPlotYs(:) = 1; %Adjust, if only a subset of the data setup should be plotted
%ar.model.qPlotYs([110]) = 0;

standcond = 'HGF_input=100'; % Insert standard condition

%% log
clc

ylabels = {};
for jd = 1:length(ar.model.data)
    ylabels = union(ylabels,ar.model.data(jd).y);
end
disp(ylabels)
disp(ar.model.x)

%% link
ylink = cell(size(ylabels));

if(only_inhib == false)
    ylink{6} = 12; % pAkt_au
    ylink{8} = 22; % pERK_au
    ylink{10} = 21; % pMEK_au
    %ylink{11} = 1; % pMet_au
    %ylink{12} = 18; % pRaf_au
    %ylink{5} = 25; % double_RSK_au
    %ylink{13} = 24; % single_RSK_au
else
    ylink{2} = 12; % pAkt_au_only_inhib
    ylink{3} = 22; % pERK_au_only_inhib
    ylink{4} = 21; % pMEK_au_only_inhib
end;

% ylink{4} = 18;
% ylink{5} = 17;
% ylink{6} = 11;

condition_link = [22 23]; %Adjust for required condition combination

%% plot

figcount = 1;
for jm=1:length(ar.model);
    % colors = lines(length(ar.model.condition));
    colors = zeros(length(ar.model.condition),3);
    
    % time course plots
    for j=find(~cellfun(@isempty, ylink))
        ar.model(jm).plot_merged(j).name = sprintf('%s_%s_TC', ar.model(jm).name, ylabels{j});
        
        fprintf('%s:\n\n', ar.model(jm).plot_merged(j).name);
        
        % determine y range
        yscale = 0;
        for jc = 1:length(ar.model.condition)
            yscale = max([yscale range(ar.model.condition(jc).xExpSimu(:,ylink{j}))]);
        end
        yscale = 0.1*yscale;
        
        %collect
        ctime = cell(1,length(ar.model.condition));
        cdata = cell(1,length(ar.model.condition));
        clabel = cell(1,length(ar.model.condition));
        nds = nan(1,length(ar.model.condition));
        chi2s = nan(1,length(ar.model.condition));
        ndatas = nan(1,length(ar.model.condition));
        for jc = 1:length(ar.model.condition)
            time = [];
            data = [];
            ndstmp = 0;
            chi2tmp = 0;
            ndatatmp = 0;
            
            % data
            for jp = 1:length(ar.model.plot)
                if(ar.model.qPlotYs(jp)==1 && ar.model.plot(jp).doseresponse==0)
                    for jd = ar.model.plot(jp).dLink
                        qy = ismember(ar.model.data(jd).y, ylabels{j});
                        if(jc==ar.model.data(jd).cLink && sum(qy)==1 && ar.model.data(jd).doseresponse==0)
                            tExp = ar.model.condition(jc).tExp(ar.model.data(jd).tLinkExp);
                            yExp = ar.model.condition(jc).xExpSimu(ar.model.data(jd).tLinkExp,ylink{j}) + ...
                                yscale * ar.model.data(jd).res(:,qy);
                            time = [time; tExp(:)]; %#ok<AGROW>
                            data = [data; yExp(:)]; %#ok<AGROW>
                            ndstmp = ndstmp + 1;
                            chi2tmp = chi2tmp + ar.model.data(jd).chi2(qy);
                            if(ar.config.fiterrors==1)
                                chi2tmp = chi2tmp + ar.model.data(jd).chi2err(qy);
                            end
                            ndatatmp = ndatatmp + ar.model.data(jd).ndata(qy);
                            
                            fprintf('\tcondition #%i, plot #%i, %s\n', jc, jp, ar.model.data(jd).name);
                        end
                    end
                end
            end
            qnan = isnan(data);
            time = time(~qnan);
            data = data(~qnan);
            
            % label
            if(jc>1)
                tmpstr = '';
                jd = ar.model.condition(jc).dLink(1);
                jdref = ar.model.condition(1).dLink(1);
                for jdc=1:length(ar.model(jm).data(jd).condition)
                    if(str2double(ar.model(jm).data(jd).condition(jdc).value) ~= ...
                            str2double(ar.model(jm).data(jdref).condition(jdc).value))
                        tmpstr = [tmpstr sprintf('%s=%s ',ar.model(jm).data(jd).condition(jdc).parameter, ...
                            ar.model(jm).data(jd).condition(jdc).value)]; %#ok<AGROW>
                    end
                end
            else
                tmpstr = standcond;
            end
            fprintf('\tcondition #%i, %s\n\n', jc, tmpstr);
            
            ctime{jc} = time;
            cdata{jc} = data;
            clabel{jc} = tmpstr;
            nds(jc) = ndstmp;
            chi2s(jc) = chi2tmp;
            ndatas(jc) = ndatatmp;
        end
        fprintf('\n');
        
        % plot
        h = myRaiseFigure(jm, j, ar.model(jm).plot_merged(j).name, figcount);
        
        qsub = ~cellfun(@isempty, ctime);
        nsub = sum(qsub);
        [nrows, ncols] = arNtoColsAndRows(nsub);
        
        subcount = 1;
        if(condition_link_bool)
            qsub(:) = 0;
            qsub(condition_link(:)) = 1;
        end;
        for jc = find(qsub);
            if(~condition_link_bool)
                g = subplot(nrows, ncols, subcount);
                hold(g, 'on');
                box(g, 'on');
            elseif(condition_link_bool && jc == condition_link(1))
                g = subplot(1, 1, 1);
                hold(g, 'on');
                box(g, 'on');
            end;
            
            if(~isempty(ctime{jc}))
                tFine = ar.model.condition(jc).tFine;
                xFine = ar.model.condition(jc).xFineSimu(:,ylink{j});
                plot(g, ar.model.condition(jc).tFine, ar.model.condition(jc).xFineSimu(:,ylink{j}), ...
                    'Color', colors(jc,:));
                tFineP = [tFine; flipud(tFine)];
                xFineP = [xFine + yscale; flipud(xFine - yscale)];
                patch(tFineP, xFineP, zeros(size(xFineP))-2, ones(size(xFineP)), ...
                    'FaceColor', colors(jc,:)*0.1+0.9, 'EdgeColor', colors(jc,:)*0.1+0.9)
                patch(tFineP, xFineP, zeros(size(xFineP))-1, ones(size(xFineP)), 'LineStyle', '--', ...
                    'FaceColor', 'none', 'EdgeColor', colors(jc,:)*0.3+0.7)
                plot(g, ctime{jc}, cdata{jc}, '*', 'Color', colors(jc,:))
            end
            if(~condition_link_bool)
                hold(g, 'off');
            end;
            if(~condition_link_bool)
                if(ar.config.fiterrors == 1)
                    titstr = sprintf('-2 log(L)_{%i} = %g', ndatas(jc), 2*ndatas(jc)*log(sqrt(2*pi)) + chi2s(jc));
                else
                    titstr = sprintf('chi^2_{%i} = %g', ndatas(jc), chi2s(jc));
                end
            else
                titstr = '';
            end
            if(~condition_link_bool)
                title(g, {sprintf('condition %i (#d%i)', jc, nds(jc)), strrep(clabel{jc},'_','\_'), titstr});
            else
                titstr = sprintf('Condition Link:');
                for title_i = 1:length(condition_link)
                    if(ar.config.fiterrors == 1)
                        titstr = strcat([titstr ' ' sprintf('\nCondition %i (#d%i) -2 log(L)_{%i} = %g', condition_link(title_i), nds(condition_link(title_i)) , ndatas(condition_link(title_i)), 2*ndatas(condition_link(title_i))*log(sqrt(2*pi)) + chi2s(condition_link(title_i)))]);
                    else
                        titstr = strcat([titstr ' ' sprintf('\nCondition %i (#d%i) chi^2_{%i} = %g', condition_link(title_i), nds(condition_link(title_i)), ndatas(condition_link(title_i)), chi2s(condition_link(title_i)))]);
                    end
                end;
                title(g, {titstr});
            end
            arSpacedAxisLimits(g);
            if(subcount == (nrows-1)*ncols + 1)
                xlabel(g, sprintf('%s [%s]', ar.model(jm).tUnits{3}, ar.model(jm).tUnits{2}));
            end
            ylabel(g, sprintf('%s [%s]', ar.model(jm).xUnits{ylink{j},3}, ar.model(jm).xUnits{ylink{j},2}));
            
            subcount = subcount + 1;
        end
        
        % save
        if(saveToFile)
            ar.model(jm).plot_merged(j).savePath_FigY = mySaveFigure(h, ar.model(jm).plot_merged(j).name);
        end
        
        figcount = figcount + 1;
    end
end
ar.model.qPlotYs(:) = 0;



function h = myRaiseFigure(m, jplot, figname, figcount)
global ar
openfigs = get(0,'Children');

figcolor = [1 1 1];
figdist = 0.02;

ar.model(m).plot_merged(jplot).time = now;

if(isfield(ar.model(m).plot_merged(jplot), 'fighandel_y') && ~isempty(ar.model(m).plot_merged(jplot).fighandel_y) && ...
        ar.model(m).plot_merged(jplot).fighandel_y ~= 0 && ...
        sum(ar.model(m).plot_merged(jplot).fighandel_y==openfigs)>0 && ...
        strcmp(get(ar.model(m).plot_merged(jplot).fighandel_y, 'Name'), figname))
    
    h = ar.model(m).plot_merged(jplot).fighandel_y;
    figure(h);
else
    h = figure('Name', figname, 'NumberTitle','off', ...
        'Units', 'normalized', 'Position', ...
        [0.1+((figcount-1)*figdist) 0.35-((figcount-1)*figdist) 0.3 0.45]);
    set(h,'Color', figcolor);
    ar.model(m).plot_merged(jplot).fighandel_y = h;
end
clf;

function savePath = mySaveFigure(h, name)

savePath = [arSave '/FiguresMerged/Y'];

if(~exist(savePath, 'dir'))
	mkdir(savePath)
end

savePath = mypath([savePath '/' name]);

saveas(h, savePath, 'fig');
print('-depsc', savePath);
% print('-dpng', savePath);
system(['export LD_LIBRARY_PATH=""; ps2pdf  -dEPSCrop ' savePath '.eps '  savePath '.pdf']);
% plot2svg([savePath '.svg'], h);

function str = mypath(str)
str = strrep(str, ' ', '\ ');
str = strrep(str, '(', '\(');
str = strrep(str, ')', '\)');

