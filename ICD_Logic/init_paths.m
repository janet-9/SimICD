function init_paths()
% INIT_PATHS Sets up the required paths for the project.
%   This script adds necessary directories and subdirectories to the MATLAB path.

    % Define the base directory (change this to your project's base directory)
    baseDir = '/home/k23086865/Projects/ICD_Online_24_Testing_Single_Chamber';

    % Add paths to various directories
    addpath(fullfile(baseDir, 'ICD_Online_24_Sim_Files'));

    % Display a message indicating paths have been set up
    disp('All necessary paths added.');
end