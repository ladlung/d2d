% Plot fit of model parameters to data using Levenberg-Marquardt
%
% arPlotFitLM

function arPlotFit(qp)

global ar

if(~exist('qp','var'))
    qp = true(size(ar.p));
end

figure(2)

chi2s = ar.fit.chi2_hist;
xs = 1:sum(~isnan(chi2s));

subplot(3,2,1)
plot(xs-1, chi2s(xs), '-')
title('likelihood improvement')
xlim([0 length(xs)-1])

subplot(3,2,3)
plot(xs-1, log10(ar.fit.stepsize_hist(xs)), '-')
hold on
plot(xs-1, log10(ar.fit.maxstepsize_hist(xs)), 'r--')
plot([0 length(xs)], log10([ar.config.optim.TolX ar.config.optim.TolX]), 'r--');
hold off
title('log10 stepsize')
xlabel('iterations')
xlim([0 length(xs)-1])

subplot(3,2,5)
plot(xs(2:end)-1, log10(abs(-diff(chi2s(xs)))), '-')
hold on
plot(xlim, log10([ar.config.optim.TolFun ar.config.optim.TolFun]), 'r--');
hold off
title('log10 relativ likelihood improvement')
xlim([0 length(xs)-1])

subplot(3,2,2)
plot(xs-1, ar.fit.p_hist(xs,qp))
title('parameters')
xlim([0 length(xs)-1])

subplot(3,2,4)
plot(xs-1, bsxfun(@minus,ar.fit.p_hist(1,qp),ar.fit.p_hist(xs,qp)))
title('parameter changes relative to start')
xlim([0 length(xs)-1])

subplot(3,2,6)
plot(xs(2:end)-1, diff(ar.fit.p_hist(xs,qp))) 
title('relative parameter changes')
xlabel('iterations')
xlim([0 length(xs)-1])