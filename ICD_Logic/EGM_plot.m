function EGM_plot(phie_filePath, pythonExe, pythonScript, simFolder, phieName, PAt_filename, ICD_Traces_filename, EGM_name)
% EGM_Plot: Generate the EGM from the phie file
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

% Check if the file exists
if exist(phie_filePath, 'file') == 2
    %disp(['Monitoring file: ', phie_filePath]);

    % Call the Python script with the updated file path -
    command = sprintf('%s %s --sim_folder %s --phie_name %s', pythonExe, pythonScript, simFolder, phieName);
    [~, cmdout] = system(command);


    % Check if ASCII files are produced
    if exist(PAt_filename, 'file') == 2 && exist(ICD_Traces_filename, 'file') == 2
        % Call the MATLAB function to generate the EGM structure
        try
            generateEGMStructure_fromascii(PAt_filename, ICD_Traces_filename, EGM_name);

        catch ME
            disp(['Error generating EGM structure: ', ME.message]);
        end
    else
        disp('ASCII files not found. Skipping EGM structure generation.');
    end
else
    disp(['File does not exist: ', phie_filePath]);

    plotEGM_ATP(EGM);
end
