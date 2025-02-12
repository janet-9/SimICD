function [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = monitor_ATP_reentrant(outputFile, EGM_name, EGM_features_name, Sim_End, NSR_temp)
   
    % Pause to allow the simulation to generate necessary files
    pause(5);
   
   
   % Define the folder paths based on the output file provided
    simFolder = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT', outputFile);
    phie_filePath = fullfile(simFolder, 'phie.igb');
    disp(phie_filePath);

    % Define the file path for the extraction of the phie traces 
    pythonScript = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Reentrant_VT', 'phie_extract.py');
    pythonExe = 'python'; % Assuming python executable is available in the path
    % Define the name for the extracted phie traces
    phieName = 'phie_icd';

    % Define the ICD_traces file, the atrial trace file, and the name of
    % EGM
    ICD_traces_file = fullfile(simFolder, phieName);
   
    % Monitor the file and call the Python script if updated
    disp('ATP Results...');
    [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = ATP_detection(phie_filePath, pythonExe, pythonScript, simFolder, phieName, ICD_traces_file, EGM_name, NSR_temp);

    % Save the relevant structures:
    % EGM (raw)
    save([char(EGM_name), '.mat'], 'EGM');
    % EGM features 
    save([char(EGM_features_name), '.mat'], 'EGM_features');

    % Display the relevant information
    plotEGM_ATP(EGM, EGM_features, Sim_End, EGM_name);
   
end

