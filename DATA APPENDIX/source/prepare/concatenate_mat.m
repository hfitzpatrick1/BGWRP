function [concatenated_data, success] = concatenate_mat(input_directory)
%CONCATENATE_MAT Concatenate MAT files into single dataset
%
% Pure concatenation function - handles only loading and concatenating
% MAT files. No decimation or other processing.
%
% Inputs:
%   input_directory - Directory containing MAT files to concatenate
%
% Outputs:
%   concatenated_data - Combined data matrix [time x channels]
%   success          - true if successful, false otherwise

console_log('=== CONCATENATING MAT FILES ===\n');
console_log('Input directory: %s\n', input_directory);

success = false;
concatenated_data = [];

try
    % Validate input directory
    if ~exist(input_directory, 'dir')
        error('Input directory does not exist: %s', input_directory);
    end
    
    % Find MAT files
    files = dir(fullfile(input_directory, '*.mat'));
    if isempty(files)
        error('No MAT files found in directory: %s', input_directory);
    end
    
    console_log('Found %d MAT files to concatenate\n', length(files));
    
    % Initialize variables
    rawdata = [];
    expected_channels = [];
    
    % Load and concatenate all files
    for nn = 1:length(files)
        if mod(nn, 5) == 1 || nn == length(files)  % Show every 5th file + last
            console_log('Loading file %d of %d: %s\n', nn, length(files), files(nn).name);
        end
        
        % Load data
        filename = files(nn).name;
        file_path = fullfile(input_directory, filename);
        loaded_data = load(file_path);
        
        % Get the data variable (try 'data' first, then largest numeric array)
        if isfield(loaded_data, 'data')
            file_data = loaded_data.data;
        else
            % Find the largest numeric array
            field_names = fieldnames(loaded_data);
            largest_field = '';
            largest_size = 0;
            for i = 1:length(field_names)
                field_data = loaded_data.(field_names{i});
                if isnumeric(field_data) && numel(field_data) > largest_size
                    largest_size = numel(field_data);
                    largest_field = field_names{i};
                end
            end
            if isempty(largest_field)
                error('No numeric data found in file: %s', filename);
            end
            file_data = loaded_data.(largest_field);
        end
        
        if mod(nn, 5) == 1 || nn == length(files)  % Show details for same files
            console_log('  Data size: [%d x %d]\n', size(file_data, 1), size(file_data, 2));
        end
        
        % Check channel consistency
        if isempty(expected_channels)
            expected_channels = size(file_data, 2);
        elseif size(file_data, 2) ~= expected_channels
            console_log('  WARNING: Skipping file with different channel count: %d vs %d\n', ...
                    size(file_data, 2), expected_channels);
            continue;
        end
        
        % Concatenate data
        rawdata = [rawdata; file_data];
        
        if mod(nn, 5) == 1 || nn == length(files)  % Show progress for same files
            console_log('  Concatenated size: [%d x %d]\n', size(rawdata, 1), size(rawdata, 2));
        end
    end
    
    % Final validation
    if isempty(rawdata)
        error('No valid data files were concatenated');
    end
    
    concatenated_data = rawdata;
    success = true;
    
    console_log('✓ Concatenation complete: [%d x %d]\n', size(concatenated_data, 1), size(concatenated_data, 2));
    
catch ME
    console_log('✗ Error during concatenation: %s\n', ME.message);
    success = false;
    concatenated_data = [];
end

end
