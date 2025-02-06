function [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = analyze_EGM_ATP(EGM_name, NSR_temp)

    % Generate the NSR template for the discrimination algorithm:
    NSR_temp = NSR_template(NSR_temp);
    %load the EGM you want to analyse
    
    load([char(EGM_name), '.mat'], 'EGM');
    %Save the EGM for plotting 
    save([char(EGM_name), '.mat'], 'EGM');

    % Extract the key features of the EGM
    [EGM, EGM_features, ICD_sense_state, ICD_sense_param] = BSc_extract_EGM_features_NSR_temp(EGM, NSR_temp, [], 2);

end 