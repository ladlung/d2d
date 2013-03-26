% fit sequence
%
% arFits(ps, append)
%
% ps:                           parameter values      
% append:                       [false]
% dynamic_only                  [true]

function arFits(ps, append, dynamic_only, plot_summary)

global ar

if(~exist('append','var'))
    append = false;
end
if(~exist('dynamic_only','var'))
    dynamic_only = false;
end
if(~exist('plot_summary','var'))
    plot_summary = false;
end

n = size(ps,1);

arChi2(true);
pReset = ar.p;
chi2Reset = ar.chi2fit;

if(append && isfield(ar,'ps') && isfield(ar, 'chi2s') && ...
        isfield(ar, 'exitflag') && isfield(ar, 'timing') && ...
        isfield(ar, 'fun_evals'))
    ar.ps = [nan(n, length(ar.p)); ar.ps];
    ar.ps_start = [ps; ar.ps_start];
    ar.chi2s = [nan(1,n) ar.chi2s];
    ar.timing = [nan(1,n) ar.timing];
    ar.exitflag = [-ones(1,n) ar.exitflag];
    ar.fun_evals = [nan(1,n) ar.fun_evals];
    
else
    ar.ps = nan(n, length(ar.p));
    ar.ps_start = ps;
    ar.chi2s = nan(1,n);
    ar.timing = nan(1,n);
    ar.fun_evals = nan(1,n);
    ar.exitflag = -ones(1,n);
end

if(~dynamic_only)
    q_select = ar.qFit==1 & ar.qDynamic==1;
else
    q_select = ar.qFit==1;
end

if(sum(q_select)<6)
    figure(1)
    plotmatrix(ps(:,q_select), 'x');
end

arWaitbar(0);
for j=1:n
    if(ar.config.fiterrors == 1)  
        text = sprintf('best minimum: -2*log(L) = %f (old = %f)', ...
            min(2*ar.ndata*log(sqrt(2*pi)) + ar.chi2s), 2*ar.ndata*log(sqrt(2*pi)) + chi2Reset);
    else
        text = sprintf('best minimum: chi^2 = %f (old = %f)', min(ar.chi2s), chi2Reset);
    end
    arWaitbar(j, n, text);
    ar.p = ps(j,:);
    tic;
    try
        if(dynamic_only)
            arFitObs(true);
        end
        arFit(true);
        ar.ps(j,:) = ar.p;
        ar.chi2s(j) = ar.chi2fit;
        ar.exitflag(j) = ar.fit.exitflag;
        ar.fun_evals(j) = ar.fevals;
    catch exception
        fprintf('fit #%i: %s\n', j, exception.message);
    end
    ar.timing(j) = toc;
end
fprintf('totol fitting time: %fsec\n', sum(ar.timing(~isnan(ar.timing))));
fprintf('mean fitting time: %fsec\n', 10^mean(log10(ar.timing(~isnan(ar.timing)))));
arWaitbar(-1);

if(chi2Reset>min(ar.chi2s))
    [chi2min,imin] = min(ar.chi2s);
    ar.p = ar.ps(imin,:);
    if(ar.config.fiterrors == 1)
        fprintf('selected best fit #%i with -2*log(L) = %f (old = %f)\n', ...
            imin, 2*ar.ndata*log(sqrt(2*pi)) + chi2min, 2*ar.ndata*log(sqrt(2*pi)) + chi2Reset);
    else
        fprintf('selected best fit #%i with chi^2 = %f (old = %f)\n', imin, chi2min, chi2Reset);
    end
else
    fprintf('did not find better fit\n');
    ar.p = pReset;
end
arChi2(false);

if plot_summary
    if(sum(q_select)<6)
        figure(2)
        plotmatrix(ar.ps(:,q_select), 'x');
    end
    
    arPlotChi2s
end
<<<<<<< mine

arPlotFits
=======
>>>>>>> theirs
