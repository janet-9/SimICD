function Focal_VT_Patient(varargin)
% Full Function for simulating focal VT episodes and ICD diagnosis
% Optional parameters for varying the episode characteristics and therapy parameters are listed below

% Define default values for all variable parameters
defaults = { ...
    'stim_sites/Focal_Site.vtx', ...   % focal beat location
    0, ...                  % time for the start of the focal beats
    1, ...                  % number of focal episodes
    1000, ...               % interval between episodes
    10, ...                 % number of focal pulses
    300, ...                % pulse interval for focal pulses
    450, ...                % strength of focal pulses
    4, ...                  % duration of focal pulses
    'EGM_focal_VT', ...     % Name for the EGM
    'EGM_features_focal_VT', ... % name for the EGM features
    0.81, ...               % ATP Cycle Length
    0.81, ...               % ATP Coupling Interval
    8.00, ...               % ATP Pulses
    10.00, ...              % ATP Cycle Length Decrement
    220.00, ...             % ATP Min Cycle Length
    'meshes/meshname', ...         % mesh
    1, ...                  % myocardium region tag
    1, ...                  % scar_flag
    2, ...                  % scar_region tag
    3, ...                  % isthmus_region tag
    1.0, ...                % conmul
    'input_states/input_1000.roe', ...   % input_state
    'tenTusscherPanfilov', ... % cell model
    800, ...                % bcl for NSR
    450, ...                % strength for NSR
    4, ...                  % duration for NSR
    0, ...                  % start for NSR
    'NSR_temps/EGM_NSR', ...          % Template for NSR trace
    'stim_sites/NSR.vtx', ...          % NSR_vtx
    'electrodes/electrodesICD.pts', ...   % electrodes points file
    1, ...                  % output resolution
    1000, ...               % checkpoint
    450, ...                % ATP_strength
    4, ...                  % ATP_duration
    'stim_sites/ATP.vtx', ...          % ATP_stimsite
    [3 3 2], ...            % Max number of therapy calls
    };

% Number of expected arguments
numArgs = length(defaults);

% Overwrite defaults with user-provided values
for i = 1:min(nargin, numArgs)
    defaults{i} = varargin{i};
end

% Assign values from defaults array
[ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, ...
    focal_strength, focal_duration, EGM_name, EGM_features_name, ATP_CL, ...
    ATP_coupling, ATP_pls, ATP_dec, ATP_Min_Cycle, mesh, myocardium, scar_flag, ...
    scar_region, isthmus_region, conmul, input_state, model, bcl, strength, ...
    duration, start, NSR_vtx, electrodes, output_res, check, ATP_strength, ATP_duration, ATP_stimsite] = defaults{:};

% Print out the default parameters to the user in a concise format

disp('Default Parameter Values:');
fprintf('\n');
fprintf('--- Focal VT Episode Information ---\n');
fprintf('Focal Beat Location (VTX): %s\n', ectopic);
fprintf('Start Time for Focal Beats: %.2f\n', focal_start);
fprintf('Number of Focal Episodes: %.2f\n', episodes);
fprintf('Interval Between Episodes: %.2f ms\n', episode_interval);
fprintf('Number of Focal Pulses: %.2f\n', focal_pls);
fprintf('Pulse Interval for Focal Pulses: %.2f ms\n', focal_bcl);
fprintf('Strength of Focal Pulses: %.2f\n', focal_strength);
fprintf('Duration of Focal Pulses: %.2f ms\n', focal_duration);

fprintf('\n');
fprintf('--- EGM Information ---\n');
fprintf('EGM Name: %s\n', EGM_name);
fprintf('EGM Features Name: %s\n', EGM_features_name);

fprintf('\n');
fprintf('--- ATP Therapy Parameters ---\n');
fprintf('ATP Cycle Length: %.2f\n', ATP_CL);
fprintf('ATP Coupling Interval: %.2f\n', ATP_coupling);
fprintf('ATP Pulses: %.2f\n', ATP_pls);
fprintf('ATP Cycle Length Decrement: %.2f\n', ATP_dec);
fprintf('ATP Min Cycle Length: %.2f\n', ATP_Min_Cycle);

