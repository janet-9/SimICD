function [outputFile, Redetect_param] = ATP_Burst_Therapy_reentrant(ATP_param, mesh, conmul, nprocs, pythonExe, full_sim_time, bcl, check, NSR_temp)
    % This function delivers a round of ATP therapy to the desired episode,
    % finding the input state from the initial episode simulation, and
    % outputs an EGM demonstrating that therapy has been delivered. It then
    % launches the redetection script from the end of therapy and monitors
    % the outcome
   
    
    % Define therapy script and parameters
    Therapy_script = 'ATP_Burst.py'; 
    input_state = ATP_param.input_state;
    tend = ATP_param.Sim_End;
    ATP_start = ATP_param.start;
    ATP_cl = ATP_param.cycle;
    ATP_pls = ATP_param.ATP_pls;
    ATP_Min_Cycle = ATP_param.ATP_Min_Cycle; 

    % Set names for the ATP EGM 
    EGM_name = strcat('EGM_ATP_', string(ATP_start));
    EGM_features_name = strcat('EGM_features_ATP_', string(ATP_start)) ;
  

    %Terminate background episode simulation
    killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
    [~, ~] = system(killCommand);  % Suppresses the output
    disp('Initial Episode Simulation Ended...');

    % Step 3: Run the ATP simulation
    disp('Launching ATP therapy...');
    outputFile = runATPSimulation(Therapy_script, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, ATP_pls, ATP_Min_Cycle, nprocs, pythonExe);
    disp(['Output file: ', outputFile]);

    % Step 4: Analyse the results of the ATP simulation
    disp('Analysing Therapy...');
    monitor_ATP_reentrant(outputFile, EGM_name, EGM_features_name, tend-ATP_start, NSR_temp);

    % Step 5: Find the final checkpoint for the ATP simulation
    roeFile = findFinalCheckpointATP_reentrant(outputFile);
    save(roeFile)

    % Step 6: Set parameters for post-therapy simulation

    Redetect_param.EGM_name_post_therapy = strcat('EGM_post_therapy_', string(roeFile)) ;
    Redetect_param.EGM_features_name_post_therapy = strcat('EGM_features_post_therapy_', string(roeFile)) ;
    Redetect_param.input_state = roeFile;
    Redetect_param.tend = ATP_param.Sim_End + full_sim_time;
    Redetect_param.pls = Redetect_param.tend/bcl;
    input_state_time = regexp(roeFile,  '\d+\.\d+', 'match'); 
    Redetect_param.Input_state_time = str2double(input_state_time{end}); 

    disp(Redetect_param);
    save('Redetect_Param.mat', 'Redetect_param');
   
end
