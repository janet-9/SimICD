%% 

% Initialisation of the environment

% Path initialisation 
init_paths(); 
% Full path to the Python executable - Allows the python scripts to run
pythonExe = '/opt/anaconda3/bin/python';

% Set parameters for the ICD, using the default values from Boston
% Scientific
%3 therapy zones, VT_1, VT, VF 
%Threshold for Quick Convert override - straight to shock 
ICDparam.VF_th = 300;
ICDparam.QC_Override_th = 240;
ICDparam.VT_th = 353;
ICDparam.VT_1_th = 429;

%Duration parameters, can be set between 1s-60s for VT_1, 1s-30s for VT and
%1s-15s for VF. Here, use nominal values - which is 2.5s for all zones.
ICDparam.VF_dur = 2500;
ICDparam.VT_dur = 2500;
ICDparam.VT_1_dur = 2500; 

ICDparam.VTC_corr_th = 0.94;
ICDparam.Afib_th = 353;
ICDparam.stab = 20;

%Durations for redetection, VF is always 1s but VT_1 and Vt can
%be programmed between 1s-15s. Using nominal values, 1s for all zones.
ICDparam.VF_red_dur = 1000;
ICDparam.VT_red_dur = 1000;
ICDparam.VT_1red_dur = 1000;

%NEW: end of episode timers, these determine when an episode is over (they
%begin once the first therapy has been delivered OR when all three zones
%have become unsatisfied. 
%TODO: need to add something to the original initial discrimination for the
%case in which zones are satisfied and then become unsatisfied. 
ICDparam.EoE_timer_NT_dur = 10000;
ICDparam.EoE_timer_ATP_dur = 10000;

%NEW: Adding ATP time outs for for VT and VT_1
ICDparam.VT_ATP_TO = 30000;
ICDparam.VT_1_ATP_TO = 40000;

%Load the NSR template and generate the shock signal morphology template
load('EGM_NSR.mat')
NSR_temp = NSR_temp_build(EGM);
save('NSR_temp.mat', 'NSR_temp')
save('ICDparam.mat', 'ICDparam')
%%
%Diagnosis Stage: Taking an initial simulation and searching for Arrythmia 

%% Monitoring the phie file and extracting it as an ascii when updated 

% Define the file to monitor and the duration
phie_filePath = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/phie.igb';
monitorDuration = 200; 

% Define the Python executable and the script to call when the file is updated
pythonScript = '/home/k23086865/Projects/ICD_Online_24/phie_extract.py';

% Define the simulation folder and the name for the extracted phie traces
simFolder = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/';
phieName = 'phie_icd';

% Define the ICD_traces file, The atrial trace file and the name of EGM
% that you want to be monitored

PAT_file = '/home/k23086865/Projects/ICD_Online_24/NSR_75bpm_30s_PsuedoAtrial';
ICD_traces_file = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/phie_icd';
EGM_name = 'RVOT_Trace';

% Monitor the file and call the Python script if updated
[EGM, EGM_features, ICD_sense_state, ICD_sense_param, therapySigs, ICD_disc_state]= monitor_file_2(phie_filePath, monitorDuration, pythonExe, pythonScript, simFolder, phieName, PAT_file, ICD_traces_file, EGM_name )
%%
%Diagnosis Stage: Taking an initial simulation and searching for Arrythmia 

%% Monitoring the phie file and extracting it as an ascii when updated 

% Define the file to monitor and the duration
phie_filePath = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/phie.igb';
monitorDuration = 200; 

% Define the Python executable and the script to call when the file is updated
pythonScript = '/home/k23086865/Projects/ICD_Online_24/phie_extract.py';

% Define the simulation folder and the name for the extracted phie traces
simFolder = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/';
phieName = 'phie_icd';

% Define the ICD_traces file, The atrial trace file and the name of EGM
% that you want to be monitored

PAT_file = '/home/k23086865/Projects/ICD_Online_24/NSR_75bpm_30s_PsuedoAtrial';
ICD_traces_file = '/home/k23086865/Projects/ICD_Online_24/2024-08-06_BiV_coarser_focal_beats_RVOT_focal.vtx_320.0bcl_20.0pls_350uA_2ms/phie_icd';
EGM_name = 'RVOT_Trace';

% Monitor the file and call the Python script if updated
[EGM, EGM_features, ICD_sense_state, ICD_sense_param, therapySigs, ICD_disc_state]= monitor_file_2(phie_filePath, monitorDuration, pythonExe, pythonScript, simFolder, phieName, PAT_file, ICD_traces_file, EGM_name )
%%

%%