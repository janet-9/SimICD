function ICDparam = initialise_ICD()
    % initialise_ICD: Initialize the ICD parameters using default values.
    
    % Set parameters for the ICD, using the default values from Boston Scientific
    % Therapy zones and thresholds
    ICDparam.VF_th = 300;
    ICDparam.QC_Override_th = 240;
    ICDparam.VT_th = 353;
    ICDparam.VT_1_th = 429;

    % Duration parameters (in milliseconds)
    ICDparam.VF_dur = 2500;
    ICDparam.VT_dur = 2500;
    ICDparam.VT_1_dur = 2500; 

    % Additional parameters
    ICDparam.VTC_corr_th = 0.94;
    ICDparam.Afib_th = 353;
    ICDparam.stab = 20;

    % Redetection durations (in milliseconds)
    ICDparam.VF_red_dur = 1000;
    ICDparam.VT_red_dur = 1000;
    ICDparam.VT_1red_dur = 1000;

    % End of episode timers (in milliseconds)
    ICDparam.EoE_timer_NT_dur = 10000;
    ICDparam.EoE_timer_ATP_dur = 10000;

    % ATP timeouts (in milliseconds)
    ICDparam.VT_ATP_TO = 30000;
    ICDparam.VT_1_ATP_TO = 40000;

    %disp('ICD initialised!')

    save("ICDparam.mat", 'ICDparam')
end