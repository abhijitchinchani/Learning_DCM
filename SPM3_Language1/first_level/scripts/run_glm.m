% First level analysis of the Seghier et al semantic matching task.
% NB Before running this script, please change directory in Matlab to the
% /scripts/ directory.
%
% This is 2 x 2 design: task (semantic vs picture matching) and stimulus
% type (pictures or words).
%
% We will use data from a single participant, with four regions: two ventral 
% (lvF, rvF) and two dorsal (ldF, rdF). We will ask the question: do all   
% four regions distinguish pictures and words (model 1), or just the dorsal 
% regions (model 2)?
% _________________________________________________________________________

% Settings
% -------------------------------------------------------------------------
subject = 'sub-01';

func_dir = sprintf('../fMRI/%s/func/',subject);

GLM_dir = sprintf('../GLM/%s/',subject);

% Prepare files and directories
% -------------------------------------------------------------------------
% Create output directory
if ~exist(GLM_dir,'file')
    mkdir(GLM_dir);
end

% Select functionals (4D niftis)
epi_sess1 = spm_select('ExtFPList',func_dir,'.*run-01_desc-preproc_bold.nii$',1:999);
epi_sess2 = spm_select('ExtFPList',func_dir,'.*run-02_desc-preproc_bold.nii$',1:999);

% Select onsets
onsets = spm_select('FPList',func_dir,'.*run-all_events.mat$');

% GLM specification
% -------------------------------------------------------------------------

% Create batch
clear matlabbatch;
matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr(GLM_dir);
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = 3.6;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

% GLM settings
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond  = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128;
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.6;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

% EPIs
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr([epi_sess1; epi_sess2]);

% Onsets
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = cellstr(onsets);

% Head movement (not used in this paradigm due to covert speech production)
%matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = cellstr(rp_sess1);
%matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = cellstr(rp_sess2);

% Run
spm_jobman('run',matlabbatch);

% GLM session (run) concatenation
% -------------------------------------------------------------------------
spm_mat = fullfile(GLM_dir,'SPM.mat');
nscans = [size(epi_sess1,1) size(epi_sess2,1)];
spm_fmri_concatenate(spm_mat,nscans);

% GLM estimation
% -------------------------------------------------------------------------
clear matlabbatch;
matlabbatch{1}.spm.stats.fmri_est.spmmat = cellstr(spm_mat);
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;

% Run
spm_jobman('run',matlabbatch);

% Add contrasts
% -------------------------------------------------------------------------
clear matlabbatch;
matlabbatch{1}.spm.stats.con.spmmat(1) = cellstr(spm_mat);

matlabbatch{1}.spm.stats.con.consess{1}.fcon.name = 'Effects of interest';
matlabbatch{1}.spm.stats.con.consess{1}.fcon.weights = [1 0 0 0
                                                        0 1 0 0
                                                        0 0 1 0
                                                        0 0 0 1];
matlabbatch{1}.spm.stats.con.consess{1}.fcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'Semantic - Perceptual';
matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [1 1 -1 -1];
matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'Words-Pictures';
matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [-1 1 -1 1];
matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{4}.fcon.name = 'Interaction';
matlabbatch{1}.spm.stats.con.consess{4}.fcon.weights = [1 -1 -1 1];
matlabbatch{1}.spm.stats.con.consess{4}.fcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.consess{5}.tcon.name = 'Task (pve)';
matlabbatch{1}.spm.stats.con.consess{5}.tcon.weights = [1 1 1 1];
matlabbatch{1}.spm.stats.con.consess{5}.tcon.sessrep = 'repl';

matlabbatch{1}.spm.stats.con.delete = 1;

% Run 
spm_jobman('run',matlabbatch);