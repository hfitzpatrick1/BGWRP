function success = concatenate_and_downsample(input_directory, output_filename, decimation_factor)
%CONCATENATE_AND_DOWNSAMPLE Modern function version of ConcatDownsample
%
% Inputs:
%   input_directory   - Directory containing MAT files to concatenate
%   output_filename   - Name of output file (e.g., 'Dataset_a_1Hz.mat')
%   decimation_factor - Decimation factor (e.g., 100)
%
% Outputs:
%   success          - true if successful, false otherwise

fprintf('Starting concatenation and downsampling...\n');
fprintf('  Input directory: %s\n', input_directory);
fprintf('  Output file: %s\n', output_filename);
fprintf('  Decimation factor: %d\n', decimation_factor);

success = false;

try
    % Validate inputs
    if ~exist(input_directory, 'dir')
        error('Input directory does not exist: %s', input_directory);
    end
    
    % Find MAT files
    files = dir(fullfile(input_directory, '*.mat'));
    if isempty(files)
        error('No MAT files found in directory: %s', input_directory);
    end
    
    fprintf('Found %d MAT files to process\n', length(files));
    
    % Initialize variables
    decdata = [];
    lastNC = [];
    
    % Process each file
    for nn = 1:length(files)
        fprintf('Processing file %d of %d: %s\n', nn, length(files), files(nn).name);
        
        % Extract timestamp for sorting (optional - files should already be sorted)
        filename = files(nn).name;
        try
            StartTime = extractBetween(filename, "UTC_", ".mat");
            StartTime = StartTime{1};
        catch
            StartTime = sprintf('File_%03d', nn);
        end
        
        % Load data
        file_path = fullfile(input_directory, filename);
        loaded_data = load(file_path);
        
        % Get the data variable (assuming it's named 'data')
        if isfield(loaded_data, 'data')
            data2 = loaded_data.data;
        else
            % Try to find the largest numeric array
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
            data2 = loaded_data.(largest_field);
        end
        
        fprintf('  Data size: [%d x %d]\n', size(data2, 1), size(data2, 2));
        
        % Check channel consistency
        if isempty(lastNC)
            lastNC = size(data2, 2);
        elseif size(data2, 2) ~= lastNC
            fprintf('  WARNING: Skipping file with different channel count: %d vs %d\n', size(data2, 2), lastNC);
            continue;
        end
        
        % Decimate each channel
        decmat = zeros(ceil(size(data2, 1) / decimation_factor), size(data2, 2));
        for n = 1:size(data2, 2)
            if mod(n, 100) == 0
                fprintf('    Decimating channel %d of %d\n', n, size(data2, 2));
            end
            decmat(:, n) = decimate(data2(:, n), decimation_factor);
        end
        
        % Concatenate
        decdata = [decdata; decmat];
        
        fprintf('  Decimated size: [%d x %d], Total size: [%d x %d]\n', ...
            size(decmat, 1), size(decmat, 2), size(decdata, 1), size(decdata, 2));
    end
    
    % Save result
    fprintf('Saving concatenated data: %s\n', output_filename);
    save(output_filename, 'decdata', '-v7.3');
    
    % Verify file was created
    if exist(output_filename, 'file')
        file_info = dir(output_filename);
        fprintf('Success! File saved: %.1f MB\n', file_info.bytes / 1024 / 1024);
        success = true;
    else
        error('Output file was not created');
    end
    
catch ME
    fprintf('Error during concatenation: %s\n', ME.message);
    success = false;
end

end
