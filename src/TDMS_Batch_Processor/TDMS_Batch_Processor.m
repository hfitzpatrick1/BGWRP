%% TDMS Batch Processing Pipeline
% This script performs complete TDMS to analysis-ready data workflow:
% 1. Converts TDMS files to individual MAT files with physical units
% 2. Concatenates and downsamples to create final 1Hz datasets
% 3. Extracts timing configuration from filenames
%
% Input: TDMS files organized in subdirectories
% Output: Final 1Hz MAT files + timing configuration

clear all;
fprintf('=== TDMS BATCH PROCESSING PIPELINE ===\n');

%% Setup paths
script_dir = fileparts(mfilename('fullpath'));
util_dir = fullfile(script_dir, 'util');
addpath(util_dir);
fprintf('Added util directory to path: %s\n', util_dir);

%% Configuration Setup
% Create configuration struct (can be overridden by input parameters)
if ~exist('config', 'var')
    config = struct();
end

% Set defaults
if ~isfield(config, 'base_input')
    config.base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';
end
if ~isfield(config, 'test_directories')
    config.test_directories = {'PT01a_Recovery', 'PT01b_Recovery', 'PT01c_Recovery'};
end
if ~isfield(config, 'test_labels')
    config.test_labels = {'a', 'b', 'c'};
end
if ~isfield(config, 'run_tdms_conversion')
    config.run_tdms_conversion = false;  % DEFAULT: SKIP
end
if ~isfield(config, 'run_concatenation')
    config.run_concatenation = true;     % DEFAULT: ENABLED
end
if ~isfield(config, 'run_timing_extraction')
    config.run_timing_extraction = true; % DEFAULT: ENABLED
end
if ~isfield(config, 'decimation_factor')
    config.decimation_factor = 100;      % DEFAULT: 100x decimation
end

fprintf('Processing stages enabled:\n');
if config.run_tdms_conversion
    fprintf('  TDMS Conversion: ENABLED\n');
else
    fprintf('  TDMS Conversion: DISABLED\n');
end
if config.run_concatenation
    fprintf('  Concatenation: ENABLED\n');
else
    fprintf('  Concatenation: DISABLED\n');
end
if config.run_timing_extraction
    fprintf('  Timing Extraction: ENABLED\n');
else
    fprintf('  Timing Extraction: DISABLED\n');
end

