function main_reentrant(varargin)
% Full Function for simulating reentrant VT episodes and ICD diagnosis
% Optional parameters for varying the episode characteristics and therapy parameters are listed below

%% ----- Initialisation of the environment ----- %%

% Path Construction %
init_paths();

% Default Simulation Arguments %

args = SimArgParse_Reentrant(varargin{:});

% Default ICD Parameter Arguments %

argsICD = initialise_ICD();

% Results Folders %
todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
FolderName = sprintf('%s_Patient_Reentrant', char(todayDate));

% Output saving %
newFolderPath = fullfile('OUTPUT', FolderName);
% Check if the folder already exists and append a number if necessary (if multiple runs done in the same day)
folder_number = 1;
while exist(newFolderPath, 'dir')
    newFolderName = sprintf('%s_%d', FolderName, folder_number); % Append a number
    newFolderPath = fullfile('OUTPUT', newFolderName); % Update path
    folder_number = folder_number + 1;
end
% Create the new folder for the outputs
mkdir(newFolderPath);

% Save the passed parameters to the output folder for later inspection %
saveprintparams_reentrant(args, argsICD, newFolderPath);


% Initialise the log file to capture all command output during the simulation: 
logname = 'Simulation_log.txt';
diary(logname)

% Pause to allow environment and file path set up %
pause(2)


%% --- Initial Simulation Stage --- %%

% Define input arguments for simulation: python path executable, number of processors to use, the simulation script and the monitor duration


