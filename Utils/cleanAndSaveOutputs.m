function cleanAndSaveOutputs(targetDir, EGM_name, EGM_features_name, episode_folder)
% cleanAndSaveOutputs - Move simulation output files to the target directory
% and clean up intermediate files from simulation folders.
%
% Inputs:
%   targetDir            - Full path to the output folder for this patient test
%   EGM_name             - Prefix of EGM trace files to move
%   EGM_features_name    - Prefix of EGM feature files to move
%   episode_folder       - Folder name within Episode_Sim_Scripts to search for today's files

    currentDir = pwd;
    todayDate = datestr(now, 'yyyymmdd'); % Assuming this is how todayDate is defined

    %% 1. Move the EGM results
    tracefiles = dir(fullfile(currentDir, [EGM_name, '*']));
    featurefiles = dir(fullfile(currentDir, [EGM_features_name, '*']));
    simfiles = dir(fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', episode_folder, [todayDate, '*']));

    allfiles = [tracefiles; featurefiles; simfiles];

    for i = 1:length(allfiles)
        oldPath = fullfile(allfiles(i).folder, allfiles(i).name);
        newPath = fullfile(targetDir, allfiles(i).name);
        movefile(oldPath, newPath);
    end

    %% 2. Clean up .trc, .roe files and PETSc folders from Reentrant_VT
    reentrantPath = fullfile(currentDir, 'Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT');

    trcfiles = dir(fullfile(reentrantPath, '*.trc'));
    chkptfiles = dir(fullfile(reentrantPath, '*.roe'));
    petscfolders = dir(fullfile(currentDir, '*petsc*'));

    for i = 1:length(trcfiles)
        delete(fullfile(trcfiles(i).folder, trcfiles(i).name));
    end

    for i = 1:length(chkptfiles)
        delete(fullfile(chkptfiles(i).folder, chkptfiles(i).name));
    end

    for i = 1:length(petscfolders)
        rmdir(fullfile(petscfolders(i).folder, petscfolders(i).name), 's');
    end

    fprintf('ATP Therapy Availability Threshold Exceeded - Shock Required!\n');
end
