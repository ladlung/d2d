% Load models & data

arInit
arLoadModel('pnas_jak_stat');
arLoadData('pnas_data_original');
arCompileAll(2);

% load best fit parameter values
arLoadPars('BestFit');

useErrorModel = true;
if(~useErrorModel)
    % do not fit error model
    ar.config.fiterrors = -1;
    
    % show error bars instead of error model
    ar.config.ploterrors = 1;
    
    % show, but not fit input data for pEpoR
    ar.model.data.qFit(3) = 0;
    
    % fix parameter for input and error model
    arSetPars('sp1',[],2);
    arSetPars('sp2',[],2);
    arSetPars('sp3',[],2);
    arSetPars('sp4',[],2);
    arSetPars('sp5',[],2);
    arSetPars('scale_pEpoR',[],2);
    arSetPars('sd_pEpoR_au',[],2);
    arSetPars('sd_pSTAT_au',[],2);
    arSetPars('sd_tSTAT_au',[],2);
end

arPlot;
arPrint;

%Compute prediction bands for tSTAT and plot them in combination with
%validation profile thresholds for t=0, 10, 20, 30, 50 min
% doPPL(1,1,1,[0 10 20 30 50],1,2,0.5);
% ar.config.ploterrors=-1;
% arPlot2
