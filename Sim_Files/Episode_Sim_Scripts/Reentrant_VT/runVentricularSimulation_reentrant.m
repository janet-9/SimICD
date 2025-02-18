function [outputFile] = runVentricularSimulation_reentrant(Simscript, mesh, myocardium, scar_flag, scar_region, isthmus_region, conmul, input_state, model, tend, bcl, strength, duration, start, NSR_vtx, electrodes, output_res, check, nprocs, pythonExe)
    % runVentricularSimulation_reentrant Executes a Python script for ventricular stimulation simulation in the background.
    % The script includes all necessary arguments, runs in parallel (with --np), and captures the process ID (PID).
    
    % Save the current directory
    originalDir = pwd;
    disp(['Original directory: ', originalDir]);

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');
    cd(simDir);

    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
    outputFile = sprintf('%s_%s_INPUT_%s_conmul_%.2f', todayDateStr, mesh, input_state, conmul);

    % Save the output file name to a .mat file for later reference
    save('outputFileName.mat', 'outputFile');

    % Construct the command to run the Python script with necessary arguments
    cmd = sprintf('%s %s --np %d --mesh %s --myocardium %.2f --scar_flag %d --conmul %.2f --input_state %s --model %s --tend %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --NSR_vtx %s --electrodes %s --output_res %.2f --check %.2f', ...
                  pythonExe, Simscript, nprocs, mesh, myocardium, scar_flag, conmul, input_state, model, tend, bcl, strength, duration, start, NSR_vtx, electrodes, output_res, check);

    % Add optional scar and isthmus parameters if applicable
    if scar_flag == 1
        cmd = sprintf('%s --scar_region %.2f --isthmus_region %.2f', cmd, scar_region, isthmus_region);
    end

    % Run the command in the background and capture the PID
    cmd = [cmd, ' & echo $!'];  % Runs in background and prints PID

    % Display the constructed command for verification
    disp('Running cardiac simulation...:');
    %disp(cmd);

    % Execute the command and get the PID
    [~, ~] = system(cmd);

    % Change back to the original directory
    cd(originalDir);
end
