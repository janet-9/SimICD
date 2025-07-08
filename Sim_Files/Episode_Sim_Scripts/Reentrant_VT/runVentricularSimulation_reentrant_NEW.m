function [outputFile] = runVentricularSimulation_reentrant_NEW(Simscript, nprocs, pythonExe, tend, args)

%% -- Run the intial epsiode simulation of focal VT using predefined arguments -- %%

% Save the current directory
originalDir = pwd;

% Change to the target directory where the simulation should be executed %
simDir = fullfile(originalDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');
cd(simDir);

% Construct the output file name based on the input arguments %
todayDate = datetime('today', 'Format', 'yyyy-MM-dd');
todayDateStr = char(todayDate);

outputFile = sprintf('%s_%s_INPUT_%s_conmul_%.2f', todayDateStr, args.mesh, args.input_state, args.conmul);

% Save the output file name to a .mat file for later reference
save('outputFileName.mat', 'outputFile');

% Copy over the necessary files to the main simulation folder %

% Copy all of the mesh files %
meshBaseName = args.mesh;
meshFolder = fullfile(simDir, 'meshes');

% Look for all files starting with the mesh base name in the mesh folder
meshFiles = dir(fullfile(meshFolder, [meshBaseName, '.*']));

% Copy each found mesh file into the current sim folder
for k = 1:length(meshFiles)
    src = fullfile(meshFiles(k).folder, meshFiles(k).name);
    dest = fullfile(simDir, meshFiles(k).name);
    try
        if ~strcmp(src, dest)  % Prevent "copy onto itself" error
            copyfile(src, dest);
        end
    catch ME
        warning('Could not copy mesh file %s: %s', meshFiles(k).name, ME.message);
    end
end

% copy the electrodes file % 

% Construct the full path to the electrodes file (append .pts if needed)
electrodesFileName = args.electrodes;
if ~endsWith(electrodesFileName, '.pts')
    electrodesFileName = [electrodesFileName, '.pts'];
end

% Build full source path for electrodes
electrodesSrc = fullfile(simDir, 'electrodes', electrodesFileName);

% Build destination path (current working directory is simDir)
electrodesDest = fullfile(simDir, electrodesFileName);

% Copy electrodes file if it exists
if exist(electrodesSrc, 'file')
    copyfile(electrodesSrc, electrodesDest);
else
    warning('Electrodes file not found: %s', electrodesSrc);
end

% Define mapping of the other simulation argument fields to subdirectories
fileMap = containers.Map(...
    { 'input_state', 'NSR_vtx', 'ATP_stimsite', 'EGM_template'}, ...
    { 'input_states', 'stim_sites', 'stim_sites', 'NSR_temps'} ...
);

copiedFiles = {};  % Keep track of what we copy to delete later

% Normalize path utility
normalizePath = @(p) char(java.io.File(p).getCanonicalPath());

% Loop through and copy files if not already in the current directory
keysToCheck = fileMap.keys;
for i = 1:length(keysToCheck)
    field = keysToCheck{i};
    
    if isfield(args, field)
        subdir = fileMap(field);
        srcFile = fullfile(simDir, subdir, args.(field));
        dstFile = fullfile(simDir, args.(field));  % where it's copied to (same dir as current)
        
        % Copy only if source exists and is different path
        try
            if exist(srcFile, 'file') && ...
               (~exist(dstFile, 'file') || ~strcmp(normalizePath(srcFile), normalizePath(dstFile)))
                copyfile(srcFile, dstFile);
                copiedFiles{end+1} = dstFile;
            end
        catch ME
            warning('Could not copy file "%s": %s', srcFile, ME.message);
        end
    else
        warning('Missing expected field in args: "%s"', field);
    end
end

% Construct the command to run the Python script with necessary arguments
cmd = sprintf('%s %s --np %d --mesh %s --myocardium %.2f --scar_flag %d --scar_region %.2f --isthmus_region %.2f --conmul %.2f --input_state %s --model %s --tend %.2f --bcl %.2f --strength %.2f --duration %.2f --start %.2f --NSR_vtx %s --electrodes %s --output_res %.2f --check %.2f & echo $!', ...
    pythonExe, Simscript, nprocs, args.mesh, args.myocardium, args.scar_flag, args.scar_region, args.isthmus_region, args.conmul, args.input_state, args.model, tend, args.bcl, args.strength, args.duration, args.start, args.NSR_vtx, args.electrodes, args.output_res, args.check);


% Display the command to ensure it's correctly constructed
disp('Running cardiac simulation...');
disp(cmd);

% Run the Python script in the background and capture the PID
[~, ~] = system(cmd);

% Change back to the original directory
cd(originalDir);
end
