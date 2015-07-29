% Compile CVODES c-functions
%
% function arCompile(forceFullCompile, forceCompileLast, debug_mode, source_dir)
%
%   forceFullCompile:   recompile all objects files     [false]
%   forceCompileLast:   only recompile mex-file         [false]
%   debug_mode:         exclude precompiled objects     [false]
%   source_dir:         external source directory       []
% 
% or
%
% arCompile(ar, forceFullCompile, forceCompileLast, debug_mode, source_dir)
%   ar:                 d2d model/data structure


function arCompile(varargin)

if(nargin==0 || ~isstruct(varargin{1}))
    global ar %#ok<TLEV>
    
    if(isempty(ar))
        error('please initialize by arInit')
    end
else
    ar = varargin{1};
    if(nargin>1)
        varargin = varargin(2:end);
    else
        varargin = {};
    end
end

usePool = exist('gcp','file')>0 && ~isempty(gcp('nocreate'));

if(~isempty(varargin))
    forceFullCompile = varargin{1};
else
    forceFullCompile = false;
end
if(length(varargin)>1)
    forceCompileLast = varargin{2};
else
    forceCompileLast = false;
end
if(length(varargin)>2)
    debug_mode = varargin{3};
else
    debug_mode = false;
end
if(length(varargin)>3)
    source_dir = varargin{4};
else
    source_dir = pwd;
end

fprintf('\n');

if(length(which('arClusterCompiledHook.m','-all'))>1)
    warning('arClusterCompiledHook.m is found multiple times which can cause compilation errors. Check your matlab path.');
end
if(~ispc)
    ar_path = strrep(which('arInit.m'),'/arInit.m','');
    %sundials_path = [strrep(which('arInit.m'),'/arInit.m','') '/sundials-2.5.0/']; % sundials 2.5.0
    sundials_path = [strrep(which('arInit.m'),'/arInit.m','') '/sundials-2.6.1/']; % sundials 2.6.1
    KLU_path = [strrep(which('arInit.m'),'/arInit.m','') '/KLU-1.2.1/']; % KLU of suitesparse 4.2.1
    compiled_cluster_path = strrep(which('arClusterCompiledHook.m'),'/arClusterCompiledHook.m','');
