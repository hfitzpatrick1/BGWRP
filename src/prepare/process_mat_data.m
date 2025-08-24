function success = process_mat_data(input_directory, output_filename, decimation_factor)
%PROCESS_MAT_DATA Integrated MAT file processing (concatenation + downsampling)
%
% Main function that orchestrates the complete MAT file processing pipeline:
% 1. Concatenate MAT files
% 2. Apply downsampling (if requested)
% 3. Save result with appropriate variable name
%
% This replaces both concatenate_configurable.m and concatenate_and_downsample.m
%
% Inputs:
%   input_directory   - Directory containing MAT files to process
%   output_filename   - Full path for output file
%   decimation_factor - Decimation factor (1 = no decimation)
%
% Outputs:
%   success          - true if successful, false otherwise

fprintf('=== MAT DATA PROCESSING PIPELINE ===\n');
fprintf('Input directory: %s\n', input_directory);
fprintf('Output file: %s\n', output_filename);
fprintf('Decimation factor: %d\n', decimation_factor);

success = false;

try
    % STEP 1: Concatenate MAT files
    [concatenated_data, concat_success] = concatenate_mat(input_directory);
    if ~concat_success
        error('Concatenation failed');
    end
    
    % STEP 2: Apply downsampling
    [processed_data, downsample_success] = downsample_mat(concatenated_data, decimation_factor);
    if ~downsample_success
        error('Downsampling failed');
    end
    
    % Clear concatenated data to free memory
    clear concatenated_data;
    
    % STEP 3: Save result with appropriate variable name
    fprintf('\n=== SAVING PROCESSED DATA ===\n');
    
    % Ensure output directory exists
    output_dir = fileparts(output_filename);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    if decimation_factor == 1
        % Save as full-resolution data
        fulldata = processed_data;
        fprintf('Saving full-resolution data: %s\n', output_filename);
        save(output_filename, 'fulldata', '-v7.3');
        clear fulldata;
    else
        % Save as decimated data (maintain compatibility)
        decdata = processed_data;
        fprintf('Saving decimated data: %s\n', output_filename);
        save(output_filename, 'decdata', '-v7.3');
        clear decdata;
    end
    
    % Verify file was created and report size
    if exist(output_filename, 'file')
        file_info = dir(output_filename);
        fprintf('✓ Success! File saved: %.1f MB\n', file_info.bytes / 1024 / 1024);
        success = true;
    else
        error('Output file was not created');
    end
    
catch ME
    fprintf('✗ Processing failed: %s\n', ME.message);
    success = false;
end

fprintf('=== PROCESSING COMPLETE ===\n\n');

end
