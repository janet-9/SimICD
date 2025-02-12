function roeFile = findFinalCheckpointATP_focal(outputFile)
    % Post Therapy Simulation - Finding the final checkpoint of ATP delivery

    % Define the folder path using the provided output file directory
    folderPath = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', outputFile);
    % Get a list of all .roe files in the directory
    fileList = dir(fullfile(folderPath, '*.roe'));

    if ~isempty(fileList)
        % Find the final saved state (assuming first file in the list)
        roeFile = fileList(1).name;

        % Store the file name in Post_ATP structure
        Post_ATP.input_state = roeFile;
        fprintf('Post-therapy relaunch from: %s\n', roeFile);

        % Define the destination folder - simulation files
        destinationFolderPath = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT');

        % Move the .roe file to the destination directory
        movefile(fullfile(folderPath, roeFile), destinationFolderPath);
        %fprintf('Moved %s to %s\n', roeFile, destinationFolderPath);
    else
        fprintf('No .roe file for post-therapy relaunch found.\n');
    end

    % Save the Post ATP parameters
    
    saveFilename = fullfile(folderPath, 'Post_ATP_parameters.mat');
    save(saveFilename, 'Post_ATP');
    disp(Post_ATP);
end