%% Step 1: Convert TDMS to individual MAT files
if config.run_tdms_conversion
    fprintf('\n=== STEP 1: TDMS TO MAT CONVERSION ===\n');
    
    for i = 1:length(config.test_directories)
        current_test = config.test_directories{i};
        fprintf('\n--- Processing %s ---\n', current_test);
        
        % Set parameters for Silixa script (store in config to avoid clearing)
        config.silixa.directory = [config.base_input current_test '\'];
        config.silixa.filesearch = '*.tdms';
        config.silixa.fileindex = [];
        config.silixa.save_data = 1;
        config.silixa.save_directory = config.base_input;
        
        % Extract for script compatibility
        directory = config.silixa.directory;
        filesearch = config.silixa.filesearch;
        fileindex = config.silixa.fileindex;
        save_data = config.silixa.save_data;
        save_directory = config.silixa.save_directory;
    
    % Verify input directory exists
    if ~exist(directory, 'dir')
        fprintf('⚠ Directory not found: %s\n', directory);
        continue;
    end
    
    % Check files
    files = dir([directory filesearch]);
    fprintf('Found %d TDMS files\n', length(files));
    if length(files) == 0
        fprintf('⚠ No TDMS files found, skipping\n');
        continue;
    end
    
    % Run TDMS conversion
    try
        run(fullfile(util_dir, 'Silixa_TDMSDataToPhysicalDispRate.m'));
        fprintf('✓ TDMS conversion completed for %s\n', test_directories{i});
    catch ME
        fprintf('✗ TDMS conversion failed for %s: %s\n', test_directories{i}, ME.message);
    end
    end
else
    fprintf('\n=== STEP 1: SKIPPED (TDMS conversion disabled) ===\n');
end

%% Step 2: Concatenate and downsample individual MAT files
if config.run_concatenation
    fprintf('\n=== STEP 2: CONCATENATION AND DOWNSAMPLING ===\n');

% Store config values locally before loop to survive clear statements
local_test_directories = config.test_directories;
local_test_labels = config.test_labels;
local_base_input = config.base_input;
local_decimation_factor = config.decimation_factor;

for i = 1:length(local_test_directories)
    current_test_dir = local_test_directories{i};
    fprintf('\n--- Concatenating %s ---\n', current_test_dir);
    
    % Set parameters for ConcatDownsample script
    mat_directory = [local_base_input current_test_dir '_mat\'];
    directory = mat_directory;  % ConcatDownsample expects 'directory' variable
    filesearch = '*.mat';
    r = local_decimation_factor;  % Use config decimation factor
    
    % Output filename
    outname = sprintf('Dataset_%s_1Hz.mat', local_test_labels{i});
    
    % Verify MAT directory exists
    if ~exist(mat_directory, 'dir')
        fprintf('⚠ MAT directory not found: %s\n', mat_directory);
        continue;
    end
    
    % Check MAT files
    files = dir([mat_directory filesearch]);
    fprintf('Found %d MAT files to concatenate\n', length(files));
    if length(files) == 0
        fprintf('⚠ No MAT files found, skipping\n');
        continue;
    end
    
    % Run concatenation
    try
        run(fullfile(util_dir, 'ConcatDownsample.m'));
        fprintf('✓ Concatenation completed: %s\n', outname);
    catch ME
        fprintf('✗ Concatenation failed for test %d: %s\n', i, ME.message);
    end
end
else
    fprintf('\n=== STEP 2: SKIPPED (Concatenation disabled) ===\n');
end

%% Step 3: Extract timing configuration
if config.run_timing_extraction
    fprintf('\n=== STEP 3: EXTRACTING TIMING CONFIGURATION ===\n');

timing_config = struct();

for i = 1:length(config.test_directories)
    test_label = config.test_labels{i};
    tdms_directory = [config.base_input config.test_directories{i} '\'];
    
    fprintf('Extracting timing for dataset %s...\n', test_label);
    
    if exist(tdms_directory, 'dir')
        % Find first TDMS file to extract start time
        tdms_files = dir([tdms_directory '*.tdms']);
        if ~isempty(tdms_files)
            first_file = tdms_files(1).name;
            
            % Extract timestamp from filename
            % Generic pattern for UTC timestamps in filenames
            timestamp_match = regexp(first_file, 'UTC_(\d{8}_\d{6}\.\d{3})', 'tokens');
            if ~isempty(timestamp_match)
                timestamp_str = timestamp_match{1}{1};
                
                % Parse timestamp
                try
                    % Format: YYYYMMDD_HHMMSS.mmm
                    year = str2double(timestamp_str(1:4));
                    month = str2double(timestamp_str(5:6));
                    day = str2double(timestamp_str(7:8));
                    hour = str2double(timestamp_str(10:11));
                    minute = str2double(timestamp_str(12:13));
                    second = str2double(timestamp_str(14:15));
                    millisecond = str2double(timestamp_str(17:19));
                    
                    start_time = datetime(year, month, day, hour, minute, second, millisecond, 'TimeZone', 'UTC');
                    
                    timing_config.(test_label).start = start_time;
                    timing_config.(test_label).first_file = first_file;
                    timing_config.(test_label).source = 'extracted_from_filename';
                    timing_config.(test_label).num_files = length(tdms_files);
                    
                    fprintf('  ✓ Start time: %s (from %s)\n', start_time, first_file);
                    
                    % Calculate end time (approximate)
                    last_file = tdms_files(end).name;
                    last_timestamp_match = regexp(last_file, 'UTC_(\d{8}_\d{6}\.\d{3})', 'tokens');
                    if ~isempty(last_timestamp_match)
                        last_timestamp_str = last_timestamp_match{1}{1};
                        last_year = str2double(last_timestamp_str(1:4));
                        last_month = str2double(last_timestamp_str(5:6));
                        last_day = str2double(last_timestamp_str(7:8));
                        last_hour = str2double(last_timestamp_str(10:11));
                        last_minute = str2double(last_timestamp_str(12:13));
                        last_second = str2double(last_timestamp_str(14:15));
                        last_millisecond = str2double(last_timestamp_str(17:19));
                        
                        end_time = datetime(last_year, last_month, last_day, last_hour, last_minute, last_second, last_millisecond, 'TimeZone', 'UTC');
                        timing_config.(test_label).end = end_time;
                        timing_config.(test_label).duration_minutes = minutes(end_time - start_time);
                        
                        fprintf('  ✓ End time: %s (%.1f minutes)\n', end_time, timing_config.(test_label).duration_minutes);
                    end
                    
                catch
                    fprintf('  ⚠ Could not parse timestamp: %s\n', timestamp_str);
                end
            else
                fprintf('  ⚠ No timestamp found in filename: %s\n', first_file);
            end
        else
            fprintf('  ⚠ No TDMS files found in %s\n', tdms_directory);
        end
    else
        fprintf('  ⚠ Directory not found: %s\n', tdms_directory);
    end
end

%% Step 4: Save timing configuration
fprintf('\n=== STEP 4: SAVING CONFIGURATION ===\n');

config_file = [config.base_input 'Batch_Timing_Config.mat'];
save(config_file, 'timing_config');
fprintf('✓ Timing configuration saved: %s\n', config_file);

% Display configuration summary
fprintf('\n=== EXTRACTED TIMING CONFIGURATION ===\n');
for i = 1:length(config.test_labels)
    test_label = config.test_labels{i};
    if isfield(timing_config, test_label)
        config = timing_config.(test_label);
        fprintf('Dataset %s:\n', upper(test_label));
        fprintf('  Start: %s\n', config.start);
        if isfield(config, 'end')
            fprintf('  End: %s\n', config.end);
            fprintf('  Duration: %.1f minutes\n', config.duration_minutes);
        end
        fprintf('  Files: %d\n', config.num_files);
        fprintf('  Source: %s\n', config.source);
    end
end

%% Final Summary
fprintf('\n=== BATCH PROCESSING COMPLETE ===\n');
fprintf('Final outputs:\n');
for i = 1:length(config.test_labels)
    final_file = sprintf('Dataset_%s_1Hz.mat', config.test_labels{i});
    if exist([config.base_input final_file], 'file')
        fprintf('  ✓ %s\n', final_file);
    else
        fprintf('  ✗ %s (not created)\n', final_file);
    end
end
    if config.run_timing_extraction
        fprintf('  ✓ Batch_Timing_Config.mat\n');
    end
    fprintf('\nReady for analysis!\n');
else
    fprintf('\n=== STEP 3: SKIPPED (Timing extraction disabled) ===\n');
end
