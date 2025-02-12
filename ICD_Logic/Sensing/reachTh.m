function [VT1, VT, VF] = reachTh(therapy_sig)
    % reachTh: Determine if any of the therapy signals exceed their thresholds.
    %
    % Parameters:
    % therapy_sig - A matrix where each column corresponds to a different therapy zone.
    %               Column 1: VT1 therapy signals
    %               Column 2: VT therapy signals
    %               Column 3: VF therapy signals
    % Returns:
    % VT1 - Therapy counter value for VT1
    % VT  - Therapy counter value for VT
    % VF  - Therapy counter value for VF
    
    % Check if therapy_sig is a non-empty matrix with at least 3 columns
    if isempty(therapy_sig) || size(therapy_sig, 2) < 3
        error('Invalid input: therapy_sig must be a non-empty matrix with at least 3 columns.');
    end
    
    % Calculate if thresholds were reached for each therapy zone
    VT1 = therapy_sig(:, 1);
    VT = therapy_sig(:, 2);
    VF = therapy_sig(:, 3);
end
