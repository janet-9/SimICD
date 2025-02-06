function [outputFile, ICD_diagnosis, pid] = ATP_Ramp(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, mesh, conmul, nprocs, pythonExe, Simscript, full_sim_time, bcl, strength, duration, start, output_res, check, monitor_duration)

    % Step 1: Set the parameters for QC therapy
    ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling);
    
    % Save the previous therapy signals for later comparison
    prev_therapySigs = ICD_diagnosis.therapySigs;
    save("Prev_TherapySigs.mat", "prev_therapySigs");

    % Define therapy script and parameters
    Therapy_script = 'ATP_Ramp.py'; 
    input_state = ATP_param.input_state;
    tend = ATP_param.Sim_End;
    ATP_start = ATP_param.start;
    ATP_cl = ATP_param.cycle;

    % Set names for EGM and post-therapy files
    EGM_name = strcat('EGM_ATP_', string(ATP_start));
    EGM_features_name = strcat('EGM_features_ATP_', string(ATP_start)) ;
    EGM_name_post_therapy = strcat('EGM_post_therapy', string(ATP_start)) ;
    EGM_features_name_post_therapy = strcat('EGM_features_post_therapy', string(ATP_start)) ;
    
    % Step 2: Terminate background episode simulation
    killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1');
    system(killCommand);
    disp('Initial Episode Simulation Ended...');

    % Step 3: Run the ATP simulation
    disp('Launching ATP therapy...');
    outputFile = runATPSimulation(Therapy_script, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, nprocs, pythonExe);
    disp(['Output file: ', outputFile]);

    % Step 4: Analyse the results of the ATP simulation
    disp('Analysing Therapy...');
    monitor_ATP(outputFile, EGM_name, EGM_features_name, tend-ATP_start);

    % Step 5: Find the final checkpoint for the ATP simulation
    roeFile = findFinalCheckpointATP(outputFile);

    % Step 6: Set parameters for post-therapy simulation
    input_state = roeFile;
    tend = ATP_param.Sim_End + full_sim_time;
    pls = tend / bcl;

    % Step 7: Run the post-therapy simulation
    [outputFile, pid] = runVentricularSimulation(Simscript, mesh, conmul, input_state, 'tenTusscherPanfilov', tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe);

    % Display the output file name and the process ID
    disp('Post ATP Episode simulation running...');
    disp(['Output file: ', outputFile]);

    % Step 8: Re-Detection Diagnosis Stage - Update the last_beat_time
    % according to the start time of the simulation. 
    [ICD_diagnosis, ~, ~, ~, ~] = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs);

    ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + Input_state_time;

end
