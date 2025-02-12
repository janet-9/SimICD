function [EGM, EGM_features, ICD_sense_state, ICD_sense_param]= ATP_detection(phie_filePath, ...
    pythonExe, pythonScript, simFolder, phieName, ICD_Traces_filename, EGM_name, NSR_temp)

if exist(phie_filePath, 'file') == 2

    % Call the Python script with the updated file path
    command = sprintf('%s %s --sim_folder %s --phie_name %s', pythonExe, ...
        pythonScript, simFolder, phieName);
    [~, cmdout] = system(command);

    % Check if ASCII files are produced
    if exist(ICD_Traces_filename, 'file') == 2
        % Call the MATLAB function to generate the EGM structure
        try
            generateEGMStructure_fromascii(ICD_Traces_filename, ...
                EGM_name);

            % Analyze the generated EGM
            [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = analyze_EGM_ATP(EGM_name, NSR_temp);

        catch ME
            error(['Error generating EGM structure: ', ME.message]);
        end
    else
        error(['ASCII files not found. Skipping EGM structure generation. ', ...
            'Command output:',cmdout]);
    end
else
    error('Phie Files not found. Skipping EGM structure generation.' );
end
end
