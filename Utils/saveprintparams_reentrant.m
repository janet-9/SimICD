function paramfilepath = saveprintparams_reentrant(args, argsICD, logFilePath)
% Save simulation parameters to console and a txt log file for later inspection

    logFileName = 'SimParams.txt';

    % Determine the output path for the log file
    if nargin < 3 || isempty(logFilePath)
        paramfilepath = fullfile(pwd, logFileName);
    else
        paramfilepath = fullfile(logFilePath, logFileName);
    end

    % Capture printed parameters as a string using a function handle
    %outputStr = evalc('internal_print(args, argsICD);');
    [outputStr, args, argsICD] = internal_print(args, argsICD);
    %[outputStr, args, argsICD] = internal_print(args, argsICD);


    % Attempt to write the captured string to file
    fid = fopen(paramfilepath, 'w');
    if fid == -1
        warning('Could not open log file: %s', paramfilepath);
    else
        fwrite(fid, outputStr);
        fclose(fid);
        fprintf('Simulation parameters saved to text log: %s\n', paramfilepath);
    end
    
    %Save the parameters to the main folder:
    save('SimParam.mat', 'args');
    save("ICDparam.mat", 'argsICD');

end

function [outStr, args, argsICD] = internal_print(args, argsICD)
    outStr = evalc('print_params(args, argsICD)');
end

function print_params(args, argsICD)
% Print simulation parameters (args) and ICD parameters (argsICD) to console and return as string

disp('#### Simulation Parameter Values ####');

fprintf('\n--- EGM Information ---\n');
fprintf('EGM Name: %s\n', args.EGM_name);
fprintf('EGM Features Name: %s\n', args.EGM_features_name);

fprintf('\n--- ATP Therapy Parameters ---\n');
fprintf('Burst Only Flag: %f \n', args.Burst_only);
fprintf('ATP Strength: %.2f uA/cm^2\n', args.ATP_strength);
fprintf('ATP Duration: %.2f ms\n', args.ATP_duration);
fprintf('ATP Stimsite: %s\n', args.ATP_stimsite);
fprintf('ATP Min Cycle Length: %.2f ms\n', args.ATP_Min_Cycle);

fprintf('\n--- ATP Therapy Parameters: VT1 Zone---\n');
fprintf('ATP Cycle Length: %.2f % \n', args.VT1_ATP_CL);
fprintf('ATP Coupling Interval: %.2f % \n', args.VT1_ATP_coupling);
fprintf('ATP Pulses: %.2f\n', args.VT1_ATP_pls);
fprintf('ATP Cycle Length Decrement: %.2f ms\n', args.VT1_ATP_dec);

fprintf('\n--- ATP Therapy Parameters: VT Zone---\n');
fprintf('ATP Cycle Length: %.2f % \n', args.VT_ATP_CL);
fprintf('ATP Coupling Interval: %.2f % \n', args.VT_ATP_coupling);
fprintf('ATP Pulses: %.2f\n', args.VT_ATP_pls);
fprintf('ATP Cycle Length Decrement: %.2f ms\n', args.VT_ATP_dec);


fprintf('\n--- Quick Convert ATP Therapy Parameters ( Non - Programmable!) ---\n');
fprintf('QC ATP Cycle Length: %.2f uA/cm^2\n', args.QC_ATP_CL);
fprintf('QC ATP Coupling Interval: %.2f uA/cm^2\n', args.QC_ATP_coupling);
fprintf('QC ATP Pulse: %.2f uA/cm^2\n', args.QC_ATP_pls);

fprintf('\n--- Mesh and Region Information ---\n');
fprintf('Mesh Name: %s\n', args.mesh);
fprintf('Myocardium Region Tag: %.2f\n', args.myocardium);
fprintf('Scar Flag: %.2f\n', args.scar_flag);
fprintf('Scar Region Tag: %.2f\n', args.scar_region);
fprintf('Isthmus Region Tag: %.2f\n', args.isthmus_region);
fprintf('Conductivity Multiplier for the Isthmus: %.2f\n', args.conmul);

fprintf('\n--- Additional Simulation Parameters ---\n');
fprintf('Input State: %s\n', args.input_state);
fprintf('Cell Model: %s\n', args.model);
fprintf('BCL for NSR: %.2f\n', args.bcl);
fprintf('Strength for NSR: %.2f uA/cm^2\n', args.strength);
fprintf('Duration for NSR: %.2f ms\n', args.duration);
fprintf('Start for NSR: %.2f ms\n', args.start);
fprintf('NSR Template: %s\n', args.EGM_template);
fprintf('NSR VTX: %s\n', args.NSR_vtx);
fprintf('Electrodes Points File: %s\n', args.electrodes);
fprintf('Output Resolution: %.2f\n', args.output_res);
fprintf('Checkpoint for saving simulation state: %.2f ms\n', args.check);

fprintf('\n--- Therapy Call Limits ---\n');
fprintf('Max Therapy Calls [VT1, VT, VF]: %s\n', mat2str(args.max_therapy_calls));

fprintf('\n### ICD Parameters ###\n');
fprintf('\n--- ICD Therapy Zone Thresholds ---\n');
fprintf('QC Override Threshold: %.2f ms\n', argsICD.QC_Override_th);
fprintf('VF Threshold: %.2f ms\n', argsICD.VF_th);
fprintf('VT Threshold: %.2f ms\n', argsICD.VT_th);
fprintf('VT-1 Threshold: %.2f ms\n', argsICD.VT_1_th);

fprintf('\n--- Episode Duration Parameters ---\n');
fprintf('VF Duration: %.2f ms\n', argsICD.VF_dur);
fprintf('VT Duration: %.2f ms\n', argsICD.VT_dur);
fprintf('VT-1 Duration: %.2f ms\n', argsICD.VT_1_dur);

fprintf('\n--- RhythmID Parameters ---\n');
fprintf('VTC Correlation Threshold: %.2f\n', argsICD.VTC_corr_th);
fprintf('AFib Threshold: %.2f ms\n', argsICD.Afib_th);
fprintf('Stability Count: %.2f\n', argsICD.stab);

fprintf('\n--- Redetection Durations ---\n');
fprintf('VF Redetection Duration: %.2f ms\n', argsICD.VF_red_dur);
fprintf('VT Redetection Duration: %.2f ms\n', argsICD.VT_red_dur);
fprintf('VT-1 Redetection Duration: %.2f ms\n', argsICD.VT_1red_dur);

fprintf('\n--- End of Episode Timers ---\n');
fprintf('EoE Timer (Non-Therapy): %.2f ms\n', argsICD.EoE_timer_NT_dur);
fprintf('EoE Timer (ATP): %.2f ms\n', argsICD.EoE_timer_ATP_dur);

fprintf('\n--- ATP Timeout Durations ---\n');
fprintf('VT ATP Timeout: %.2f ms\n', argsICD.VT_ATP_TO);
fprintf('VT-1 ATP Timeout: %.2f ms\n', argsICD.VT_1_ATP_TO);

fprintf('\n------------------------\n\n');



end