else
    ar_path = strrep(which('arInit.m'),'\arInit.m','');
    %sundials_path = [strrep(which('arInit.m'),'\arInit.m','') '\sundials-2.5.0\']; % sundials 2.5.0
    sundials_path = [strrep(which('arInit.m'),'\arInit.m','') '\sundials-2.6.1\']; % sundials 2.6.1
    KLU_path = [strrep(which('arInit.m'),'\arInit.m','') '\KLU-1.2.1\']; % KLU of suitesparse 4.2.1
    compiled_cluster_path = strrep(which('arClusterCompiledHook.m'),'\arClusterCompiledHook.m','');
end

% compile directory
if(~exist(['./Compiled/' ar.info.c_version_code '/' mexext], 'dir'))
    mkdir(['./Compiled/' ar.info.c_version_code '/' mexext])
end

%% include directories
includesstr = {};

% CVODES
includesstr{end+1} = ['-I"' sundials_path 'include"'];
includesstr{end+1} = ['-I"' sundials_path 'src/cvodes"'];

% KLU
includesstr{end+1} = ['-I"' KLU_path 'SuiteSparse_config"'];
includesstr{end+1} = ['-I"' KLU_path 'KLU/Include"'];
includesstr{end+1} = ['-I"' KLU_path 'KLU/Source"'];
includesstr{end+1} = ['-I"' KLU_path 'AMD/Include"'];
includesstr{end+1} = ['-I"' KLU_path 'AMD/Source"'];
includesstr{end+1} = ['-I"' KLU_path 'BTF/Include"'];
includesstr{end+1} = ['-I"' KLU_path 'BTF/Source"'];
includesstr{end+1} = ['-I"' KLU_path 'COLAMD/Include"'];
includesstr{end+1} = ['-I"' KLU_path 'COLAMD/Source"'];

% arFramework3
includesstr{end+1} = ['-I"' pwd '/Compiled/' ar.info.c_version_code '"'];
includesstr{end+1} = ['-I"' source_dir '/Compiled/' ar.info.c_version_code '"'];
includesstr{end+1} = ['-I"' ar_path '"'];
includesstr{end+1} = ['-I/usr/local/include'];

if(~isempty(compiled_cluster_path))
    includesstr{end+1} = ['-I"' compiled_cluster_path '/' ar.info.c_version_code '"'];
end

c_version_code = ar.info.c_version_code;
objectsstr = {};
%% pre-compile KLU sources

% source files
sourcesKLU = {
'SuiteSparse_config/SuiteSparse_config.c';
'/KLU/Source/klu.c';
'/KLU/Source/klu_analyze.c';
'/KLU/Source/klu_analyze_given.c';
'/KLU/Source/klu_defaults.c';
'/KLU/Source/klu_diagnostics.c';
'/KLU/Source/klu_dump.c';
'/KLU/Source/klu_extract.c';
'/KLU/Source/klu_factor.c';
'/KLU/Source/klu_free_numeric.c';
'/KLU/Source/klu_free_symbolic.c';
'/KLU/Source/klu_kernel.c';
'/KLU/Source/klu_memory.c';
'/KLU/Source/klu_refactor.c';
'/KLU/Source/klu_scale.c';
'/KLU/Source/klu_solve.c';
'/KLU/Source/klu_sort.c';
'/KLU/Source/klu_tsolve.c';
'/AMD/Source/amd_1.c';
'/AMD/Source/amd_2.c';
'/AMD/Source/amd_aat.c';
'/AMD/Source/amd_control.c';
'/AMD/Source/amd_defaults.c';
'/AMD/Source/amd_dump.c';
'/AMD/Source/amd_global.c';
'/AMD/Source/amd_info.c';
'/AMD/Source/amd_order.c';
'/AMD/Source/amd_post_tree.c';
'/AMD/Source/amd_postorder.c';
'/AMD/Source/amd_preprocess.c';
'/AMD/Source/amd_valid.c';
'/BTF/Source/btf_maxtrans.c';
'/BTF/Source/btf_order.c';
'/BTF/Source/btf_strongcomp.c';
'/COLAMD/Source/colamd.c';
'/COLAMD/Source/colamd_global.c';
    };
sourcesstrKLU = '';
for j=1:length(sourcesKLU)
    sourcesstrKLU = strcat(sourcesstrKLU, [' "' KLU_path sourcesKLU{j} '"']);
end

objectsKLU = {
'SuiteSparse_config.o';
'klu.o';
'klu_analyze.o';
'klu_analyze_given.o';
'klu_defaults.o';
'klu_diagnostics.o';
'klu_dump.o';
'klu_extract.o';
'klu_factor.o';
'klu_free_numeric.o';
'klu_free_symbolic.o';
'klu_kernel.o';
'klu_memory.o';
'klu_refactor.o';
'klu_scale.o';
'klu_solve.o';
'klu_sort.o';
'klu_tsolve.o';
'amd_1.o';
'amd_2.o';
'amd_aat.o';
'amd_control.o';
'amd_defaults.o';
'amd_dump.o';
'amd_global.o';
'amd_info.o';
'amd_order.o';
'amd_post_tree.o';
'amd_postorder.o';
'amd_preprocess.o';
'amd_valid.o';
'btf_maxtrans.o';
'btf_order.o';
'btf_strongcomp.o';
'colamd.o';
'colamd_global.o';
    };
if(ispc)
    objectsKLU = strrep(objectsKLU, '.o', '.obj');
end

for j=1:length(objectsKLU)
    objectsstr = [objectsstr {['./Compiled/' ar.info.c_version_code '/' mexext '/' objectsKLU{j}]}]; %#ok<AGROW>
end



% compile
if(usePool)
    parfor j=1:length(sourcesKLU)
        if(~exist(['Compiled/' c_version_code '/' mexext '/' objectsKLU{j}], 'file') || forceFullCompile)
            mex('-c','-largeArrayDims', '-outdir', ['Compiled/' c_version_code '/' mexext '/'], ...
                includesstr{:}, [KLU_path sourcesKLU{j}]); %#ok<PFBNS>
            fprintf('compiling KLU(%s)...done\n', objectsKLU{j});
        else
            fprintf('compiling KLU(%s)...skipped\n', objectsKLU{j});
        end
    end
else
    for j=1:length(sourcesKLU)
        if(~exist(['Compiled/' c_version_code '/' mexext '/' objectsKLU{j}], 'file') || forceFullCompile)
            mex('-c','-largeArrayDims', '-outdir', ['Compiled/' c_version_code '/' mexext '/'], ...
                includesstr{:}, [KLU_path sourcesKLU{j}]);
            fprintf('compiling KLU(%s)...done\n', objectsKLU{j});
        else
            fprintf('compiling KLU(%s)...skipped\n', objectsKLU{j});
        end
    end
end

%% pre-compile CVODES sources

% source files
sources = {
    'src/cvodes/cvodes_band.c';
    'src/cvodes/cvodes_bandpre.c';
    'src/cvodes/cvodes_bbdpre.c';
    'src/cvodes/cvodes_direct.c';
    'src/cvodes/cvodes_dense.c';
    'src/cvodes/cvodes_klu.c';
    'src/cvodes/cvodes_sparse.c';
    'src/cvodes/cvodes_diag.c';
    'src/cvodes/cvodea.c';
    'src/cvodes/cvodes.c';
    'src/cvodes/cvodes_io.c';
    'src/cvodes/cvodea_io.c';
    'src/cvodes/cvodes_spils.c';
    'src/cvodes/cvodes_spbcgs.c';
    'src/cvodes/cvodes_spgmr.c';
    'src/cvodes/cvodes_sptfqmr.c';
    'src/sundials/sundials_band.c';
    'src/sundials/sundials_dense.c';
    'src/sundials/sundials_sparse.c';
    'src/sundials/sundials_iterative.c';
    'src/sundials/sundials_nvector.c';
    'src/sundials/sundials_direct.c';
    'src/sundials/sundials_spbcgs.c';
    'src/sundials/sundials_spgmr.c';
    'src/sundials/sundials_sptfqmr.c';
    'src/sundials/sundials_math.c';
    'src/nvec_ser/nvector_serial.c';
    };
sourcesstr = '';
for j=1:length(sources)
    sourcesstr = strcat(sourcesstr, [' "' sundials_path sources{j} '"']);
end

% objects
objects = {
    'cvodes_band.o';
    'cvodes_bandpre.o';
    'cvodes_bbdpre.o';
    'cvodes_direct.o';
    'cvodes_dense.o';    
    'cvodes_klu.o';
    'cvodes_sparse.o';
    'cvodes_diag.o';
    'cvodea.o';
    'cvodes.o';
    'cvodes_io.o';
    'cvodea_io.o';
    'cvodes_spils.o';
    'cvodes_spbcgs.o';
    'cvodes_spgmr.o';
    'cvodes_sptfqmr.o';
    'sundials_band.o';
    'sundials_dense.o';
    'sundials_sparse.o';
    'sundials_iterative.o';
    'sundials_nvector.o';
    'sundials_direct.o';
    'sundials_spbcgs.o';
    'sundials_spgmr.o';
    'sundials_sptfqmr.o';
    'sundials_math.o';
    'nvector_serial.o';
    'arInputFunctionsC.o';
    };
if(ispc)
    objects = strrep(objects, '.o', '.obj');
end

for j=1:length(objects)
    objectsstr = [objectsstr {['./Compiled/' ar.info.c_version_code '/' mexext '/' objects{j}]}]; %#ok<AGROW>
end

% compile
if(usePool)
    parfor j=1:length(sources)
        if(~exist(['Compiled/' c_version_code '/' mexext '/' objects{j}], 'file') || forceFullCompile)
            mex('-c','-largeArrayDims', '-outdir', ['Compiled/' c_version_code '/' mexext '/'], ...
                includesstr{:}, [sundials_path sources{j}]); %#ok<PFBNS>
            fprintf('compiling CVODES(%s)...done\n', objects{j});
        else
            fprintf('compiling CVODES(%s)...skipped\n', objects{j});
        end
    end
else
    for j=1:length(sources)
        if(~exist(['Compiled/' c_version_code '/' mexext '/' objects{j}], 'file') || forceFullCompile)
            mex('-c','-largeArrayDims', '-outdir', ['Compiled/' c_version_code '/' mexext '/'], ...
                includesstr{:}, [sundials_path sources{j}]);
            fprintf('compiling CVODES(%s)...done\n', objects{j});
        else
            fprintf('compiling CVODES(%s)...skipped\n', objects{j});
        end
    end
end

%% pre-compile input functions
if(~ispc)
    objects_inp = ['./Compiled/' ar.info.c_version_code '/' mexext '/arInputFunctionsC.o'];
else
    objects_inp = ['./Compiled/' ar.info.c_version_code '/' mexext '/arInputFunctionsC.obj'];
end

if(~exist(objects_inp, 'file') || forceFullCompile)
    mex('-c','-largeArrayDims','-outdir',['Compiled/' ar.info.c_version_code '/' mexext '/'], ...
        includesstr{:}, [ar_path '/arInputFunctionsC.c']);
    fprintf('compiling input functions...done\n');
else
    fprintf('compiling input functions...skipped\n');
end

% TODO I don't know why this gives a link error ... ?
% if(~debug_mode)
%     objectsstr = [objectsstr {objects_inp}];
% end

%% pre-compile conditions
objects_con = {};
file_con = {};
ms = [];
cs = [];
for jm = 1:length(ar.model)
    for jc = 1:length(ar.model(jm).condition)
        if(~ispc)
            objects_con{end+1} = ['./Compiled/' ar.info.c_version_code '/' mexext '/' ar.model(jm).condition(jc).fkt '.o']; %#ok<AGROW>
        else
            objects_con{end+1} = ['./Compiled/' ar.info.c_version_code '/' mexext '/' ar.model(jm).condition(jc).fkt '.obj']; %#ok<AGROW>
        end
        file_con{end+1} = [ar.model(jm).condition(jc).fkt '.c']; %#ok<AGROW>
        ms(end+1) = jm; %#ok<AGROW>
        cs(end+1) = jc; %#ok<AGROW>
    end
end

if(usePool)
    parfor j=1:length(objects_con)
        if(~exist(objects_con{j}, 'file') || forceFullCompile)
            if(isempty(compiled_cluster_path))
                mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                    includesstr{:}, [source_dir '/Compiled/' c_version_code '/' file_con{j}]);  %#ok<PFBNS>
            else
                mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                    includesstr{:}, [compiled_cluster_path '/' c_version_code '/' file_con{j}]);
            end
            fprintf('compiling condition m%i c%i, %s...done\n', ms(j), cs(j), file_con{j});
        else
            fprintf('compiling condition m%i c%i, %s...skipped\n', ms(j), cs(j), file_con{j});
        end
    end
else
    for j=1:length(objects_con)
        if(~exist(objects_con{j}, 'file') || forceFullCompile)
            if(isempty(compiled_cluster_path))
                mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                    includesstr{:}, [source_dir '/Compiled/' c_version_code '/' file_con{j}]);
            else
                mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                    includesstr{:}, [compiled_cluster_path '/' c_version_code '/' file_con{j}]);
            end
            fprintf('compiling condition m%i c%i, %s...done\n', ms(j), cs(j), file_con{j});
        else
            fprintf('compiling condition m%i c%i, %s...skipped\n', ms(j), cs(j), file_con{j});
        end
    end
