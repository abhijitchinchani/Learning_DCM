% List of open inputs
nrun = X; % enter the number of runs here
jobfile = {'/Users/abhijitc/Documents/Abhijit/LenaLab_DCM/spDCM/batch_volExtract_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(0, nrun);
for crun = 1:nrun
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
