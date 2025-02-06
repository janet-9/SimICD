function [ICD_diagnosis, EGM, EGM_features, ICD_sense_state, ICD_sense_param] = monitor_initial(simulationDuration, outputFile, EGM_name, EGM_features_name, NSR_temp, tend)
    % monitor_initial: Monitor the simulation for arrhythmias and return diagnosis.
    % 
    % Parameters:
    % simulationDuration - The duration (in seconds) for which to monitor the simulation
    % outputFile - the simulation folder to monitor for diagnosis
    % EGM_name - name for the EGM data struct from the simulation 
    % EGM_features_name - name for the extracted EGM features from the simulation 
    
    if nargin < 1
        simulationDuration =  18000; % Default monitoring duration if not specified - 5 hours 
    end

    % Pause to allow the simulation to generate necessary files
    pause(5);

    % Define the folder paths based on the output file provided
    simFolder = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', outputFile);
    phie_filePath = fullfile(simFolder, 'phie.igb');
    disp(phie_filePath);

    % Define the file path for the extraction of the phie traces 
    pythonScript = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', 'phie_extract.py');
    pythonExe = 'python'; % Assuming python executable is available in the path

    % Define the name for the extracted phie traces
    phieName = 'phie_icd';

    % Define the ICD_traces file and the name of EGM
    ICD_traces_file = fullfile(simFolder, phieName);
   
    % Monitor the file and call the Python script if updated
    disp('ICD Monitoring in Progress...');
    [EGM, EGM_features, ICD_sense_state, ICD_sense_param, ICD_diagnosis, ~] = initial_detection(phie_filePath, simulationDuration, pythonExe, pythonScript, simFolder, phieName, ICD_traces_file, EGM_name, NSR_temp, tend);

    % Save the relevant structures:
    % EGM (raw)
    save([char(EGM_name), '.mat'], 'EGM');
    % EGM features 
    save([char(EGM_features_name), '.mat'], 'EGM_features');
    % Diagnosis structure
    save([char(EGM_features_name), 'ICD_diagnosis.mat'], 'ICD_diagnosis');

    % Display the relevant information
    plotEGM(EGM, EGM_features, ICD_diagnosis.last_beat_time, EGM_name);
    disp(ICD_diagnosis);
end

