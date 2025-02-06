

function [status, cmdout] = run_simulation(pythonExe, sim_scriptPath, varargin)
%RUN_SIMULATION Runs a simulation using the specified Python executable and script.
%   [status, cmdout] = RUN_SIMULATION(pythonExe, sim_scriptPath, varargin) executes the
%   simulation script using the given Python executable and returns the 
%   exit status and command output.
%
%   Inputs:
%       pythonExe      - Full path to the Python executable
%       sim_scriptPath - Full path to the simulation script
%       varargin       - Additional arguments to pass to the Python script
%
%   Outputs:
%       status - Exit status of the simulation command
%       cmdout - Standard output and standard error from the simulation command

    % Construct the command with additional arguments
    command = [pythonExe, ' ', sim_scriptPath];
    for i = 1:2:length(varargin)
        argName = varargin{i};
        argValue = varargin{i+1};
        if isnumeric(argValue)
            argValue = num2str(argValue);
        end
        command = [command, ' --', argName, ' ', argValue];
    end

    % Execute the command
    [status, cmdout] = system(command);
end