fprintf('\n');
fprintf('--- Mesh and Region Information ---\n');
fprintf('Mesh Name: %s\n', mesh);
fprintf('Myocardium Region Tag: %.2f\n', myocardium);
fprintf('Scar Flag: %.2f\n', scar_flag);
fprintf('Scar Region Tag: %.2f\n', scar_region);
fprintf('Isthmus Region Tag: %.2f\n', isthmus_region);

fprintf('\n');
fprintf('--- Additional Parameters ---\n');
fprintf('Conmul: %.2f\n', conmul);
fprintf('Input State: %s\n', input_state);
fprintf('Cell Model: %s\n', model);
fprintf('BCL for NSR: %.2f\n', bcl);
fprintf('Strength for NSR: %.2f\n', strength);
fprintf('Duration for NSR: %.2f\n', duration);
fprintf('Start for NSR: %.2f\n', start);
fprintf('NSR Template: %s\n', NSR_vtx);
fprintf('NSR VTX: %s\n', NSR_vtx);
fprintf('Electrodes Points File: %s\n', electrodes);
fprintf('Output Resolution: %.2f\n', output_res);
fprintf('Checkpoint: %.2f\n', check);
fprintf('ATP Strength: %.2f\n', ATP_strength);
fprintf('ATP Duration: %.2f\n', ATP_duration);
fprintf('ATP Stimsite: %s\n', ATP_stimsite);

fprintf('\n');
fprintf('--- Therapy Call Limits ---\n');
fprintf('Max Therapy Calls: %s\n', mat2str([3 3 2]));


%% Initialisation of the environment

%Set Up the relevant paths:
init_paths();

%Initialize the parameters of the ICD - default is the nominal set of
%Boston Scientific device parameters:
initialise_ICD();

%Set up the output folders to save the EGM results:
todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
FolderName = sprintf('%s_Patient_Focal', char(todayDate));

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

% pause to allow folders to be generated
pause(1)


%% Simulation Stage and Diagnosis Stage:

% Define input arguments for simulation: python path executable, number of
% processors to use, the simulation script and the monitor duration
Simscript = 'Basic_BiV_Focal_Beats.py';
nprocs = 28;
pythonExe = '/opt/anaconda3/bin/python'; %Change to your own python path!
monitor_duration = 16200; %How long the ICD monitors the simulation (in seconds)

% Adjusting timings to account for the input state time
input_state_time = regexp(input_state, '\d+', 'match');
if ~isempty(input_state_time)
    % If start state time found, extract and use to calculate the full simulation time
    Input_state_time_init = str2double(input_state_time{end});
    full_sim_time = 30000 + Input_state_time_init; % 30 seconds per episode simulation
    tend = full_sim_time;  % Use calculated time for tend
else
    % If no state time found, 30 second simulation by default
    tend = 30000;  % 30 second simulation by default
end


% Call the function to run the simulation in the specified subfolder in the background

[outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);
disp(['Output file: ', outputFile]);

% Puase to allow files to be created
pause(5)


%% Diagnosis Stage:

[ICD_diagnosis, ~, ~, ~, ~] = monitor_initial_focal(monitor_duration, outputFile, EGM_name, EGM_features_name, NSR_temp, tend);

%% Therapy Stage:

%Therapy History Tracker Initialisation:
history = [0 0 0];

%Set Maximum Number of Therapy Calls for each Zone
VT1_max = max_therapy_calls(1);
VT_max = max_therapy_calls(2);
VF_max = max_therapy_calls(3);

%Load the Therapy Signals and the discrimination state from the initial diagnosis
therapy_sig = ICD_diagnosis.therapySigs;
[VT1, VT, VF] = reachTh(therapy_sig);