end

if(~debug_mode)
    objectsstr = [objectsstr objects_con];
end

%% pre-compile data
if(isfield(ar.model, 'data'))
    objects_dat = {};
    file_dat = {};
    ms = [];
    ds = [];

    for jm = 1:length(ar.model)
        for jd = 1:length(ar.model(jm).data)                       
            if(~ispc)
                objects_dat{end+1} = ['./Compiled/' ar.info.c_version_code '/' mexext '/' ar.model(jm).data(jd).fkt '.o']; %#ok<AGROW>
            else
                objects_dat{end+1} = ['./Compiled/' ar.info.c_version_code '/' mexext '/' ar.model(jm).data(jd).fkt '.obj']; %#ok<AGROW>
            end
            file_dat{end+1} = [ar.model(jm).data(jd).fkt '.c']; %#ok<AGROW>
            ms(end+1) = jm; %#ok<AGROW>
            ds(end+1) = jd; %#ok<AGROW>
        end
    end
    
    if(usePool)
        parfor j=1:length(objects_dat)
            if(~exist(objects_dat{j}, 'file') || forceFullCompile)
                if(isempty(compiled_cluster_path))
                    mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                        includesstr{:}, [source_dir '/Compiled/' c_version_code '/' file_dat{j}]);  %#ok<PFBNS>
                else
                    mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                        includesstr{:}, [compiled_cluster_path '/' c_version_code '/' file_dat{j}]);
                end
                fprintf('compiling data m%i d%i, %s...done\n', ms(j), ds(j), file_dat{j});
            else
                fprintf('compiling data m%i d%i, %s...skipped\n', ms(j), ds(j), file_dat{j});
            end
        end
    else
        for j=1:length(objects_dat)
            if(~exist(objects_dat{j}, 'file') || forceFullCompile)
                if(isempty(compiled_cluster_path))
                    mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                        includesstr{:}, [source_dir '/Compiled/' c_version_code '/' file_dat{j}]);
                else
                    mex('-c','-largeArrayDims','-outdir',['./Compiled/' c_version_code '/' mexext '/'], ...
                        includesstr{:}, [compiled_cluster_path '/' c_version_code '/' file_dat{j}]);
                end
                fprintf('compiling data m%i d%i, %s...done\n', ms(j), ds(j), file_dat{j});
            else
                fprintf('compiling data m%i d%i, %s...skipped\n', ms(j), ds(j), file_dat{j});
            end
        end
    end
    
    if(~debug_mode)
        objectsstr = [objectsstr objects_dat];
    end
