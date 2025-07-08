function FullEGMArray = load_EGMs(targetDir, EGM_name)
% Loads .mat files for EGM processing in proper order, placing the init file first.

    % 1. Load the initial episode file (e.g., 'EGM_reentrant_VT.mat')
    init_file = dir(fullfile(targetDir, [EGM_name, '*.mat']));
    if isempty(init_file)
        error('Initial EGM file not found: %s*.mat', EGM_name);
    end
    % disp("Loading initial file:");
    % disp(init_file.name)
    init_struct = load_struct_from_file(init_file(1));

    % 2. Load ATP therapy episode files (e.g., 'EGM_ATP_1.mat', 'EGM_ATP_2.mat')
    atp_files = dir(fullfile(targetDir, 'EGM_ATP_*.mat'));
    % disp("ATP files:");
    % disp({atp_files.name})

    % 3. Load post-therapy redetect files (e.g., 'EGM_post_therapy_1.mat')
    redetect_files = dir(fullfile(targetDir, ['EGM_post_therapy_','*.mat']));
    % disp("Redetect files:");
    % disp({redetect_files.name})

    % Combine ATP and redetect
    other_files = [atp_files; redetect_files];

    % Extract meaningful numeric values from filenames
    fileNums = zeros(1, length(other_files));
    for i = 1:length(other_files)
        fname = other_files(i).name;

        % Extract number after known prefixes
        % Try ATP_###.mat or ATP_end_###.roe.mat
        match = regexp(fname, 'ATP(?:_end)?_(\d+\.?\d*)', 'tokens');

        if ~isempty(match)
            fileNums(i) = str2double(match{1}{1});
        else
            warning('No valid numeric identifier found in file: %s', fname);
            fileNums(i) = inf; % Push unmatched files to end
        end
    end

    % Sort by the extracted number
    [~, sortIdx] = sort(fileNums);
    sorted_files = other_files(sortIdx);
    % fprintf("\nSorted files by numeric key:\n")
    % for i = 1:length(sorted_files)
    %     fprintf("%2d: %s [%.4f]\n", i, sorted_files(i).name, fileNums(sortIdx(i)));
    % end

    % Load all files into FullEGMArray
    FullEGMArray = cell(1, 1 + length(sorted_files));
    FullEGMArray{1} = init_struct;  % First file is always init

    for i = 1:length(sorted_files)
        FullEGMArray{i + 1} = load_struct_from_file(sorted_files(i));
    end
end

function s = load_struct_from_file(file)
% Helper function to load the only structure in a .mat file
    data = load(fullfile(file.folder, file.name));
    fn = fieldnames(data);
    s = data.(fn{1});
end
