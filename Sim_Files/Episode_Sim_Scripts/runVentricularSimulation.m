function [outputFile] = runVentricularSimulation(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe)
    % runVentricularSimulation Executes a Python script for ventricular stimulation simulation.
    %   [outputFile, pid] = runVentricularSimulation(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe)
    %   runs the specified Python script with the given parameters and returns the generated output file name and the process ID (PID).

    % Save the current directory
    originalDir = pwd;
    disp(originalDir);

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');
    %disp(simDir);
    cd(simDir);

    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
    outputFile = sprintf('%s_%s_INPUT_%s_conmul_%.2f', todayDateStr, mesh, input_state, conmul);

    % Save the filename to a .mat file for later use
    save('outputFileName.mat', 'outputFile');

    % Construct the command to run the Python script with the given arguments
    cmd = sprintf('%s %s --np %d --mesh %s --conmul %.2f --input_state %s --model %s --tend %.2f --pls %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --output_res %.2f --check %.2f & echo $!', ...
                  pythonExe, Simscript, nprocs, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check);

    % Display the command to ensure it's correctly constructed
    disp('Running cardiac simulation...');
    %disp(cmd);

    % Run the Python script in the background and capture the PID
    [~, cmdout] = system(cmd);
    pid = str2double(cmdout);

    % % Check for errors
    % if isnan(pid)
    %     % Change back to the original directory before throwing an error
    %     cd(originalDir);
    %     error('Failed to retrieve the PID for the background Python process.');
    % end

    % Save the PID to a .mat file for later use
    save('backgroundProcessPID.mat', 'pid');

    % Change back to the original directory
    cd(originalDir);
end
