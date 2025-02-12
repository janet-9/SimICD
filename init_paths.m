function init_paths()
% Initialise the paths to the simulation folders and subfolders. 

    % Get Base Diectory (current folder)
    baseDir = fileparts(mfilename('fullpath'));
    
    % List of subdirectories to add
    subDirs = {'ICD_Logic', ...
        'ICD_Logic/Sensing', 'ICD_Logic/Detection', 'ICD_Logic/Therapy',...
        'NSR_Temps', ...
        'Sim_Files/Episode_Sim_Scripts','Sim_Files/Input_states', 'Sim_Files/Therapy_Scripts', ...
        'Sim_Files/Episode_Sim_Scripts/Electrodes',  'Sim_Files/Episode_Sim_Scripts/Focal_VT/', ...
        'Sim_Files/Episode_Sim_Scripts/NSR', 'Sim_Files/Episode_Sim_Scripts/Reentrant_VT', ... 
        'OUTPUT'};
    
    % Add paths for each subdirectory
    for i = 1:length(subDirs)
        folderPath = fullfile(baseDir, subDirs{i});
        if isfolder(folderPath)
            addpath(folderPath);
           
        else
            warning(['Directory not found: ', folderPath]);
        end
    end
    
    % Display a message indicating paths have been set up
    disp('All necessary paths have been added.');
end