function argsICD = initialise_ICD(varargin)

    %% -- Initialize the ICD parameters using default values or user-specified overrides -- %%
    %% -- Note: These features are based on the Boston Scienftic ICD specifications -- %%

    % Set up input parser
    p = inputParser;
    p.FunctionName = 'initialise_ICD';

    % --- Therapy zones and thresholds (ms) --- %
    addParameter(p, 'VF_th', 300);
    addParameter(p, 'QC_Override_th', 240);
    addParameter(p, 'VT_th', 353);
    addParameter(p, 'VT_1_th', 429);

    % --- Episode Duration parameters (ms)--- %
    addParameter(p, 'VF_dur', 2500);
    addParameter(p, 'VT_dur', 2500);
    addParameter(p, 'VT_1_dur', 2500);

    % --- RhythmID paramters --- %%
    addParameter(p, 'VTC_corr_th', 0.94);
    addParameter(p, 'Afib_th', 353);
    addParameter(p, 'stab', 20);

    % --- Redetection durations (ms) --- %
    addParameter(p, 'VF_red_dur', 1000);
    addParameter(p, 'VT_red_dur', 1000);
    addParameter(p, 'VT_1red_dur', 1000);

    % --- End of episode timers (ms) --- %
    addParameter(p, 'EoE_timer_NT_dur', 10000);
    addParameter(p, 'EoE_timer_ATP_dur', 10000);

    % --- ATP timeouts (ms) --- %
    addParameter(p, 'VT_ATP_TO', 30000);
    addParameter(p, 'VT_1_ATP_TO', 40000);

    % Parse input
    parse(p, varargin{:});
    args= p.Results;

    % Assign fields to struct to called later
    ICDparam = struct( ...
        'VF_th', args.VF_th, ...
        'QC_Override_th', args.QC_Override_th, ...
        'VT_th', args.VT_th, ...
        'VT_1_th', args.VT_1_th, ...
        'VF_dur', args.VF_dur, ...
        'VT_dur', args.VT_dur, ...
        'VT_1_dur', args.VT_1_dur, ...
        'VTC_corr_th', args.VTC_corr_th, ...
        'Afib_th', args.Afib_th, ...
        'stab', args.stab, ...
        'VF_red_dur', args.VF_red_dur, ...
        'VT_red_dur', args.VT_red_dur, ...
        'VT_1red_dur', args.VT_1red_dur, ...
        'EoE_timer_NT_dur', args.EoE_timer_NT_dur, ...
        'EoE_timer_ATP_dur', args.EoE_timer_ATP_dur, ...
        'VT_ATP_TO', args.VT_ATP_TO, ...
        'VT_1_ATP_TO', args.VT_1_ATP_TO ...
    );

    % Save as arguments to be used in the main script 
    argsICD = args;
      
    % Save to file
    save("ICDparam.mat", 'ICDparam');
end