Simscript = 'Basic_BiV_Infarcted_VT_Episode.py';
nprocs = 28;
pythonExe = '/opt/anaconda3/bin/python'; %Change to your own python path if necesssary!
monitor_duration = 16200; %How long the ICD monitors the simulation (in seconds, alter if necessary

% Adjusting timings to account for the input state time
input_state_time = regexp(args.input_state, '\d+', 'match');
if ~isempty(input_state_time)
    % If start state time found, extract and use to calculate the full simulation time
    Input_state_time_init = str2double(input_state_time{end});
    full_sim_time = 30000 + Input_state_time_init; % 30 seconds per episode simulation
    tend = full_sim_time;  % Use calculated time for tend
else
    % If no state time found, 30 second simulation by default
    tend = 30000;  % 30 second simulation by default
end

% Call the function to run the simulation in the episode subfolder (background process)

[outputFile] = runVentricularSimulation_reentrant_NEW(Simscript, nprocs, pythonExe, tend, args);
disp(['Episode Output file: ', outputFile]);

% Pause to allow the simulation files to be generated
pause(5)


%% --- Initial Diagnosis Stage --- %%

[ICD_diagnosis, ~, ~] = monitor_initial_reentrant(monitor_duration, outputFile, args.EGM_name, args.EGM_features_name,  args.EGM_template, tend, pythonExe);

%% --- Therapy Progression Stage --- %%
% Note: The pathway defined here has an initial round of Burst. If arrhytmia continues, then
% further therapy is applied up to a pre-defined max. 
% If the Burst_only flag is set to 0, further therapy is set to be Ramp ATP
% If the Burst_only flag is set to 1, further therapy is Burst ATP 


% Therapy History Tracker Initialisation %
history = [0 0 0];

% Set Maximum Number of Therapy Calls for each zone %
VT1_max = args.max_therapy_calls(1);
VT_max = args.max_therapy_calls(2);
VF_max = args.max_therapy_calls(3);

% Load the Therapy Signals and the discrimination state from the initial diagnosis %
therapy_sig = ICD_diagnosis.therapySigs;
[VT1, VT, VF] = reachTh(therapy_sig);

% Follow through the therapy pathway until the VT is either terminated or therapy options are exhausted % 

while(true)

    % If the discrimination algorithm doesn't initiate therapy from the initial
    % episode then the therapy progression ends here.

    if ~VT1 && ~VT && ~VF %If the therapy counter for all of the zones is zero then no therapy is required - end the simulation process!
        disp('No Therapy Required!');
        % Sort and clean the output files 
        diary off
        output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)
        return;

        %Check to see if the max therapy calls have been made in any zones and
        %terminate the progression if they have.

    elseif VT1 >= VT1_max || VT >= VT_max || VF >= VF_max
        disp(ICD_diagnosis.therapySigs)
        disp('ATP Therapy Availability Threshold Exceeded - Shock Required!');

        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whoami) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');
        % Sort and clean the output files 
        diary off
        output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)
        return;

        % For the initial episode, if VF therapy required and no therapy has been
        % delivered in this zone, proceed with QC ATP.

    elseif VF && history(3) < 1 % QC therapy required - Follow therapy pathway for VF:

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

        %Calculate the Therapy Parameters and adjust for Quick Convert 
        ATP_param = calculate_therapy_parameters_reentrant(outputFile, ICD_diagnosis, Input_state_time, args.ATP_CL_QC, args.ATP_coupling_QC, args.ATP_pls_QC);
       
        % Run the ATP therapy simulation
        disp('Running QC ATP...')
        [~, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args);
        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect_reentrant(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, args.EGM_template, pythonExe);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;

        % Look at the ICD_diagnosis to see if therapy is required:
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VF episode terminated');
            % Sort and clean the output files
            diary off
            output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)
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
        ATP_param = calculate_therapy_parameters_reentrant(outputFile, ICD_diagnosis, Input_state_time, args.VT_ATP_CL, args.VT_ATP_coupling, args.VT_ATP_pls);
   

        % Run the ATP therapy simulation
        disp('Running VT ATP1...')
        [~, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args);
        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect_reentrant(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, args.EGM_template, pythonExe);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:

        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');
            % Sort and clean the output files
            diary off
            output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

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
        ATP_param = calculate_therapy_parameters_reentrant(outputFile, ICD_diagnosis, Input_state_time, args.VT_ATP_CL, args.VT_ATP_coupling, args.VT_ATP_pls);
   
        % Run the ATP therapy simulation
        if args.Burst_only == 1
            disp('Running VT ATP2 - BURST...')
            [~, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);
        else
            disp('Running VT ATP2 - RAMP...')
            [~, Redetect_param] = ATP_Ramp_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);
        end

        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args);
        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect_reentrant(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, args.EGM_template, pythonExe);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;


        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:

        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');
            diary off
            % Sort and clean the output files
            output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)
            
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
        ATP_param = calculate_therapy_parameters_reentrant(outputFile, ICD_diagnosis, Input_state_time, args.VT1_ATP_CL, args.VT1_ATP_coupling, args.VT1_ATP_pls);
      

        % Run the ATP therapy simulation
        disp('Running VT1 ATP1...')
        [~, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);
      
        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args);
        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect_reentrant(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, args.EGM_template, pythonExe);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;

        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:

        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);

        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');
            diary off
            % Sort and clean the output files
            output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

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
        ATP_param = calculate_therapy_parameters_reentrant(outputFile, ICD_diagnosis, Input_state_time, args.VT1_ATP_CL, args.VT1_ATP_coupling, args.VT1_ATP_pls);
      
        % Run the ATP therapy simulation
        if args.Burst_only == 1
            disp('Running VT1 ATP2 - BURST...')
            [~, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);
        else
            disp('Running VT1 ATP2 - RAMP...')
            [~, Redetect_param] = ATP_Ramp_Therapy_reentrant(ATP_param, nprocs, pythonExe, full_sim_time, args);
        end
        %Set parameters for the redetection simulation
        input_state = Redetect_param.input_state;
        tend = Redetect_param.tend;

        % Run the redetection simulation to check for episode termination
        [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args);

        % Display the output file name and the process ID
        disp('Post ATP Episode simulation running...');
        disp(['Output file: ', outputFile]);

        %Set the parameters for running redetection monitoring

        EGM_name_post_therapy = Redetect_param.EGM_name_post_therapy;
        EGM_features_name_post_therapy = Redetect_param.EGM_features_name_post_therapy;
        Input_state_time = Redetect_param.Input_state_time;

        % Run the redetection monitoring function on the post-therapy
        % simulation
        [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect_reentrant(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs, Input_state_time, args.EGM_template, pythonExe);
        % ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;


        % Diagnosis and Therapy: Look at the ICD_diagnosis to see if therapy is required:
        therapy_sig = ICD_diagnosis.therapySigs;
        [VT1, VT, VF] = reachTh(therapy_sig);
        if isequal(therapy_sig, prev_therapySigs) %If the therapy counter has not changed, then the therapy was successful.
            disp('Therapy Successful- VT episode terminated');
            % Sort and clean the output files
            diary off
            output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

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



    elseif VF >= 1 && history(3) >= VF_max % QC therapy already applied:
        disp('VF Called: Available Therapies Unsuccessful - Shock Required!')
        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whoami) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');
        % Sort and clean the output files
        diary off
        output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

        return;

    elseif VT >= 1 && history(2) >= VT_max % Available rounds of ATP already delivered:
        disp('VT Called: Available Therapies Unsuccessful - Shock Required!')
        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whoami) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');

        % Sort and clean the output files
        diary off
        output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)
        return;

    elseif VT1 >= 1 && history(1) >= VT1_max % Available rounds of ATP already delivered:
        disp('VT1 Called: Available Therapies Unsuccessful - Shock Required!')
        %Terminate background episode simulation
        killCommand = sprintf('pkill -u $(whoami) "openCARP" > /dev/null 2>&1 ');
        [~, ~] = system(killCommand);  % Suppresses the output
        disp('Initial Episode Simulation Ended...');
        % Sort and clean the output files
        diary off
        output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

        return;
    end


    %% File clean up and saving the outputs.

    
    % Sort and clean the output files
    diary off
    output_clean(newFolderPath, args.EGM_name, args.EGM_features_name, 'Reentrant_VT', todayDate)

end