while(true)

    % If the discrimination algorithm doesn't initiate therapy from the initial
    % episode then the therapy progression ends here.
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

        % For the initial episode, if VF therapy required and no therapy has been
        % delivered in this zone, proceed with QC ATP.

    elseif VF && history(3) < 1 %QC therapy required - Follow therapy pathway for VF:

        %Set the parameters for QC therapy - non-programmable
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
        ATP_param.ATP_strength = ATP_strength;
        ATP_param.ATP_duration = ATP_duration;
        ATP_param.ATP_stimsite = ATP_stimsite;

        % Run the ATP therapy simulation
        disp('Running QC ATP...')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, nprocs, pythonExe, full_sim_time, bcl, check, model, strength, duration, start, NSR_vtx, electrodes, output_res);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);

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
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL_QC, ATP_coupling_QC, ATP_pls_QC);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_strength = ATP_strength;
        ATP_param.ATP_duration = ATP_duration;
        ATP_param.ATP_stimsite = ATP_stimsite;

        % Run the ATP therapy simulation
        disp('Running VT ATP1...')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, nprocs, pythonExe, full_sim_time, bcl, check, model, strength, duration, start, NSR_vtx, electrodes, output_res);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);

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
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL_QC, ATP_coupling_QC, ATP_pls_QC);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_strength = ATP_strength;
        ATP_param.ATP_duration = ATP_duration;
        ATP_param.ATP_stimsite = ATP_stimsite;
        ATP_param.ATP_dec = ATP_dec;


        % Run the ATP therapy simulation
        disp('Running VT ATP2 - RAMP...')
        [~, Redetect_param] = ATP_Ramp_Therapy_Focal(ATP_param, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, nprocs, pythonExe, full_sim_time, bcl, check, model, strength, duration, start, NSR_vtx, electrodes, output_res);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);

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
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL_QC, ATP_coupling_QC, ATP_pls_QC);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_strength = ATP_strength;
        ATP_param.ATP_duration = ATP_duration;
        ATP_param.ATP_stimsite = ATP_stimsite;

        % Run the ATP therapy simulation
        disp('Running VT1 ATP1...')
        [~, Redetect_param] = ATP_Burst_Therapy_Focal(ATP_param, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, nprocs, pythonExe, full_sim_time, bcl, check, model, strength, duration, start, NSR_vtx, electrodes, output_res);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);

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
        ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL_QC, ATP_coupling_QC, ATP_pls_QC);
        ATP_param.ATP_pls = ATP_pls;
        ATP_param.ATP_Min_Cycle = ATP_Min_Cycle;
        ATP_param.ATP_strength = ATP_strength;
        ATP_param.ATP_duration = ATP_duration;
        ATP_param.ATP_stimsite = ATP_stimsite;
        ATP_param.ATP_dec = ATP_dec;

        % Run the ATP therapy simulation
        disp('Running VT1 ATP2 - RAMP...')
        [~, Redetect_param] = ATP_Ramp_Therapy_Focal(ATP_param, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, nprocs, pythonExe, full_sim_time, bcl, check, model, strength, duration, start, NSR_vtx, electrodes, output_res);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration, myocardium, scar_flag, scar_region, isthmus_region, NSR_vtx, electrodes, focal_site);

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


    %% File clean up and saving the outputs.

    % Move the EGM results
    currentDir = pwd;
    targetDir = newFolderPath; % Output Folder this this patient test

    % Define the filename pattern (e.g., all .txt files or specific names)
    tracefiles = dir(fullfile(currentDir, [EGM_name, '*']));
    featurefiles = dir(fullfile(currentDir, [EGM_features_name, '*']));
    simfiles = dir(fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', [todayDate,'*']));

    % Get a list of matching files
    allfiles = [tracefiles; featurefiles; simfiles];

    % Loop through each matching file and move it to the target directory
    for i = 1:length(allfiles)
        oldPath = fullfile(currentDir,allfiles(i).name);
        newPath = fullfile(targetDir, allfiles(i).name);
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