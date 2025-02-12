function Patient_1(ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, EGM_name, EGM_features_name, ATP_CL, ATP_coupling, ATP_pls, ATP_dec, ATP_Min_Cycle)

    % Function for simulating cardiac episodes and ICD diagnosis
    % Default values for optional parameters
    if nargin < 15, ATP_Min_Cycle = 220.00; end
    if nargin < 14, ATP_dec = 10.00; end
    if nargin < 13, ATP_pls = 8.00; end
    if nargin < 12, ATP_coupling = 0.81; end
    if nargin < 11, ATP_CL = 0.81; end
    if nargin < 10, EGM_features_name = 'EGM_features_focal_VT'; end
    if nargin < 9, EGM_name = 'EGM_focal_VT'; end
    if nargin < 8, focal_duration = 4; end
    if nargin < 7, focal_strength = 450; end
    if nargin < 6, focal_bcl = 300; end
    if nargin < 5, focal_pls = 12; end
    if nargin < 4, episode_interval = 1000; end
    if nargin < 3, episodes = 3; end
    if nargin < 2, focal_start = 3800; end
    if nargin < 1, ectopic = 'RVOT_focal.vtx'; end


%Initialisation of the environment

%Set Up the relevant paths:
init_paths();

%Initialize the parameters of the ICD - default is the nominal set of
%Boston Scientific device parameters: 
ICDparam = initialise_ICD();

%Provide the type of NSR template you want for the simulation
NSR_temp ='EGM_NSR';

%Set up the output folders to save the EGM results:
todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
FolderName = sprintf('%s_Patient_1', char(todayDate));

% Construct the full path
newFolderPath = fullfile('OUTPUT', FolderName);

% Check if the folder already exists and append a number if necessary (if
% multiple runs done in the same day)
folder_number = 1;
while exist(newFolderPath, 'dir')
    newFolderName = sprintf('%s_%d', FolderName, folder_number); % Append a number
    newFolderPath = fullfile('OUTPUT', newFolderName); % Update path
    folder_number = folder_number + 1;
end

% Create the new folder for the outputs 
mkdir(newFolderPath);


pause(1)


%Simulation Stage and Diagnosis Stage: Chose the type of cardiac episode to simulate and
%execute it as a background process which can be monitored by the icd -
%will return the diagnosis of the measured signals

% Define input arguments for simulation

% Default Parameters for underlying NSR and execution of the simulation:
model = 'tenTusscherPanfilov';
bcl = 800; % NSR bcl, corresponds to 75bpm 
strength = 450;
duration = 4;
start = 0;
output_res = 1;
check = 1000; %Saves a simulation checkpoint state every 1 second
nprocs = 28;
pythonExe = '/opt/anaconda3/bin/python';


% Focal Episode Parameters 
Simscript = 'Basic_BiV_Ectopic_Beats.py'; %Choose the simulation type: NSR, Focal or Infarcted Reentrant
mesh = 'ventricles_coarser'; %Choose the type of mesh, normal structure or the left/right ventricle infarction
conmul = 1.00; %Adjust to vary the cycle length of the reentrant circuit (infarcte mesh) or the general conductivity of the non-infarcted mesh
input_state = '1_NSR_input_3200.roe'; %Choose in the input state, top/bottom reentrant for the infarcted meshes
monitor_duration = 16200; %How long the ICD monitors the simulation (in seconds)

%Pre-loading some of the therapy parameters
input_state_time = regexp(input_state, '\d+', 'match');
Input_state_time_init = str2double(input_state_time{end}); %This should be the time of the input_state
full_sim_time = 30000 + Input_state_time_init; % 30 seconds per episode simulation 
tend = full_sim_time;
pls = tend/bcl;


% Call the function to run the simulation in the specified subfolder in the background
[outputFile] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

% Display the output file name
%disp('Episode simulation running...');
disp(['Output file: ', outputFile]);


pause(10)


% Diagnosis Stage: Taking an initial simulation and searching for an
% arrythmia that requires therapy - this part breaks when therapy is
% required OR the 30 second episode ens without the need for therapy, 
% and returns the necessary therapy parameters. 

[ICD_diagnosis, EGM, EGM_features, ICD_sense_state, ICD_sense_param] = monitor_initial_focal(monitor_duration, outputFile, EGM_name, EGM_features_name, NSR_temp, tend);

