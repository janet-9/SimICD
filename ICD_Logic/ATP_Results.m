function ATP_Results(outputFile, EGM_name)
    %ATP_Results: Analyse the ATP simulation - plotting the EGM of it. 
    % 
    % Parameters:
    % outputFile - the simulation folder to monitor for diagnosis
    % EGM_name - name for the EGM data struct from the simulation 
    % EGM_features_name - name for the extracted EGM features from the simulation

    % Define the folder paths based on the output file provided
    simFolder = fullfile('/home/k23086865/Projects/ICD_Online_24_TESTING/ICD_Online_24_Sim_Files', outputFile);
    phie_filePath = fullfile(simFolder, 'phie.igb');

    % Define the file path for the extraction of the phie traces 
    pythonScript = '/home/k23086865/Projects/ICD_Online_24_TESTING/phie_extract.py';
    pythonExe = 'python'; % Assuming python executable is available in the path

    % Define the name for the extracted phie traces
    phieName = 'phie_icd';

    % Define the ICD_traces file, the atrial trace file, and the name of EGM
    PAT_file = '/home/k23086865/Projects/ICD_Online_24_TESTING/NSR_75bpm_30s_PsuedoAtrial';
    ICD_traces_file = fullfile(simFolder, phieName);
   
    % Generate the EGM from the results of the ATP simulation 
    disp('ATP delivery EGM trace...');
    EGM_plot(phie_filePath, pythonExe, pythonScript, simFolder, phieName, PAT_file, ICD_traces_file, EGM_name);

    % % Save the relevant structures:
    % % EGM (raw)
    % save([EGM_name, '.mat'], 'EGM');
    % 
    % % Display the relevant information
    % plotEGM_ATP(EGM);
end


