function FullEGM = full_egm_construction(structArray, order)
% combine_clean_mat_structs - Cleans and concatenates multiple .mat structs.
%
% Inputs:
%   structArray - A cell array of structures (each with VSigRaw, Shock, RVin)
%   order       - An array of indices indicating the desired order of concatenation
%
% Output:
%   FullEGM      - Structure with concatenated and cleaned VSigRaw, Shock, RVin fields

    % Initialize empty FullEGM structure
    FullEGM.VSigRaw = [];
    FullEGM.Shock = [];
    FullEGM.RVin = [];

    for i = 1:length(order)
        idx = order(i);
        s = structArray{idx};

        % Clean each signal by removing redundant rows
        data = [s.VSigRaw(:), s.Shock(:), s.RVin(:)];  % ensure columns
        changeMask = [true; any(diff(data), 2)];       % keep first row and any changes

        % Append to FullEGM
        FullEGM.VSigRaw = [FullEGM.VSigRaw; data(changeMask, 1)];
        FullEGM.Shock   = [FullEGM.Shock;   data(changeMask, 2)];
        FullEGM.RVin    = [FullEGM.RVin;    data(changeMask, 3)];
    end
end
