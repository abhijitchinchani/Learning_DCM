%% Builds an example analysis for demonstrating SPM PEB
%
% Peter Zeidman, 2024
%
% References:
%
% Tak, Y.W., Knights, E., Henson, R. and Zeidman, P., 2021. 
% Ageing and the ipsilateral M1 BOLD response: a connectivity study. 
% Brain sciences, 11(9), p.1130.
%
% Taylor, J.R., Williams, N., Cusack, R., Auer, T., Shafto, M.A., 
% Dixon, M., Tyler, L.K. and Henson, R.N., 2017. The Cambridge Centre for 
% Ageing and Neuroscience (Cam-CAN) data repository: Structural and 
% functional MRI, MEG, and cognitive data from a cross-sectional adult 
% lifespan sample. Neuroimage, 144, pp.262-269.

tak_download_dir = 'D:\experiments\Methods\spm_docs_example_tak\downloaded';

%% Prepare design matrix for PEB

% Get the age of each participant
load(fullfile(tak_download_dir,'subject_metadata','subjects635.mat'));
age = meta.Age;

% Identify subjects with negative rM1 response
load(fullfile(tak_download_dir,'subject_metadata','cluster_assignments.mat'));
is_negative_responder = (y_rM1 < 0);

% Create design matrix
nsubjects = length(age);
X = [ones(nsubjects,1) is_negative_responder zscore(age)];

% Orthogonalise design matrix
X = spm_orth(X);

% Reorder subjects for clarity of display
[~,tak_idx] = sort(is_negative_responder);
X = X(tak_idx,:);

Xnames = {'Mean','Group (Nve - Pve rM1)','Residual age'};

save('participants.mat','X','Xnames','tak_idx');

%% First level DCM analysis 

% Load original DCMs from Tak et al
load(fullfile(tak_download_dir,'DCM','GCM_left_driving_full_estimated_twice.mat'));

% Select regions of interest (ROIs) to retain
regions_to_retain = [2 5 1 4]; % lPMd, rPMd, lM1, rM1
nregions = length(regions_to_retain);

for s = 1:nsubjects
    DCM = GCM{s};
        
    % Get number of time points
    nv = length(DCM.xY(1).u);                
    
    % Get number of conditions
    nconditons = size(DCM.U.u,2);
    
    % Limit to just the selected regions
    DCM.a = DCM.a(regions_to_retain,regions_to_retain);
    DCM.b = DCM.b(regions_to_retain,regions_to_retain,:);
        
    % Disconnect homotopic connections
    DCM.a = [1 0 1 1;
             0 1 1 1;
             1 1 1 0;
             1 1 0 1];
    
    % Set only PMd driving
    DCM.c = zeros(nregions,nconditons);
    DCM.c(1:2,:) = 1;
    
    % Disable non-linear effects
    DCM.d = zeros(nregions,nregions,0);    
    
    % Set new ROI metadata
    DCM.xY = DCM.xY(regions_to_retain);    
    DCM.xY(1).name = 'lPMd';
    DCM.xY(2).name = 'rPMd';
    DCM.xY(3).name = 'lM1';    
    DCM.xY(4).name = 'rM1';    
    
    % Set new data y and covariance components Q
    DCM.n = nregions;    
    DCM.Y.y = DCM.Y.y(:,regions_to_retain);    
    DCM.Y.Q = spm_Ce(ones(1,nregions)*nv);
    
    % Delete old priors
    DCM = rmfield(DCM,'M');
        
    % Replace original DCM
    GCM{s} = DCM;
    
end

% Fit to data
GCM = spm_dcm_fit(GCM,true);

% Re-order participants to match metadata
GCM = GCM(tak_idx,:);

% Save
save('GCM_tak.mat','GCM');
%% Remove long pathnames from the DCMs
for i = 1:length(GCM)
    DCM = GCM{i};
    for j = 1:length(DCM.xY)
        [~,fname,ext] = fileparts(DCM.xY(j).spec.fname);
        DCM.xY(j).spec.fname = [fname ext];
    end
    GCM{i} = DCM;
end
save('GCM_tak.mat','GCM');

%% Create template DCMs for PEB
nregions = 4;
ninputs  = 3;

% Get one subject's DCM to use as a template
DCM = GCM{1};

% Clear out old priors
DCM = rmfield(DCM,'M');

% Model 1, interhemispheric
DCM.a = [0 0 0 1;
         0 0 0 0;
         0 0 0 0;
         1 0 0 0];
GCM = cell(1,2);
GCM{1} = DCM;

% Model 2, intrahemispheric
DCM.a = [0 0 0 0;
         0 0 0 1;
         0 0 0 0;
         0 1 0 0];

GCM{2} = DCM;

% Model 3, intrinsic
DCM.a = [0 0 0 0;
         0 0 0 0;
         0 0 0 0;
         0 0 0 1];

GCM{3} = DCM;

% Model 4, null
DCM.a = [0 0 0 0;
         0 0 0 0;
         0 0 0 0;
         0 0 0 0];

GCM{4} = DCM;

save('GCM_templates.mat','GCM');
