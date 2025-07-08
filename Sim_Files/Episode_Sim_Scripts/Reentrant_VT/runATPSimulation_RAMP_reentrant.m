function outputFile = runATPSimulation_RAMP_reentrant(Simscript, input_state, tend, ATP_start, ATP_cl, ATP_pls, nprocs, pythonExe, args)
    % runATPSimulation_RAMP_reentrant Executes a Python script for ATP therapy simulation in the background.
    % Runs the specified Python script with the given parameters and returns the generated output file name.

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
    
    outputFile = sprintf('%s_ATP_APP_INPUT_%s_%.2f_atpbcl_%.2f_atpstart_%.2f_atpdec_%.2f_atppls', ...
        todayDateStr, inputFilename, ATP_cl, ATP_start, args.ATP_dec, ATP_pls);

    % Save the filename to a .mat file for later use
    save('outputFileName_ATP.mat', 'outputFile');

    % Construct the command to run the Python script with all required arguments
    cmd = sprintf('"%s" "%s" --np %d --mesh "%s" --myocardium %.2f --scar_flag %d --scar_region %.2f --isthmus_region %.2f --conmul %.2f --input_state "%s" --model "%s" --tend %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --NSR_vtx "%s" --electrodes "%s" --output_res %.2f --check %.2f --ATP_start %.2f --ATP_pls %.2f --ATP_cl %.2f --ATP_strength %.2f --ATP_duration %.2f --ATP_stimsite "%s" --ATP_Min_Cycle %.2f --ATP_dec %.2f', ...
                  pythonExe, Simscript, nprocs, args.mesh, args.myocardium, args.scar_flag, args.scar_region, args.isthmus_region, args.conmul, input_state, args.model, tend, args.bcl, args.strength, args.duration, args.start, args.NSR_vtx, args.electrodes, args.output_res, args.check, ATP_start, ATP_pls, ATP_cl, args.ATP_strength, args.ATP_duration, args.ATP_stimsite, args.ATP_Min_Cycle, args.ATP_dec);

    % Display the command for debugging purposes
    %disp('Executing Python script with command:');
    %disp(cmd);

    % Run the Python script in the background and capture the process ID (PID)
    [~, ~] = system(cmd);


    % Change back to the original directory
    cd(originalDir);

    disp('ATP simulation started successfully in the background.');
end










