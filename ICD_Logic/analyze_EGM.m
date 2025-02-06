function [EGM, EGM_features, ICD_sense_state, ICD_sense_param, ICD_diagnosis, message]=analyze_EGM(EGM_name, NSR_temp)

   
    %Initialize the parameters of the ICD - default is the nominal set of
    %Boston Scientific device parameters:
    ICDparam = initialise_ICD();

    % Generate the NSR template for the discrimination algorithm:
    NSR_temp = NSR_template(NSR_temp);


    %load the EGM you want to analyse
    
    load([char(EGM_name), '.mat'], 'EGM');
    %Save the EGM for plotting 
    save([char(EGM_name), '.mat'], 'EGM');

    % Extract the key features of the EGM
    [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = BSc_extract_EGM_features_NSR_temp(EGM, NSR_temp, [], 2);

    % Analyze the signal
    [ICD_diagnosis, message] = BSc_disc_algorithm_SC(ICDparam, EGM_features, 0);
end 