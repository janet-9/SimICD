function output_clean(targetDir, EGM_name, EGM_features_name, episode_folder, todayDate)
% output_clean - Moves simulation output files to a target directory and
%                removes intermediate files from simulation folders.
%
% Inputs:
%   targetDir          - Full path to the output folder for this patient test
%   EGM_name           - Prefix of EGM trace files to move
%   EGM_features_name  - Prefix of EGM feature files to move
%   episode_folder     - Folder name within Episode_Sim_Scripts for episode files
%   todayDate          - String representing the date of episode run

    currentDir = pwd;
    
    if ~ischar(todayDate) && ~isstring(todayDate)
    todayDate = datestr(todayDate, 'yyyy-mm-dd');  % convert datetime to string to find the files
    end
    disp(todayDate);

    %% 1. Move EGM trace and feature files, Therapy files, and other relevant .mat files to the output folder
    tracefiles = dir(fullfile(currentDir, [EGM_name, '*']));
    featurefiles = dir(fullfile(currentDir, [EGM_features_name, '*']));
    matfiles = dir(fullfile(currentDir, '*.mat'));
    pngfiles = dir(fullfile(currentDir, '*.png'));
    diaryname =dir(fullfile(currentDir, '*log.txt'));
   

    allfiles = [tracefiles; featurefiles; matfiles; pngfiles; diaryname];
    
    % Move the created simulation files from the main folder into the
    % output folder
    fprintf('Moving %d files to %s...\n', length(allfiles), targetDir);
    for i = 1:length(allfiles)
        oldPath = fullfile(allfiles(i).folder, allfiles(i).name);
        newPath = fullfile(targetDir, allfiles(i).name);

        if exist(oldPath, 'file') ~= 2
            %warning('Skipping missing file: %s', oldPath);
            continue;
        end

        try
            movefile(oldPath, newPath);
        catch ME
            warning('Failed to move file %s:\n%s', oldPath, ME.message);
        end
    end

    % Move simulation folders that match date
    simDirs = dir(fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', episode_folder, [todayDate, '*']));
    simDirs = simDirs([simDirs.isdir]);
    simDirs = simDirs(~ismember({simDirs.name}, {'.', '..'}));

    fprintf('Moving %d simulation folders to %s...\n', length(simDirs), targetDir);
    for i = 1:length(simDirs)
        oldFolderPath = fullfile(simDirs(i).folder, simDirs(i).name);
        newFolderPath = fullfile(targetDir, 'Sim_folders', simDirs(i).name);

        if ~exist(oldFolderPath, 'dir')
            %warning('Skipping missing folder: %s', oldFolderPath);
            continue;
        end

        try
            mkdir(fileparts(newFolderPath));
            movefile(oldFolderPath, newFolderPath);
            fprintf('Moved %s to %s\n', simDirs(i).name, newFolderPath);
        catch ME
            warning('Failed to move folder %s:\n%s', oldFolderPath, ME.message);
        end
    end


    %% 2. Clean up .trc, .roe files and PETSc folders in the main environment
    episodePath = fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', episode_folder);
    trcfiles = dir(fullfile(episodePath, '*.trc'));
    outnamefiles = dir(fullfile(episodePath, 'outputFileName*'));
    sparemat = dir(fullfile(episodePath, '*.mat'));
    
    chkptfiles = dir(fullfile(episodePath, '*.roe'));
    chkptfiles_root = dir(fullfile(currentDir, '*.roe'));
    petscfolders = dir(fullfile(currentDir, '*petsc*'));

    extrafiles = [trcfiles; chkptfiles; chkptfiles_root;outnamefiles;sparemat];

    fprintf('Deleting %d files and %d PETSc folders...\n', length(extrafiles), length(petscfolders));
    for i = 1:length(extrafiles)
        delete(fullfile(extrafiles(i).folder, extrafiles(i).name));
    end

    for i = 1:length(petscfolders)
        rmdir(fullfile(petscfolders(i).folder, petscfolders(i).name), 's');
    end

    fprintf('Episode results saved to: %s\n', targetDir);

    %% 3. Within the Output folder: Delete unnecessary files and folders:

    outnamefiles = dir(fullfile(targetDir, 'outputFileName*'));
    ther1 = dir(fullfile(targetDir, 'Prev_TherapySigs.mat'));
    ther2 = dir(fullfile(targetDir, 'Therapy_History.mat'));
    ther3 = dir(fullfile(targetDir, 'Redetect_Param.mat'));

    sparefiles = [outnamefiles, ther1, ther2, ther3];
    for i = 1:length(sparefiles)
        delete(fullfile(sparefiles(i).folder, sparefiles(i).name));
    end

    %% 4. Within the Output folder: Concat the relevant EGM traces to show the FULL trace of the episode:

    % Load the initial episode first, then the other files in a struct:
    FullEGMArray = load_EGMs(targetDir, EGM_name);
    %disp(FullEGMArray);

    % Concatenate and clean the EGMs into a full structure
    full_egm = full_egm_construction(FullEGMArray, 1:length(FullEGMArray));
    save(fullfile(targetDir, 'FULL_EGM_output.mat'), 'full_egm');
    %disp(full_egm)

    % Plot the full trace for the episode:
    plotEGM_FULL(full_egm,'Full_Episode_Trace', targetDir)


end
