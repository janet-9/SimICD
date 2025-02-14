function outputFile = runATPSimulation_reentrant(Simscript, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, ATP_pls, ATP_Min_Cycle, nprocs, pythonExe)
    % runATPSimulation Executes a Python script for ATP therapy simulation.
    %   outputFile = runATPSimulation(Simscript, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, nprocs, pythonExe)
    %   runs the specified Python script with the given parameters and returns the generated output file name.

   % Save the current directory
    originalDir = pwd;

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');
    cd(simDir);
    
    % Extract just the filename from the input_state path
    [~, inputFilename, ext] = fileparts(input_state);
    inputFilename = strcat(inputFilename, ext); % Recombine filename and extension

    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
   
    outputFile = sprintf('%s_ATP_APP_INPUT_%s_%.2f_atpbcl_%.2f_atpstart_%.2f_atppls', ...
                         todayDateStr, inputFilename, ATP_cl, ATP_start, ATP_pls);

    % Save the filename to a .mat file for later use
    save('outputFileName_ATP.mat', 'outputFile');

    % Construct the command to run the Python script with the given arguments
    cmd = sprintf('"%s" "%s" --np %d --mesh "%s" --conmul %.2f --input_state "%s" --tend %.2f --check %.2f --ATP_start %.2f --ATP_cl %.2f --ATP_pls %.2f --ATP_Min_Cycle %.2f', ...
                  pythonExe, Simscript, nprocs, mesh, conmul, input_state, tend, check, ATP_start, ATP_cl, ATP_pls, ATP_Min_Cycle);

    % Display the command to ensure it's correctly constructed
    %disp('Running command:');
    %disp(cmd);

    % Run the Python script and capture the output
    [status, cmdout] = system(cmd);

    % Check for errors
    if status ~= 0
        % Change back to the original directory before throwing an error
        cd(originalDir);
        error('Error running Python script:\n%s', cmdout);
    else
        disp('ATP simulated successfully.');
    end

    % Change back to the original directory
    cd(originalDir);
end
