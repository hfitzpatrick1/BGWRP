%% TDMS Batch Processing Pipeline
% This script performs complete TDMS to analysis-ready data workflow:
% 1. Converts TDMS files to individual MAT files with physical units
% 2. Concatenates and downsamples to create final 1Hz datasets
% 3. Extracts timing configuration from filenames
%
% Input: TDMS files organized in subdirectories
% Output: Final 1Hz MAT files + timing configuration

% clear all; % REMOVED - this was clearing input config struct!
fprintf('=== TDMS BATCH PROCESSING PIPELINE ===\n');

%% Setup paths
script_dir = fileparts(mfilename('fullpath'));
util_dir = fullfile(script_dir, 'util');
addpath(util_dir);
fprintf('Added util directory to path: %s\n', util_dir);

%% Configuration Setup
% Load config from file first
file_config = load_batch_config();

% Handle shorthand mode parameter
if exist('mode', 'var') && ischar(mode)
    fprintf('Using shorthand mode: %s\n', mode);
    config = file_config; % Start with file config
    
    % Parse mode
    mode_parts = strsplit(lower(mode), '_');
    base_mode = mode_parts{1};
    
    switch base_mode
        case 'prep'
            if length(mode_parts) > 1
                % Specific prep stage
                prep_stage = mode_parts{2};
                config.run_tdms_conversion = strcmp(prep_stage, 'tdms');
                config.run_concatenation = strcmp(prep_stage, 'concat');
                config.run_timing_extraction = false;
                config.run_data_analysis = false;
                config.save_charts = false;
                fprintf('Prep stage: %s\n', prep_stage);
            else
                % Full prep: TDMS conversion + concatenation only
                config.run_tdms_conversion = true;
                config.run_concatenation = true;
                config.run_timing_extraction = false;
                config.run_data_analysis = false;
                config.save_charts = false;
            end
            
        case 'run'
            % Analysis mode: timing + analysis
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = true;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            
        case 'all'
            % Full pipeline
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            
        otherwise
            error('Unknown mode: %s. Valid modes: prep, prep_tdms, prep_concat, run, run_save, all, all_save', mode);
    end
    
    fprintf('Mode "%s" configured\n', mode);
else
    % Use file config as base
    config = file_config;
end

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
    config.run_concatenation = true;     % DEFAULT: ENABLED (only if not set)
else
    % Ensure boolean type (in case it was set as numeric)
    config.run_concatenation = logical(config.run_concatenation);
end
if ~isfield(config, 'run_timing_extraction')
    config.run_timing_extraction = true; % DEFAULT: ENABLED
end
if ~isfield(config, 'decimation_factor')
    config.decimation_factor = 100;      % DEFAULT: 100x decimation
end
if ~isfield(config, 'run_data_analysis')
    config.run_data_analysis = true;     % DEFAULT: ENABLED
end
if ~isfield(config, 'save_charts')
    config.save_charts = false;          % DEFAULT: DISABLED (charts displayed only)
end
if ~isfield(config, 'chart_output_dir')
    config.chart_output_dir = '';        % DEFAULT: Use base_input/analysis_charts
end

%% Workspace Organization
fprintf('\n=== WORKSPACE ORGANIZATION ===\n');
workspace_info = organize_workspace(config.base_input);

fprintf('Processing stages enabled:\n');
if config.run_tdms_conversion
    fprintf('  TDMS Conversion: ENABLED\n');
else
    fprintf('  TDMS Conversion: DISABLED\n');
end
fprintf('DEBUG: config.run_concatenation = %s (type: %s)\n', string(config.run_concatenation), class(config.run_concatenation));
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
if config.run_data_analysis
    fprintf('  Data Analysis: ENABLED\n');
else
    fprintf('  Data Analysis: DISABLED\n');
end
if config.save_charts
    fprintf('  Chart Saving: ENABLED\n');
else
    fprintf('  Chart Saving: DISABLED\n');
end

