% send a single fit to a matlab cluster worker

function arFitCluster(cluster)

global ar
global ar_fit_cluster

if(isempty(ar_fit_cluster)) % new job
    fprintf('arFitCluster sending job...');
    ar_fit_cluster = batch(cluster, @arFitClusterFun, 1, {ar}, ...
        'CaptureDiary', true, ...
        'CurrentFolder', '.');
    fprintf('done\n');
    
elseif(isa(ar_fit_cluster,'parallel.job.MJSIndependentJob')) % old job
    fprintf('arFitCluster (ID %i) ', ar_fit_cluster.ID);
    
    if(~strcmp(ar_fit_cluster.State, 'finished')) % still running
        fprintf('status %s...\n', ar_fit_cluster.State);
    else % finished
        try
            fprintf('retrieving results %s...\n', ar_fit_cluster.State);
            diary(ar_fit_cluster);
            S = fetchOutputs(ar_fit_cluster);
            ar = S{1};
            delete(ar_fit_cluster);
            clear global ar_fit_cluster
            arFitPrint;
        catch err_id
            delete(ar_fit_cluster);
            clear global ar_fit_cluster
            rethrow(err_id);
        end
    end
else
    error('arFitCluster global variable ar_fit_cluster is invalid!\n');
end

function ar = arFitClusterFun(ar)
ar = arFit(ar);
