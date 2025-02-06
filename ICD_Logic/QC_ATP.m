function [outputFile, ICD_diagnosis, pid] = QC_ATP(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling, mesh, conmul, nprocs, pythonExe, Simscript, full_sim_time, bcl, strength, duration, start, output_res, check, monitor_duration)

    % Step 1: Set the parameters for QC therapy
    QC_ATP_param = calculate_therapy_parameters(outputFile, ICD_diagnosis, Input_state_time, ATP_CL, ATP_coupling);
    
    % Define therapy script and parameters
    Therapy_script = 'ATP_Burst.py'; 
    input_state = QC_ATP_param.input_state;
    tend = QC_ATP_param.Sim_End;
    ATP_start = QC_ATP_param.start;
    ATP_cl = QC_ATP_param.cycle;

    % Set names for EGM and post-therapy files
    EGM_name = 'EGM_QC_ATP';
    EGM_features_name = 'EGM_features_QC_ATP';
    EGM_name_post_therapy = 'EGM_post_therapy_QC';
    EGM_features_name_post_therapy = 'EGM_features_post_therapy_QC';

    % Step 2: Terminate background episode simulation
    killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
    system(killCommand);
    disp('Initial Episode Simulation Ended...');

    % Step 3: Run the ATP simulation
    disp('Launching Quick Convert ATP therapy...');
    outputFile = runATPSimulation(Therapy_script, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, nprocs, pythonExe);
    disp(['Output file: ', outputFile]);

    % Step 4: Analyse the results of the ATP simulation
    disp('Analysing QC Therapy...');
    monitor_ATP(outputFile, EGM_name, EGM_features_name, tend-ATP_start);

    % Step 5: Find the final checkpoint for the ATP simulation
    roeFile = findFinalCheckpointATP(outputFile);

    % Step 6: Set parameters for post-therapy simulation
    input_state = roeFile;
    tend = QC_ATP_param.Sim_End + full_sim_time;
    pls = tend / bcl;

    % Step 7: Run the post-therapy simulation
    [outputFile, pid] = runVentricularSimulation(Simscript, mesh, conmul, input_state, 'tenTusscherPanfilov', tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe);

    % Display the output file name and the process ID
    disp('Post ATP Episode simulation running...');
    disp(['Output file: ', outputFile]);

    % Step 8: Re-Detection Diagnosis Stage
    ICD_diagnosis = monitor_redetect(monitor_duration, outputFile, EGM_name_post_therapy, EGM_features_name_post_therapy, prev_therapySigs);

end