%% Step 1: Convert TDMS to individual MAT files
if config.run_tdms_conversion
    fprintf('\n=== STEP 1: TDMS TO MAT CONVERSION ===\n');
    
    % Use organized workspace folders
    if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders')
        folders_to_process = workspace_info.input_folders;
    else
        folders_to_process = config.test_directories;
    end
    
    for i = 1:length(folders_to_process)
        current_folder = folders_to_process{i};
        fprintf('\n--- Processing %s ---\n', current_folder);
        
        % Set parameters for Silixa script (store in config to avoid clearing)
        % Read TDMS files from original input directory
        config.silixa.directory = fullfile(config.base_input, current_folder, '\');
        config.silixa.filesearch = '*.tdms';
        config.silixa.fileindex = [];
        config.silixa.save_data = 1;
        % Write MAT files to _tdms_to_mat directory  
        config.silixa.save_directory = fullfile(config.base_input, '_tdms_to_mat', current_folder);
        
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
        fprintf('✓ TDMS conversion completed for %s\n', current_folder);
    catch ME
        fprintf('✗ TDMS conversion failed for %s: %s\n', current_folder, ME.message);
    end
    end
else
    fprintf('\n=== STEP 1: SKIPPED (TDMS conversion disabled) ===\n');
end

%% Step 2: Concatenate and downsample individual MAT files
fprintf('DEBUG: config.run_concatenation = %d\n', config.run_concatenation);
if config.run_concatenation
    fprintf('\n=== STEP 2: CONCATENATION AND DOWNSAMPLING ===\n');

% Store config values locally before loop to survive clear statements
local_test_directories = config.test_directories;
local_test_labels = config.test_labels;
local_base_input = config.base_input;
local_decimation_factor = config.decimation_factor;

% Use the same folders that were processed in TDMS conversion step
if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders')
    folders_to_process = workspace_info.input_folders;
    test_labels_to_use = {};
    for j = 1:length(folders_to_process)
        folder_name = folders_to_process{j};
        if contains(folder_name, 'PT01a') || contains(folder_name, 'a')
            test_labels_to_use{j} = 'a';
        elseif contains(folder_name, 'PT01b') || contains(folder_name, 'b')
            test_labels_to_use{j} = 'b';
        elseif contains(folder_name, 'PT01c') || contains(folder_name, 'c')
            test_labels_to_use{j} = 'c';
        else
            test_labels_to_use{j} = sprintf('test%d', j);
        end
    end
    fprintf('DEBUG: Using workspace folders: %s\n', strjoin(folders_to_process, ', '));
else
    folders_to_process = local_test_directories;
    test_labels_to_use = local_test_labels;
    fprintf('DEBUG: Using config folders: %s\n', strjoin(folders_to_process, ', '));
end

for i = 1:length(folders_to_process)
    current_folder = folders_to_process{i};
    test_label = test_labels_to_use{i};
    fprintf('\n--- Concatenating %s ---\n', current_folder);
    
    % Read from _tdms_to_mat subdirectory
    mat_directory = fullfile(local_base_input, '_tdms_to_mat', current_folder);
    fprintf('DEBUG: Looking for MAT files in: %s\n', mat_directory);
    
    directory = mat_directory;  % ConcatDownsample expects 'directory' variable
    filesearch = '*.mat';
    r = local_decimation_factor;  % Use config decimation factor
    
    % Output to _concatenated directory
    outname = sprintf('Dataset_%s_1Hz.mat', test_label);
    output_file = fullfile(local_base_input, '_concatenated', outname);
    
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
    
    % Run concatenation using modern function
    success = concatenate_and_downsample(mat_directory, output_file, local_decimation_factor);
    
    if success
        fprintf('✓ Concatenation completed: %s\n', outname);
        
        % Copy to _active directory for analysis
        active_output = fullfile(local_base_input, '_active', outname);
        copyfile(output_file, active_output);
        fprintf('✓ Copied to _active: %s\n', outname);
    else
        fprintf('✗ Concatenation failed for %s\n', current_folder);
    end
end
else
    fprintf('\n=== STEP 2: SKIPPED (Concatenation disabled) ===\n');
end

%% Step 3: Extract timing configuration
if config.run_timing_extraction
    fprintf('\n=== STEP 3: EXTRACTING TIMING CONFIGURATION ===\n');

timing_config = struct();

% Use organized workspace info to find input folders
if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders')
    input_folders = workspace_info.input_folders;
else
    % Fallback: scan for input folders
    fprintf('⚠ Workspace info not available, scanning for input folders...\n');
    input_folders = config.test_directories;
end

for i = 1:length(input_folders)
    folder_name = input_folders{i};
    
    % Determine test label from folder name
    if contains(folder_name, 'PT01a') || contains(folder_name, 'a')
        test_label = 'a';
    elseif contains(folder_name, 'PT01b') || contains(folder_name, 'b')
        test_label = 'b';
    elseif contains(folder_name, 'PT01c') || contains(folder_name, 'c')
        test_label = 'c';
    else
        test_label = sprintf('test%d', i);
    end
    
    fprintf('Extracting timing for folder %s (label: %s)...\n', folder_name, test_label);
    
    % Look for TDMS files in original input folder first
    tdms_directory = fullfile(config.base_input, folder_name);
    if ~exist(tdms_directory, 'dir')
        % Try organized workspace location
        tdms_directory = fullfile(config.base_input, '_tdms_to_mat', folder_name);
    end
    
    if exist(tdms_directory, 'dir')
        % Find first TDMS file to extract start time
        tdms_files = dir(fullfile(tdms_directory, '*.tdms'));
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

    % Save to _active directory for analysis to find
    active_dir = fullfile(config.base_input, '_active');
    if ~exist(active_dir, 'dir')
        mkdir(active_dir);
    end

    config_file = fullfile(active_dir, 'Batch_Timing_Config.mat');
    save(config_file, 'timing_config');
    fprintf('✓ Timing configuration saved: %s\n', config_file);

    % Display configuration summary
    fprintf('\n=== EXTRACTED TIMING CONFIGURATION ===\n');
    for i = 1:length(config.test_labels)
        test_label = config.test_labels{i};
        if isfield(timing_config, test_label)
            timing_data = timing_config.(test_label);
            fprintf('Dataset %s:\n', upper(test_label));
            fprintf('  Start: %s\n', timing_data.start);
            if isfield(timing_data, 'end')
                fprintf('  End: %s\n', timing_data.end);
                fprintf('  Duration: %.1f minutes\n', timing_data.duration_minutes);
            end
            fprintf('  Files: %d\n', timing_data.num_files);
            fprintf('  Source: %s\n', timing_data.source);
        end
    end

else
    fprintf('\n=== STEP 3: SKIPPED (Timing extraction disabled) ===\n');
end

%% Step 5: Data Analysis
if config.run_data_analysis
    fprintf('\n=== STEP 5: DATA ANALYSIS ===\n');
    
    % Ensure we have timing configuration
    if ~exist('timing_config', 'var') || isempty(timing_config)
        fprintf('⚠ No timing configuration available. Looking for saved config...\n');
        
        % Try to load from _active directory
        active_config_file = fullfile(config.base_input, '_active', 'Batch_Timing_Config.mat');
        if exist(active_config_file, 'file')
            fprintf('Loading timing config from: %s\n', active_config_file);
            load(active_config_file, 'timing_config');
        else
            fprintf('No saved timing config found. Generating timing config...\n');
            
            % Generate timing config if not available
            timing_config = struct();
            for i = 1:length(config.test_labels)
                test_label = config.test_labels{i};
                tdms_directory = [config.base_input config.test_directories{i} '\'];
                
                if exist(tdms_directory, 'dir')
                    tdms_files = dir([tdms_directory '*.tdms']);
                    if ~isempty(tdms_files)
                        first_file = tdms_files(1).name;
                        timestamp_match = regexp(first_file, 'UTC_(\d{8}_\d{6}\.\d{3})', 'tokens');
                        if ~isempty(timestamp_match)
                            timestamp_str = timestamp_match{1}{1};
                            year = str2double(timestamp_str(1:4));
                            month = str2double(timestamp_str(5:6));
                            day = str2double(timestamp_str(7:8));
                            hour = str2double(timestamp_str(10:11));
                            minute = str2double(timestamp_str(12:13));
                            second = str2double(timestamp_str(14:15));
                            millisecond = str2double(timestamp_str(17:19));
                            
                            start_time = datetime(year, month, day, hour, minute, second, millisecond, 'TimeZone', 'UTC');
                            timing_config.(test_label).start = start_time;
                            
                            % Estimate end time
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
                            end
                        end
                    end
                end
            end
        end
    end
    
    try
        % Analyze head data
        fprintf('Running head data analysis...\n');
        head_results = analyze_head_data(timing_config, config.test_labels, config);
        
        % Analyze DAS data
        fprintf('Running DAS data analysis...\n');
        das_results = analyze_das_data(timing_config, config.test_labels, config);
        
        % Generate plots
        fprintf('Generating analysis plots...\n');
        plot_results = generate_analysis_plots(head_results, das_results, config);
        
        fprintf('✓ Data analysis completed successfully\n');
        
    catch ME
        fprintf('✗ Data analysis failed: %s\n', ME.message);
        if length(ME.stack) > 0
            fprintf('   Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
    end
    
else
    fprintf('\n=== STEP 5: SKIPPED (Data analysis disabled) ===\n');
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
if config.run_data_analysis && exist('plot_results', 'var')
    fprintf('  ✓ Data analysis completed\n');
    if plot_results.save_enabled && ~isempty(plot_results.figures_created)
        fprintf('  ✓ Charts saved: %d files\n', length(plot_results.figures_created));
    end
end
fprintf('\nReady for analysis!\n');
