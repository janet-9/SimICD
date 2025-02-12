function [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration)
    % runVentricularSimulation Executes a Python script for ventricular stimulation simulation.
    %   [outputFile] = runVentricularSimulation(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe)
    %   runs the specified Python script with the given parameters and returns the generated output file name and the process ID (PID).

    % Save the current directory
     originalDir = pwd;

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT');
    cd(simDir);


    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
    
    outputFile = sprintf('%s_%s_Focal_VT_%s_%.2f_episodes_%.2f_focal_bcl_%.2f_focal_pls_%.2f_focal_strength_%.2f_focal_duration', todayDateStr, input_state, ectopic, episodes, focal_bcl, focal_pls, focal_strength, focal_duration);
   
    % Save the filename to a .mat file for later use
    save('outputFileName.mat', 'outputFile');

    % Construct the command to run the Python script with the given arguments
    cmd = sprintf('%s %s --np %d --mesh %s --conmul %.2f --input_state %s --model %s --tend %.2f --pls %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --output_res %.2f --check %.2f --ectopic %s --focal_start %.2f --episodes %.2f --episode_interval %.2f --focal_pls %.2f --focal_bcl %.2f --focal_strength %.2f --focal_duration %.2f & echo $!', ...
                  pythonExe, Simscript, nprocs, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration);

    % Display the command to ensure it's correctly constructed
    disp('Running cardiac simulation...');
    %disp(cmd);

    % Run the Python script in the background and capture the PID
    [~, ~] = system(cmd);
    % pid = str2double(cmdout);

    % Check for errors
    % if isnan(pid)
    %     % Change back to the original directory before throwing an error
    %     cd(originalDir);
    %     error('Failed to retrieve the PID for the background Python process.');
    % end

    % Save the PID to a .mat file for later use
    % save('backgroundProcessPID.mat', 'pid');

    % Change back to the original directory
     cd(originalDir);
end