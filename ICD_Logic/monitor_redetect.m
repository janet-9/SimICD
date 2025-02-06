function [ICD_diagnosis, EGM, EGM_features, ICD_sense_state, ICD_sense_param] = monitor_redetect(simulationDuration, outputFile, EGM_name, EGM_features_name, therapySigs, input_state_time, NSR_temp)
    % monitor_initial: Monitor the simulation for arrhythmias and return diagnosis.
    % 
    % Parameters:
    % simulationDuration - The duration (in seconds) for which to monitor the simulation
    % outputFile - the simulation folder to monitor for diagnosis
    % EGM_name - name for the EGM data struct from the simulation 
    % EGM_features_name - name for the extracted EGM features from the simulation 
    % TherapySigs - previous therapy signals used in the redetection
    % algorithm
    
    if nargin < 1
        simulationDuration = 86400; % Default monitoring duration if not specified
    end

    % Pause to allow the simulation to generate necessary files
    pause(10);

    % Define the folder paths based on the output file provided
    simFolder = fullfile('/home/k23086865/Projects/ICD_Online_24_Testing_Single_Chamber/ICD_Online_24_Sim_Files', outputFile);
    phie_filePath = fullfile(simFolder, 'phie.igb');

    % Define the file path for the extraction of the phie traces 
    pythonScript = '/home/k23086865/Projects/ICD_Online_24_Testing_Single_Chamber/phie_extract.py';
    pythonExe = 'python'; % Assuming python executable is available in the path

    % Define the name for the extracted phie traces
    phieName = 'phie_icd';

    % Define the ICD_traces file and the name of EGM
    ICD_traces_file = fullfile(simFolder, phieName);
   
    % Monitor the file with the redetection algorithm
    disp('ICD Monitoring in Progress...');
    [EGM, EGM_features, ICD_sense_state, ICD_sense_param, ICD_diagnosis]= redetection(phie_filePath, simulationDuration, pythonExe, pythonScript, simFolder, phieName, ICD_traces_file, EGM_name, therapySigs, NSR_temp);
    
    
    % Save the relevant structures:
    % EGM (raw)
    save([char(EGM_name), '.mat'], 'EGM');
    % EGM features 
    save([char(EGM_features_name), '.mat'], 'EGM_features');

    % Diagnosis structure
    ICD_diagnosis.last_beat_time = ICD_diagnosis.last_beat_time + input_state_time;
    save([char(EGM_features_name), 'ICD_diagnosis.mat'], 'ICD_diagnosis');

    % Display the relevant information
    plotEGM(EGM, EGM_features, ICD_diagnosis.last_beat_time - input_state_time, EGM_name );
    disp(ICD_diagnosis);
end
