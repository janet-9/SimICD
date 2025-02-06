function NSR_temp = NSR_template(EGM_NSR_name)
    % load_and_generate_NSR_template: Load NSR template and generate shock signal morphology template.

    % Load the NSR template EGM
    load(EGM_NSR_name);
    
    % Generate the shock signal morphology template
    NSR_temp = NSR_temp_build(EGM);

    %disp('NSR Template Loaded!')
end