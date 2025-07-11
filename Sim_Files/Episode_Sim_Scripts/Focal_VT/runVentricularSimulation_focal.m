function [outputFile] = runVentricularSimulation_focal(Simscript, input_state, tend, nprocs, pythonExe, args)
    
    
    % runVentricularSimulation_focal Executes a Python script for ventricular stimulation simulation with focal VT.
    %   [outputFile] = runVentricularSimulation_focal(Simscript, mesh, conmul, input_state, model, tend, pls, bcl, strength, duration, start, output_res, check, nprocs, pythonExe, ectopic, focal_start, episodes, episode_interval, focal_pls, focal_bcl, focal_strength, focal_duration)
    %   runs the specified Python script with the given parameters and returns the generated output file name.

    % Save the current directory
    originalDir = pwd;

    % Change to the target directory where the simulation should be executed
    simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT');
    cd(simDir);

    % Construct the output file name based on the input arguments
    todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
    todayDateStr = char(todayDate);
    
    outputFile = sprintf('%s_%s_Focal_VT_%s_%.2f_episodes_%.2f_focal_bcl_%.2f_focal_pls_%.2f_focal_strength_%.2f_focal_duration', todayDateStr, input_state, args.focal_site, args.episodes, args.focal_bcl, args.focal_pls, args.focal_strength, args.focal_duration);
   
    % Save the filename to a .mat file for later use
    save('outputFileName.mat', 'outputFile');

    % Construct the command to run the Python script with the given arguments
    cmd = sprintf('%s %s --np %d --mesh "%s" --myocardium %.2f --scar_flag %d --scar_region %.2f --isthmus_region %.2f --conmul %.2f --input_state "%s" --model "%s" --tend %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --NSR_vtx "%s" --electrodes "%s" --output_res %.2f --check %.2f --focal_site "%s" --focal_start %.2f --episodes %.2f --episode_interval %.2f --focal_pls %.2f --focal_bcl %.2f --focal_strength %.2f --focal_duration %.2f & echo $!', ...
                  pythonExe, Simscript, nprocs, args.mesh, args.myocardium, args.scar_flag, args.scar_region, args.isthmus_region, args.conmul, input_state, args.model, tend, args.bcl, args.strength, args.duration, args.start, args.NSR_vtx, args.electrodes, args.output_res, args.check, args.focal_site, args.focal_start, args.episodes, args.episode_interval, args.focal_pls, args.focal_bcl, args.focal_strength, args.focal_duration);
    
    % Display the command to ensure it's correctly constructed
    disp('Running cardiac simulation...');
    disp(cmd);

    % Run the Python script in the background and capture the PID
    [~, ~] = system(cmd);
    
    % Change back to the original directory
    cd(originalDir);
end