% Therapy Stage: Determine the required therapy, calculating the output therapy parameters and extracting
% the required checkpoint start
% Look at the ICD_diagnosis to see if therapy is required - Then follow the
% necessary therapy pathway - which is set by tracking to therapy zones:


%Therapy History Tracker Initialisation:
%History = [ VT1_H, VT_H, VF_H]
history = [0 0 0];
VT1_H = history(1);
VT_H = history(2);
VF_H = history(3);

%Set Maximum Number of Therapy Calls for each Zone 
max_therapy_calls = [3 3 2];
VT1_max = max_therapy_calls(1);
VT_max = max_therapy_calls(2);
VF_max = max_therapy_calls(3);

%Load the Therapy Signals and the discrimination state from the initial diagnosis
therapy_sig = ICD_diagnosis.therapySigs;
[VT1, VT, VF] = reachTh(therapy_sig);
ICD_disc_state = ICD_diagnosis.ICD_disc_state;

while(true)

    %This check is only used in the initial diagnosis, if the
    %discrimination algorithm doesn't initiate therapy from the initial
    %episode then the therapy progression ends here.
    if ~VT1 && ~VT && ~VF %If the therapy counter for all of the zones is zero then no therapy is required - end the simulation process!
        disp('No Therapy Required!');
        return;

    %Check to see if the max therapy calls have been made in any zones and
    %terminate if they have. 
    elseif VT1 >= VT1_max || VT >= VT_max || VF >= VF_max
        disp(ICD_diagnosis.therapySigs)
        disp('ATP Therapy Availability Threshold Exceeded - Shock Required!');

        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whomai) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');

        return;
    

         %% TO-DO: Sort the therapy delivery and redetection for the VF zone!!
        % For the initial episode, if VF therapy required and no therapy has been
        % delivered in this zone, proceed with QC ATP.

    elseif VF && history(3) < 1 %QC therapy required - Follow therapy pathway for VF:

        %Set the parameters for QC therapy
        ATP_CL_QC = 0.88; % Nominal value for the BSc device
        ATP_coupling_QC = 0.88; % Nominal value for the BSc device
        ATP_pls_QC = 8;

       %Save the previous therapy signals for later comparison
        prev_therapySigs = ICD_diagnosis.therapySigs;
        save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(3) = history(3) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
            Input_state_time = ICD_diagnosis.last_beat_time;
        end


         %Calculate the Therapy Parameters
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL_QC, ATP_coupling_QC, ATP_pls_QC);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;

        % Run the ATP therapy simulation
         disp('Running QC ATP...')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check);
        
        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;
        pls = Redetect_param.pls;

        % Run the redetection simulation to check for episode termination
        [outputFile,~] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, NSR_temp);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;
       
        % Look at the ICD_diagnosis to see if therapy is required:
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VF episode terminated');
            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            disp(['VF Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            disp(['VT1 Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
           disp(['VT Detected. Therapy History Counter Updated: ', num2str(therapy_sig)])
            continue;
        end


        % From the initial episode, VT therapy required from the diagnosis and
        % no previous therapies have been required in that zone, so ATP therapy
        % is delivered.
    elseif VT && history(2) < 2 % VT ATP_1 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = ICD_diagnosis.therapySigs;
        save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
           Input_state_time = ICD_diagnosis.last_beat_time;
        end

        %Calculate the Therapy Parameters
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, ATP_pls);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;

        % Run the ATP therapy simulation
        disp('Running VT ATP1 - Burst')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check);
        
        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;
        pls = Redetect_param.pls;

        % Run the redetection simulation to check for episode termination
        [outputFile,~] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, NSR_temp);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;
       
        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');

            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT >= 1 && history(2) >= 2 % VT ATP_2 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = ICD_diagnosis.therapySigs;
        save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
            Input_state_time = ICD_diagnosis.last_beat_time;
        end


        %Calculate the Therapy Parameters
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, ATP_pls);
        ATP_param.ATP_dec = ATP_dec;
        ATP_param.Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_pls = ATP_pls;

        % Run the ATP therapy simulation 
        disp('Running VT ATP2 - Ramp')

        [~, Redetect_param] = ATP_Ramp_Therapy_Focal(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;
        pls = Redetect_param.pls;

        % Run the redetection simulation to check for episode termination
        [outputFile,~] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);


        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, NSR_temp);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;


        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');

            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT1 && history(1) < 2 % VT_1 ATP_1 therapy required

         %Save the previous therapy signals for later comparison
        prev_therapySigs = ICD_diagnosis.therapySigs;
        save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
            Input_state_time = ICD_diagnosis.last_beat_time;
        end


        %Calculate the Therapy Parameters
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, ATP_pls);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;

        % Run the ATP therapy simulation
         disp('Running VT1 ATP1 - Burst')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;
        pls = Redetect_param.pls;

         % Run the redetection simulation to check for episode termination
        [outputFile, ~] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, NSR_temp);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');

            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        end

    elseif VT1 >= 1 && history(1) >= 2 % VT_1 ATP_2 therapy required

        %Save the previous therapy signals for later comparison
        prev_therapySigs = ICD_diagnosis.therapySigs;
        save("Prev_TherapySigs.mat", "prev_therapySigs");
        if prev_therapySigs(1) + prev_therapySigs(2) + prev_therapySigs(3) <= 1 % If you are providing therapy for the first time - include the input state offset for start time calculations
            Input_state_time = Input_state_time_init + ICD_diagnosis.last_beat_time;
            %Update the history call BEFORE delivering therapy 
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
        else %If you have already done a therapy simulation, the input state offset is already accounted for.
            Input_state_time = ICD_diagnosis.last_beat_time;
        end


        %Calculate the Therapy Parameters
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, ATP_pls);
        ATP_param.ATP_dec = ATP_dec;
        ATP_param.Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_pls = ATP_pls;


        % Run the ATP therapy simulation
        disp('Running VT1 ATP2 - Ramp')
        [~, Redetect_param] = ATP_Ramp_Therapy_Focal(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;
        pls = Redetect_param.pls;

         % Run the redetection simulation to check for episode termination
        [outputFile,~] = runVentricularSimulation_ectopic(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, NSR_temp);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;


        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);
        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');

            return;
        elseif therapy_sig(3) > prev_therapySigs(3) % Therapy required in VF zone - change to VF therapy pathway
            history(3) = history(3) +1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(1) > prev_therapySigs(1) %Therapy required in VT_1 zone - change to VT_1 therapy pathway
            history(1) = history(1) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        elseif therapy_sig(2) > prev_therapySigs(2) %Therapy required in VT zone - change to VT therapy pathway
            history(2) = history(2) + 1;
            disp(['Therapy History Counter Updated: ', num2str(history)])
            save('Therapy_History.mat', "history")
            continue;
        end



    elseif VF >= 1 && history(3) >= 2 %QC therapy already applied:
        disp('VF Called: Available Therapies Unsuccessful - Shock Required!')
        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whomai) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');

        return;

    elseif VT >= 1 && history(2) >= 3 %Both rounds of ATP already delivered:
        disp('VT Called: Available Therapies Unsuccessful - Shock Required!')
         %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whomai) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');

        return;

    elseif VT1 >= 1 && history(1) >= 3 %Both rounds of ATP already delivered:
        disp('VT1 Called: Available Therapies Unsuccessful - Shock Required!')
        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whomai) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');

        return;
    end


    %File clean up and saving the outputs.

    % Move the EGM results
    currentDir = pwd;
    targetDir = newFolderPath; % Output Folder this this patient test

    % Define the filename pattern (e.g., all .txt files or specific names)
    tracefiles = dir(fullfile(currentDir, [EGM_name, '*']));
    featurefiles = dir(fullfile(currentDir, [EGM_features_name, '*']));

    % Get a list of matching files
    allfiles = [tracefiles; featurefiles];

    % Loop through each matching file and move it to the target directory
    for i = 1:length(allfiles)
        oldPath = fullfile(currentDir,allfiles(i).name);
        newPath = fullfile(targetDir, allfiles(i).name);

        % Move the file
        movefile(oldPath, newPath);
    end


     %2: Clear the trc files and petsc folders from the simulation script
    trcfiles = dir(fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', ['*','.trc']));
    chkptfiles = dir(fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', ['*', '.roe']));
    petscfolders = dir(fullfile(currentDir, ['*', 'petsc', '*']));

    for i = 1:length(trcfiles)
        filePath = fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', trcfiles(i).name);
        delete(filePath);
    end

    for i = 1:length(chkptfiles)
        filePath = fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', chkptfiles(i).name);
        delete(filePath);
    end

    for i = 1:length(petscfolders)
        filePath = fullfile(currentDir, petscfolders(i).name);
        rmdir(filePath);
    end




end 