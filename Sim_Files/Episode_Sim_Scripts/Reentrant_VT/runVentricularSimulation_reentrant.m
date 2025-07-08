function [outputFile] = runVentricularSimulation_reentrant(Simscript, input_state, tend, nprocs, pythonExe, args)
    % runVentricularSimulation_reentrant Executes a Python script for ventricular stimulation simulation in the background.
    % The script includes all necessary arguments, runs in parallel (with --np), and captures the process ID (PID).
    
    % Save the current directory
    originalDir = pwd;
    %disp(['Simulation directory: ', originalDir]);

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');
    cd(simDir);

    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
    outputFile = sprintf('%s_%s_INPUT_%s_conmul_%.2f', todayDateStr, args.mesh, input_state, args.conmul);

    % Save the output file name to a .mat file for later reference
    save('outputFileName.mat', 'outputFile');

    % Construct the command to run the Python script with necessary arguments
    cmd = sprintf('%s %s --np %d --mesh %s --myocardium %.2f --scar_flag %d --scar_region %.2f --isthmus_region %.2f --conmul %.2f --input_state %s --model %s --tend %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --NSR_vtx %s --electrodes %s --output_res %.2f --check %.2f', ...
                  pythonExe, Simscript, nprocs, args.mesh, args.myocardium, args.scar_flag, args.scar_region, args.isthmus_region, args.conmul, input_state, args.model, tend, args.bcl, args.strength, args.duration, args.start, args.NSR_vtx, args.electrodes, args.output_res, args.check);
    %disp(cmd);

    % Run the command in the background and capture the PID
    cmd = [cmd, ' & echo $!'];  
    
    % Display the constructed command for verification
    disp('Running cardiac simulation...:');
    %disp(cmd);

    % Execute the command and get the PID
    [~, ~] = system(cmd);

    % Change back to the original directory
    cd(originalDir);
end
