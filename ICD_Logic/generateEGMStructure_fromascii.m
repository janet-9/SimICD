function generateEGMStructure_fromascii(ICD_Traces_filename, EGM_name)
    % Read in data from the ASCII file
    ICD_Traces_data = load_ascii_data(ICD_Traces_filename);

    % Extract columns from the loaded data:  CAN, RVCoil, RVRing, RVTip
    Can = ICD_Traces_data(:, 2);
    RVCoil = ICD_Traces_data(:, 3);
    RVRing = ICD_Traces_data(:, 4);
    RVTip = ICD_Traces_data(:, 5);

    % Calculate bipolar recordings
    v_raw = RVRing - RVTip;
    shock = Can - RVCoil;

    lv = length(v_raw);
   
    % Assign extra structures needed for the algorithm
    RVin = zeros(1, lv);
    lv = length(v_raw);


    % Save the data in an EGM structure
    EGM = struct('VSigRaw', v_raw, 'Shock', shock, 'RVin', RVin);
    save([char(EGM_name), '.mat'], 'EGM');
end

function data = load_ascii_data(filename)
    % Load ASCII data from a file
    data = load(filename, '-ascii'); % Assuming the file is a simple ASCII file without headers
    if isempty(data)
        error(['Failed to load data from file: ', filename]);
    end
end
