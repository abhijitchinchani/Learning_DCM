% Settings
% -------------------------------------------------------------------------
subject = 'sub-01';

func_dir = sprintf('../fMRI/%s/func/',subject);

GLM_dir = sprintf('../GLM/%s/',subject);

spm_mat = fullfile(GLM_dir,'SPM.mat');

% Timeseries extraction
% -------------------------------------------------------------------------
clear matlabbatch
matlabbatch{1}.spm.util.voi.spmmat  = cellstr(spm_mat);
matlabbatch{1}.spm.util.voi.adjust  = 1;                    % "effects of interest" F-contrast
matlabbatch{1}.spm.util.voi.session = 1;                    % session 1
matlabbatch{1}.spm.util.voi.roi{1}.spm.spmmat = {''};       % using SPM.mat above
matlabbatch{1}.spm.util.voi.roi{1}.spm.threshdesc = 'none'; % no correction
matlabbatch{1}.spm.util.voi.roi{1}.spm.thresh = 0.001;
matlabbatch{1}.spm.util.voi.roi{1}.spm.extent = 0;
matlabbatch{1}.spm.util.voi.roi{2}.sphere.radius = 8;
matlabbatch{1}.spm.util.voi.roi{2}.sphere.move.fixed = 1;
matlabbatch{1}.spm.util.voi.expression = 'i1 & i2';

% Semantic-perceptual T-contrast to select voxels
matlabbatch{1}.spm.util.voi.roi{1}.spm.contrast = 2;

% ldF
start_dir = pwd;
matlabbatch{1}.spm.util.voi.name = 'ldF';
matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = [-50,16,34];
spm_jobman('run',matlabbatch);

% rdF
cd(start_dir);
matlabbatch{1}.spm.util.voi.name = 'rdF';
matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = [54, 22, 32];
spm_jobman('run',matlabbatch);

% lvF
cd(start_dir);
matlabbatch{1}.spm.util.voi.name = 'lvF';
matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = [-34,34,-10];
spm_jobman('run',matlabbatch);

% rvF
cd(start_dir);
matlabbatch{1}.spm.util.voi.name = 'rvF';
matlabbatch{1}.spm.util.voi.roi{2}.sphere.centre = [26 34 -14];
spm_jobman('run',matlabbatch);
cd(start_dir);

% DCM specification
% -------------------------------------------------------------------------
n   = 4;    % number of regions
nu  = 3;    % number of inputs (experimental conditions)
TR  = 3.6;  % volume repetition time (seconds)
TE  = 0.05; % echo time (seconds)

% Experimental conditions to include from the SPM.
% We'll create a "Task" condition, which includes Picture and Words trials,
% to drive the network. We'll use Picture and Word trials seprately to
% modulate the self-connections.
cond = struct();

cond(1).name    = 'Pictures'; % Name of condition for the DCM
cond(1).spmname = 'Pictures'; % Name of conditions in SPM

cond(2).name    = 'Words';
cond(2).spmname = 'Words';

cond(3).name    = 'Task';               
cond(3).spmname = {'Pictures','Words'}; 

% VOIs
xY = {fullfile(GLM_dir,'VOI_lvF_1.mat');
      fullfile(GLM_dir,'VOI_ldF_1.mat');
      fullfile(GLM_dir,'VOI_rvF_1.mat');
      fullfile(GLM_dir,'VOI_rdF_1.mat');
     };
 
% Average connectivity
a  = [1 1 1 0
      1 1 0 1
      1 0 1 1
      0 1 1 1];
  
% Modulatory inputs
b  = zeros(n,n,nu);
b(:,:,1) = eye(4); % Pictures -> self-connections
b(:,:,2) = eye(4); % Words    -> self-connections

% Driving inputs
c = zeros(n,nu);
c(:,3) = 1;        % Task -> all regions

% Non-linear connections (not used)
d = zeros(n,n,0);

% DCM settings
s = struct();
s.name       = 'm1';
s.cond       = cond;
s.delays     = repmat(TR/2, 1, n);
s.TE         = TE;
s.nonlinear  = false;
s.two_state  = false;
s.stochastic = false;
s.centre     = true;
s.induced    = 0;
s.a          = a;
s.b          = b;
s.c          = c;
s.d          = d;

% Specify DCM - model 1
SPM = fullfile(GLM_dir,'SPM.mat');
DCM = spm_dcm_specify(SPM,xY,s);

% Specify alternate model where pictures & words only differ in the ventral
% regions (lvF and rvF)
% -------------------------------------------------------------------------
% Modulatory inputs
b  = zeros(n,n,nu);
b(:,:,1) = [1 0 0 0
            0 0 0 0
            0 0 1 0
            0 0 0 0]; % Pictures -> ventral regions only
        
b(:,:,1) = [1 0 0 0
            0 0 0 0
            0 0 1 0
            0 0 0 0]; % Words    -> ventral regions only

s.b = b;
s.name = 'm2';

% Specify DCM - model 2
SPM = fullfile(GLM_dir,'SPM.mat');
DCM = spm_dcm_specify(SPM,xY,s);

% Specify alternate model where pictures & words only differ in the dorsal
% regions (dvF and dvF)
% -------------------------------------------------------------------------
% Modulatory inputs
b  = zeros(n,n,nu);
b(:,:,1) = [0 0 0 0
            0 1 0 0
            0 0 0 0
            0 0 0 1]; % Pictures -> dorsal regions only
        
b(:,:,2) = [0 0 0 0
            0 1 0 0
            0 0 0 0
            0 0 0 1]; % Words    -> dorsal regions only

s.b = b;
s.name = 'm3';

% Specify DCM - model 2
SPM = fullfile(GLM_dir,'SPM.mat');
DCM = spm_dcm_specify(SPM,xY,s);

% Specify null model - no modulation
% -------------------------------------------------------------------------
b  = zeros(n,n,nu);
s.b = b;
s.name = 'm4';

% Specify DCM - model 4
SPM = fullfile(GLM_dir,'SPM.mat');
DCM = spm_dcm_specify(SPM,xY,s);

% Estimate both models (using Bayesian model reduction for model 2) and
% perform Bayesian model comparison
% -------------------------------------------------------------------------
models = {fullfile(GLM_dir,'DCM_m1.mat');
          fullfile(GLM_dir,'DCM_m2.mat');
          fullfile(GLM_dir,'DCM_m3.mat');
          fullfile(GLM_dir,'DCM_m4.mat')};

clear matlabbatch
matlabbatch{1}.spm.dcm.estimate.dcms.subj.dcmmat = cellstr(models);
matlabbatch{1}.spm.dcm.estimate.output.single.dir = cellstr(GLM_dir);
matlabbatch{1}.spm.dcm.estimate.output.single.name = 'four_models';
matlabbatch{1}.spm.dcm.estimate.est_type = 1;
matlabbatch{1}.spm.dcm.estimate.fmri.analysis = 'time';
spm_jobman('run',matlabbatch);    