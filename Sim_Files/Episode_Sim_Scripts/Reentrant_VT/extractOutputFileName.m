function outputFile = extractOutputFileName(cmdout)
    % Custom function to parse the Python script output and find the output file name
    % This is an example and may need adjustments based on how the Python script outputs the filename
    lines = strsplit(cmdout, '\n');
    outputFile = '';
    for i = 1:length(lines)
        if contains(lines{i}, 'Output file:')
            outputFile = strtrim(strrep(lines{i}, 'Output file:', ''));
            break;
        end
    end
end
