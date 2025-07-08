function ATP_param = calculate_therapy_parameters_focal(outputFile, ICD_diagnosis, varargin)
% calculate_therapy_parameters: Calculates ATP parameters and prepares for therapy simulation.
%
% Parameters:
% outputFile - The name of the output file (folder) from the simulation.
% ICD_diagnosis - The diagnosis structure obtained from the initial simulation.
%
% Varargin:
% 1- Input_State_Time: the time of the initial episode state for offset times (default: 350)
% 2- ATP_CL_Percentage: Percentage of cycle length for ATP burst cycle length (default: 0.81)
% 3- ATP_Coupling_Percentage: Percentage of coupling time to start ATP (default: 0.81)
% 4- ATP_pls: number of pulses to be applied in the ATP delivery

% Check if optional arguments are provided and set them to defaults if
% not
if nargin >= 3 && ~isempty(varargin{1})
    Input_State_Time = varargin{1};
else
    Input_State_Time = 0;
end

if nargin >= 4 && ~isempty(varargin{2})
    ATP_CL_Percentage = varargin{2};
else
    ATP_CL_Percentage = 0.81;
end

if nargin >= 5 && ~isempty(varargin{3})
    ATP_Coupling_Percentage = varargin{3};
else
    ATP_Coupling_Percentage = 0.81;
end

if nargin >= 6 && ~isempty(varargin{4})
    ATP_pls = varargin{4};
else
    ATP_pls = 8;
end



% Define the simulation folder
 simFolder = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', outputFile);

% Extract necessary values from ICD_diagnosis for therapy parameter
% calculations
% last_beat_time = ICD_diagnosis.last_beat_time;
average_cycle = ICD_diagnosis.average_cycle;

% Calculate ATP parameters
format longG;
ATP_param.start = Input_State_Time + (average_cycle * ATP_Coupling_Percentage);
ATP_param.cycle = average_cycle * ATP_CL_Percentage;
ATP_param.Sim_End = ATP_param.start + (ATP_pls * ATP_param.cycle) + 1000;
ATP_param.pls = ATP_pls;

% Initialize variables for file search
closestFilename = '';
closestNumber = inf;

% Continuously search for the closest checkpoint file
while isempty(closestFilename)
    fileList = dir(fullfile(simFolder, 'checkpoint.*.roe'));

    for i = 1:length(fileList)
        filename = fileList(i).name;

        % Extract the numeric part of the filename
        pattern = 'checkpoint\.(\d+\.\d+)\.roe';
        tokens = regexp(filename, pattern, 'tokens');

        if ~isempty(tokens)
            fileNumber = str2double(tokens{1}{1});

            % Only consider files where the number is less than or equal to ATP_param.start
            if fileNumber <= ATP_param.start
                % Update the closest file if this one is closer to ATP_param.start
                if abs(fileNumber - ATP_param.start) < abs(closestNumber - ATP_param.start)
                    closestNumber = fileNumber;
                    closestFilename = filename;
                end
            end
        end
    end

    % Pause briefly to avoid overloading the system
    pause(1);  % Adjust the pause duration as needed
end

% Move the closest file to the base folder
sourceFile = fullfile(simFolder, closestFilename);
destFile = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', closestFilename); % Move to the base folder
movefile(sourceFile, destFile);  % Move the file

% Save the input state for ATP therapy
ATP_param.input_state = closestFilename;
fprintf('Launch ATP therapy from: %s\n', closestFilename);


% Save the ATP parameters for therapy
saveFilename = fullfile('Sim_Files', 'Episode_Sim_Scripts', 'Focal_VT', 'ATP_parameters.mat');
save(saveFilename, 'ATP_param');
disp(ATP_param);

end





    