end

includesstr=strrep(includesstr,'"', '');
%% compile and link main mex file
if(~exist([ar.fkt '.' mexext],'file') || forceFullCompile || forceCompileLast)
    if(~ispc)
        % parallel code using POSIX threads for Unix type OS

        mex('-largeArrayDims','-output', ar.fkt, includesstr{:}, '-DHAS_PTHREAD=1', ...
            sprintf('-DNMAXTHREADS=%i', ar.config.nMaxThreads), ...
            which('arSimuCalc.c'), objectsstr{:});
    else
        % parallel code using POSIX threads (pthread-win32) for Windows type OS
        includesstr{end+1} = ['-I"' ar_path '\pthreads-w32_2.9.1\include"'];
        includesstr{end+1} = ['-L"' ar_path '\pthreads-w32_2.9.1\lib\' mexext '"'];
        includesstr{end+1} = '-lpthreadVC2';

        mex('-largeArrayDims','-output', ar.fkt, includesstr{:}, '-DHAS_PTHREAD=1', ...
            sprintf('-DNMAXTHREADS=%i', ar.config.nMaxThreads), ...
            which('arSimuCalc.c'), objectsstr{:});
    end
    fprintf('compiling and linking %s...done\n', ar.fkt);
else
    fprintf('compiling and linking %s...skipped\n', ar.fkt);
end

%% refresh file cache
rehash

