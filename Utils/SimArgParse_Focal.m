function args = SimArgParse_Focal(varargin)
% Script to define the key arguments for the simulation:
%     Generic mesh and simulation parameters
%     Focal episode specific parameters for the simulation
%     EGM parameters, including the NSR templat to use and the elctrodes to record from
%     Therapy parameters - including max numbers of calls per zone (VT1, VT, VF)

p = inputParser;
p.KeepUnmatched = true;

% --- Focal Episode --- %
addParameter(p, 'focal_site', 'Focal_Site.vtx');
addParameter(p, 'focal_start', 0);
addParameter(p, 'episodes', 1);
addParameter(p, 'episode_interval', 1000);
addParameter(p, 'focal_pls', 10);
addParameter(p, 'focal_bcl', 300);
addParameter(p, 'focal_strength', 450);
addParameter(p, 'focal_duration', 4);

% --- EGM --- %
addParameter(p, 'EGM_template', 'EGM_NSR');
addParameter(p, 'electrodes', 'electrodesICD');
addParameter(p, 'EGM_name', 'EGM_focal_VT');
addParameter(p, 'EGM_features_name', 'EGM_features_focal_VT');

% --- Therapy --- %
% Burst only flag - default is 0 (off), pass 1 to only model burst ATP
addParameter(p, 'Burst_only', 0);

% Universal Parameters % 
addParameter(p, 'ATP_strength', 450);
addParameter(p, 'ATP_duration', 4);
addParameter(p, 'ATP_stimsite', 'ATP_stim.vtx');
addParameter(p, 'max_therapy_calls', [3 3 2]);
addParameter(p, 'ATP_Min_Cycle', 220.00);

% VT1 Parameters % 
addParameter(p, 'VT1_ATP_CL', 0.81);
addParameter(p, 'VT1_ATP_coupling', 0.81);
addParameter(p, 'VT1_ATP_pls', 8.00);
addParameter(p, 'VT1_ATP_dec', 10.00);


% VT Parameters % 
addParameter(p, 'VT_ATP_CL', 0.81);
addParameter(p, 'VT_ATP_coupling', 0.81);
addParameter(p, 'VT_ATP_pls', 8.00);
addParameter(p, 'VT_ATP_dec', 10.00);

% VF parameters % 
addParameter(p, 'QC_ATP_CL', 0.88);
addParameter(p, 'QC_ATP_coupling', 0.88);
addParameter(p, 'QC_ATP_pls', 8);

% --- Mesh + NSR --- %
addParameter(p, 'mesh', 'meshname');
addParameter(p, 'myocardium', 1);
addParameter(p, 'scar_flag', 1);
addParameter(p, 'scar_region', 2);
addParameter(p, 'isthmus_region', 3);
addParameter(p, 'conmul', 1.0);
addParameter(p, 'input_state', 'input_state');
addParameter(p, 'model', 'tenTusscherPanfilov');
addParameter(p, 'bcl', 800);
addParameter(p, 'strength', 450);
addParameter(p, 'duration', 4);
addParameter(p, 'start', 0);
addParameter(p, 'NSR_vtx', 'NSR.vtx');
addParameter(p, 'output_res', 1);
addParameter(p, 'check', 1000);

parse(p, varargin{:});
args = p.Results;

%save('SimParam.mat', 'args');


end
