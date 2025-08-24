function success = concatenate_configurable(input_directory, output_filename, decimation_factor)
%CONCATENATE_CONFIGURABLE Configurable concatenation with validation
%
% Enhanced version of concatenate_and_downsample with:
% - Configurable decimation (including no decimation)
% - Data quality validation
% - Appropriate warnings for decimation factors
%
% Inputs:
%   input_directory   - Directory containing MAT files to concatenate
%   output_filename   - Name of output file
%   decimation_factor - Decimation factor (1 = no decimation, 100 = standard)
%
% Outputs:
%   success          - true if successful, false otherwise

fprintf('Starting configurable concatenation...\n');
fprintf('  Input directory: %s\n', input_directory);
fprintf('  Output file: %s\n', output_filename);
fprintf('  Decimation factor: %d\n', decimation_factor);

success = false;

try
    % Validate decimation factor
    validate_decimation_factor(decimation_factor);
    
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
    rawdata = [];
    lastNC = [];
    
    % STEP 1: Load and concatenate all raw data first
    fprintf('\n=== STEP 1: LOADING AND CONCATENATING RAW DATA ===\n');
    for nn = 1:length(files)
        fprintf('Loading file %d of %d: %s\n', nn, length(files), files(nn).name);
        
        % Load data
        filename = files(nn).name;
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
        
        % Concatenate raw data (no decimation yet)
        rawdata = [rawdata; data2];
        
        fprintf('  Raw concatenated size: [%d x %d]\n', size(rawdata, 1), size(rawdata, 2));
    end
    
    % STEP 2: Apply decimation (or not)
    if decimation_factor == 1
        fprintf('\n=== STEP 2: NO DECIMATION (PRESERVING FULL RESOLUTION) ===\n');
        fprintf('Full dataset size: [%d x %d]\n', size(rawdata, 1), size(rawdata, 2));
        
        % No decimation - just use raw data
        finaldata = rawdata;
        
        fprintf('Final output size: [%d x %d]\n', size(finaldata, 1), size(finaldata, 2));
        
    else
        fprintf('\n=== STEP 2: DECIMATING ENTIRE DATASET ===\n');
        fprintf('Full raw dataset size: [%d x %d]\n', size(rawdata, 1), size(rawdata, 2));
        fprintf('Decimating by factor %d...\n', decimation_factor);
        
        % Initialize decimated data array
        finaldata = zeros(ceil(size(rawdata, 1) / decimation_factor), size(rawdata, 2));
        
        % Decimate each channel of the full concatenated dataset
        for n = 1:size(rawdata, 2)
            if mod(n, 100) == 0
                fprintf('  Decimating channel %d of %d\n', n, size(rawdata, 2));
            end
            finaldata(:, n) = decimate(rawdata(:, n), decimation_factor);
        end
        
        % DEBUG: Check final decimated data quality
        fprintf('Final decimated size: [%d x %d]\n', size(finaldata, 1), size(finaldata, 2));
        fprintf('DEBUG: Final data range: [%.6f, %.6f]\n', min(finaldata(:)), max(finaldata(:)));
        final_nan_count = sum(isnan(finaldata(:)));
        fprintf('DEBUG: NaN values in final data: %d out of %d (%.1f%%)\n', final_nan_count, numel(finaldata), (final_nan_count/numel(finaldata))*100);
    end
    
    % Clear raw data to free memory
    clear rawdata;
    
    % Save result with appropriate variable name (clean save - only data variable)
    if decimation_factor == 1
        % Save as full-resolution data
        fulldata = finaldata;
        fprintf('Saving full-resolution data: %s\n', output_filename);
        save(output_filename, 'fulldata', '-v7.3');
    else
        % Save as decimated data (maintain compatibility)
        decdata = finaldata;
        fprintf('Saving decimated data: %s\n', output_filename);
        save(output_filename, 'decdata', '-v7.3');
    end
    
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

function validate_decimation_factor(decimation_factor)
%VALIDATE_DECIMATION_FACTOR Check if decimation factor is appropriate

% Assuming source data is 100 Hz based on TDMS analysis
source_sampling_rate = 100; % Hz
source_nyquist = source_sampling_rate / 2;

% Calculate target sampling rate and Nyquist
target_sampling_rate = source_sampling_rate / decimation_factor;
target_nyquist = target_sampling_rate / 2;

fprintf('\n=== DECIMATION VALIDATION ===\n');
fprintf('Source sampling rate: %.1f Hz (Nyquist: %.1f Hz)\n', source_sampling_rate, source_nyquist);
fprintf('Target sampling rate: %.1f Hz (Nyquist: %.1f Hz)\n', target_sampling_rate, target_nyquist);

% Validation checks
if decimation_factor < 1
    error('Decimation factor must be >= 1');
elseif decimation_factor == 1
    fprintf('✓ No decimation - preserving full 100 Hz resolution\n');
    fprintf('  Final Nyquist: %.1f Hz (preserves all signal content)\n', target_nyquist);
elseif decimation_factor <= 5
    fprintf('✓ Light decimation - good for preserving signal dynamics\n');
    fprintf('  Final Nyquist: %.1f Hz (preserves most signal content)\n', target_nyquist);
elseif decimation_factor <= 20
    fprintf('⚠ Medium decimation - adequate for slower phenomena\n');
    fprintf('  Final Nyquist: %.1f Hz (may lose some signal content)\n', target_nyquist);
elseif decimation_factor <= 50
    fprintf('⚠ Heavy decimation - only slow phenomena preserved\n');
    fprintf('  Final Nyquist: %.1f Hz (significant signal loss)\n', target_nyquist);
elseif decimation_factor <= 100
    fprintf('⚠ Very heavy decimation - only very slow phenomena\n');
    fprintf('  Final Nyquist: %.1f Hz (major signal loss)\n', target_nyquist);
else
    fprintf('⚠ Extreme decimation - most signal content lost\n');
    fprintf('  Final Nyquist: %.3f Hz (extreme signal loss)\n', target_nyquist);
    warning('Decimation factor %d may be too aggressive. Consider smaller values.', decimation_factor);
end

% Check for common problematic values
if mod(decimation_factor, 2) ~= 0 && decimation_factor > 1
    fprintf('ℹ Note: Odd decimation factors may cause phase distortion\n');
end

if decimation_factor > 200
    warning('Decimation factor > 200 is likely excessive for DAS data');
end

fprintf('=============================\n\n');

end
