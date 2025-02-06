function [EGM, EGM_features, ICD_sense_state, ICD_sense_param, ICD_diagnosis, message]= redetection(phie_filePath, monitorDuration, pythonExe, pythonScript, simFolder, phieName,ICD_Traces_filename, EGM_name, therapySigs, NSR_temp)
    % MONITOR_FILE Monitors a specified file for updates and calls a Python function if updated,
    % followed by a MATLAB function to process the resulting ASCII files and analyze the EGM.
    %   MONITOR_FILE(phie_filePath, monitorDuration, pythonExe, pythonScript, simFolder, phieName, PAt_filename, ICD_Traces_filename, EGM_name) 
    %   monitors the file at the given path for changes in size, calls the specified Python function 
    %   if the file is updated, and then calls the MATLAB function to generate the EGM structure and analyze it.
    %
    %   Inputs:
    %       phie_filePath      - Full path to the file to be monitored
    %       monitorDuration    - Duration for which to monitor the file (in seconds)
    %       pythonExe          - Full path to the Python executable
    %       pythonScript       - Full path to the Python script to be called when the file is updated
    %       simFolder          - Simulation folder to pass to the Python script
    %       phieName           - Name of the extracted phie traces to pass to the Python script
    %       PAt_filename       - Full path to the ASCII file for PAt data
    %       ICD_Traces_filename- Full path to the ASCII file for ICD Traces data
    %       EGM_name           - Name for the EGM structure to be saved
    %
    %   Example:
    %       monitor_file('/path/to/file.igb', 60, '/usr/bin/python3', '/path/to/python_script.py', '/path/to/simFolder', 'phie_icd', '/path/to/PAt_filename.txt', '/path/to/ICD_Traces_filename.txt', 'EGM_name');
    message = 'No further therapy required';
    initialMessage = message;
    % Check if the file exists
    if exist(phie_filePath, 'file') == 2
        % disp(['Monitoring file: ', phie_filePath]);

        % Initial file size (in bytes)
        initialFileSize = dir(phie_filePath).bytes;

        % Start timer
        tic;

        % Monitoring loop
        while true
            % Get current file size
            currentFileSize = dir(phie_filePath).bytes;

            % Check if file size has changed
            if currentFileSize ~= initialFileSize
                %disp(['File updated. New size: ', num2str(currentFileSize), ' bytes']);
                initialFileSize = currentFileSize;  % Update initial size

                % Call the Python script with the updated file path
                command = sprintf('%s %s --sim_folder %s --phie_name %s', pythonExe, pythonScript, simFolder, phieName);
                [~, ~] = system(command);

                % Clean up the petsc file that is generated using this
                % script
                currentfolder = pwd;
                keyword = 'petsc_np';
                allItems = dir(currentfolder);

                % Filter only directories and exclude '.' and '..'
                allFolders = allItems([allItems.isdir] & ~ismember({allItems.name}, {'.', '..'}));

                % Loop through the folders and delete those that contain the keyword
                for k = 1:length(allFolders)
                    folderName = allFolders(k).name;
                    if contains(folderName, keyword, 'IgnoreCase', true)
                        folderPath = fullfile(currentfolder, folderName);
                        rmdir(folderPath, 's'); % 's' option deletes the folder and its contents
                        %fprintf('Deleted folder: %s\n', folderPath);
                    end
                end


                % Print the output of the Python script for debugging
                % disp('Python script output:');
                % disp(cmdout);

                % Check if ASCII files are produced
                if exist(ICD_Traces_filename, 'file') == 2
                    % Call the MATLAB function to generate the EGM structure
                    try
                        generateEGMStructure_fromascii(ICD_Traces_filename, EGM_name);

                        
                        % Analyze the generated EGM
                        [EGM, EGM_features, ICD_sense_state, ICD_sense_param, ICD_diagnosis, message] = analyze_EGM_redetection(EGM_name, therapySigs, NSR_temp);
                        % save('output_message', 'ICD_diagnosis.message')
                        % Check if message status of the ICD has changed -
                        % this will break the monitoring loop 
                        if ~strcmp(ICD_diagnosis.message, initialMessage)
                            disp(ICD_diagnosis.message);
                            break; 
                        end


                        % Exit condition (e.g., End-Of-Episode Timer has been reached)
                        lines = readline(ICD_Traces_filename);
                        if numel(lines) >= 10000 %Value hard-coded from the BSc manual
                            disp('End-Of-Episode Timer Expired: Monitoring stopped.');
                            %Terminate background episode simulation
                            killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
                            system(killCommand);
                            disp('Episode Simulation Ended...');
                            break
                        end 


                    catch ME
                        %disp(['Error generating EGM structure: ', ME.message]);
                    end
                else
                    disp('ASCII files not found. Skipping EGM structure generation.');
                end
            %else
                %disp('No change in file size.');
            end

            % Pause for a while before checking again - check every 1 second
            pause(1);

           
            if toc > monitorDuration
                disp('Monitoring Duration Expired: Monitoring stopped.');
                %Terminate background episode simulation
                killCommand = sprintf('pkill -u k23086865 "openCARP" > /dev/null 2>&1 ');
                system(killCommand);
                disp('Initial Episode Simulation Ended...');
                break
                
            end
        end
    else
        disp(['File does not exist: ', phie_filePath]);
    end
end