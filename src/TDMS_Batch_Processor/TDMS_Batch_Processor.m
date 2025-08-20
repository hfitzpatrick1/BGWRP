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
file_config = get_batch_config();

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
                % Specific prep stage - don't cleanup existing dirs
                prep_stage = mode_parts{2};
                config.run_tdms_conversion = strcmp(prep_stage, 'tdms');
                config.run_concatenation = strcmp(prep_stage, 'concat');
                config.run_timing_extraction = strcmp(prep_stage, 'timing');
                config.run_data_analysis = false;
                config.save_charts = false;
                config.cleanup_dirs = false;  % Don't clean when running specific stages
                fprintf('Prep stage: %s\n', prep_stage);
            else
                % Full prep: TDMS conversion + concatenation + timing extraction with cleanup
                config.run_tdms_conversion = true;
                config.run_concatenation = true;
                config.run_timing_extraction = true;  % Include timing as part of prep
                config.run_data_analysis = false;
                config.save_charts = false;
                config.cleanup_dirs = true;   % Clean dirs for full prep
            end
            
        case 'run'
            % Analysis mode: analysis-only (no timing extraction)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;  % Skip - use existing configs
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            % Check for filtering suffix
            if contains(mode, 'filtered')
                config.apply_concatenation_filter = true;
                fprintf('Filtering enabled for mode: %s\n', mode);
            end
            
        case 'run_timing'
            % Analysis mode: timing extraction + analysis
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
if ~isfield(config, 'cleanup_dirs')
    config.cleanup_dirs = false;         % DEFAULT: Don't clean existing directories
end

%% Workspace Organization (only for prep modes)
if config.run_tdms_conversion || config.run_concatenation || config.run_timing_extraction
    fprintf('\n=== WORKSPACE ORGANIZATION ===\n');
    workspace_info = organize_workspace(config.base_input, config.cleanup_dirs);
else
    fprintf('\n=== ANALYSIS MODE: Skipping workspace organization ===\n');
    workspace_info = struct('input_folders', {{}});
end

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
        config.silixa.directory = [fullfile(config.base_input, current_folder) '\'];
        config.silixa.filesearch = '*.tdms';
        config.silixa.fileindex = [];
        config.silixa.save_data = 1;
        % Write MAT files to _tdms_to_mat directory  
        config.silixa.save_directory = [fullfile(config.base_input, '_tdms_to_mat', current_folder) '\'];
        
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
    
    % Output to _concatenated/<current_folder> directory  
    outname = sprintf('Dataset_%s_1Hz.mat', current_folder);
    output_dir = fullfile(local_base_input, '_concatenated', current_folder);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    output_file = fullfile(output_dir, outname);
    
    % Verify MAT directory exists
    if ~exist(mat_directory, 'dir')
        fprintf('⚠ MAT directory not found: %s\n', mat_directory);
        continue;
    end
    
    % Check MAT files
    search_pattern = fullfile(mat_directory, filesearch);
    fprintf('DEBUG: Search pattern: %s\n', search_pattern);
    files = dir(search_pattern);
    fprintf('Found %d MAT files to concatenate\n', length(files));
    
    % List the files found
    if length(files) > 0
        for j = 1:min(3, length(files))  % Show first 3 files
            fprintf('  File %d: %s\n', j, files(j).name);
        end
        if length(files) > 3
            fprintf('  ... and %d more files\n', length(files) - 3);
        end
    else
        fprintf('⚠ No MAT files found, skipping\n');
        % List what IS in the directory
        all_files = dir(mat_directory);
        fprintf('DEBUG: Directory contents (%d items):\n', length(all_files));
        for j = 1:min(5, length(all_files))
            if ~all_files(j).isdir
                fprintf('  %s\n', all_files(j).name);
            end
        end
        continue;
    end
    
    % Run concatenation using modern function
    success = concatenate_and_downsample(mat_directory, output_file, local_decimation_factor);
    
    if success
        fprintf('✓ Concatenation completed: %s\n', outname);
        
        % Copy to _active/<current_folder> directory for analysis
        active_dataset_dir = fullfile(local_base_input, '_active', current_folder);
        if ~exist(active_dataset_dir, 'dir')
            mkdir(active_dataset_dir);
        end
        active_output = fullfile(active_dataset_dir, outname);
        copyfile(output_file, active_output);
        fprintf('✓ Copied to _active/%s: %s\n', current_folder, outname);
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

% Use organized workspace info to find input folders (only during prep)
if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders') && ~isempty(workspace_info.input_folders)
    input_folders = workspace_info.input_folders;
else
    % Fallback: scan for input folders manually during prep
    fprintf('⚠ Workspace info not available, scanning for input folders...\n');
    all_items = dir(config.base_input);
    input_folders = {};
    for i = 1:length(all_items)
        if all_items(i).isdir && ~startsWith(all_items(i).name, '.') && ~startsWith(all_items(i).name, '_')
            % Check if directory contains TDMS files
            tdms_files = dir(fullfile(config.base_input, all_items(i).name, '*.tdms'));
            if ~isempty(tdms_files)
                input_folders{end+1} = all_items(i).name;
            end
        end
    end
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
    fprintf('  🔍 Checking primary directory: %s\n', tdms_directory);
    if ~exist(tdms_directory, 'dir')
        % Try organized workspace location
        tdms_directory = fullfile(config.base_input, '_tdms_to_mat', folder_name);
        fprintf('  🔍 Primary not found, trying workspace: %s\n', tdms_directory);
    else
        fprintf('  ✓ Primary directory exists\n');
    end
    
    if exist(tdms_directory, 'dir')
        % Find first TDMS file to extract start time
        fprintf('  📁 Scanning directory: %s\n', tdms_directory);
        tdms_files = dir(fullfile(tdms_directory, '*.tdms'));
        fprintf('  📊 Found %d TDMS files in directory\n', length(tdms_files));
        
        if ~isempty(tdms_files)
            % Sort files by name to ensure chronological order
            [~, sort_idx] = sort({tdms_files.name});
            tdms_files = tdms_files(sort_idx);
            fprintf('  📋 Files sorted chronologically\n');
            fprintf('  🕐 First file: %s\n', tdms_files(1).name);
            fprintf('  🕐 Last file: %s\n', tdms_files(end).name);
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
                    fprintf('  📊 Total files detected: %d\n', length(tdms_files));
                    
                    % Calculate end time (approximate)
                    last_file = tdms_files(end).name;
                    fprintf('  🕐 Processing last file: %s\n', last_file);
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
                        fprintf('  📏 Duration calculation: %s to %s = %.1f minutes\n', start_time, end_time, timing_config.(test_label).duration_minutes);
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

    % Create _configs directory
    configs_dir = fullfile(config.base_input, '_configs');
    if ~exist(configs_dir, 'dir')
        mkdir(configs_dir);
        fprintf('Created configs directory: %s\n', configs_dir);
    end

    % Save individual config files per dataset
    config_fields = fieldnames(timing_config);
    for i = 1:length(config_fields)
        test_label = config_fields{i};
        
        % Determine source folder name for this test
        source_folder = '';
        if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders')
            for j = 1:length(workspace_info.input_folders)
                folder_name = workspace_info.input_folders{j};
                if contains(folder_name, test_label) || ...
                   (strcmp(test_label, 'a') && contains(folder_name, 'PT01a')) || ...
                   (strcmp(test_label, 'b') && contains(folder_name, 'PT01b')) || ...
                   (strcmp(test_label, 'c') && contains(folder_name, 'PT01c'))
                    source_folder = folder_name;
                    break;
                end
            end
        end
        
        if isempty(source_folder)
            source_folder = sprintf('test_%s', test_label);
        end
        
        % Save as MATLAB function instead of MAT/TXT files
        test_config = timing_config.(test_label);
        save_timing_config_as_function(test_config, source_folder, configs_dir);
        
        % Configuration now saved as MATLAB function only
        
        % Also copy to _active/<source_folder>/ for dataset-specific analysis
        if ~isempty(source_folder)
            active_dataset_dir = fullfile(config.base_input, '_active', source_folder);
            if ~exist(active_dataset_dir, 'dir')
                mkdir(active_dataset_dir);
            end
            
            % Copy the MATLAB timing function
            func_filename = sprintf('get_timing_%s.m', source_folder);
            active_func_filepath = fullfile(active_dataset_dir, func_filename);
            source_func_filepath = fullfile(configs_dir, func_filename);
            
            if exist(source_func_filepath, 'file')
                copyfile(source_func_filepath, active_func_filepath);
            end
            
            fprintf('✓ Copied configs to _active/%s/\n', source_folder);
        end
    end
    
    % No longer saving legacy combined config - using individual dataset configs

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
        
        % Load timing configs from individual dataset directories
        timing_config = struct();
        active_base = fullfile(config.base_input, '_active');
        
        if exist(active_base, 'dir')
            dataset_dirs = dir(active_base);
            dataset_dirs = dataset_dirs([dataset_dirs.isdir] & ~startsWith({dataset_dirs.name}, '.'));
            
            for i = 1:length(dataset_dirs)
                dataset_name = dataset_dirs(i).name;
                dataset_dir = fullfile(active_base, dataset_name);
                
                % Find any .m file (timing config) and any .mat file (data) in directory
                m_files = dir(fullfile(dataset_dir, '*.m'));
                mat_files = dir(fullfile(dataset_dir, '*.mat'));
                
                if length(m_files) == 1 && length(mat_files) == 1
                    % Extract function name from .m file
                    [~, func_name, ~] = fileparts(m_files(1).name);
                    
                    fprintf('Loading timing function: %s from %s\n', func_name, m_files(1).name);
                    % Add the directory to path temporarily
                    addpath(dataset_dir);
                    try
                        loaded_config.test_config = feval(func_name);
                    catch ME
                        fprintf('Error calling %s: %s\n', func_name, ME.message);
                        rmpath(dataset_dir);
                        continue;
                    end
                    rmpath(dataset_dir);
                    
                    % Use full directory name as test label (authority for naming)
                    test_label = dataset_name;
                    
                    timing_config.(test_label) = loaded_config.test_config;
                    timing_config.(test_label).dataset_name = dataset_name;
                    fprintf('✓ Loaded timing for test %s from %s (data: %s)\n', test_label, m_files(1).name, mat_files(1).name);
                elseif length(m_files) == 0
                    fprintf('⚠ No .m file found in %s\n', dataset_name);
                elseif length(mat_files) == 0
                    fprintf('⚠ No .mat file found in %s\n', dataset_name);
                elseif length(m_files) > 1
                    fprintf('⚠ Multiple .m files found in %s - cannot determine config\n', dataset_name);
                elseif length(mat_files) > 1
                    fprintf('⚠ Multiple .mat files found in %s - cannot determine data file\n', dataset_name);
                end
            end
        end
        
        if isempty(fieldnames(timing_config))
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
        % Initialize timing config for analysis mode
        if ~config.run_timing_extraction
            timing_config = struct();  % Clear any previous timing config
            fprintf('Analysis mode: Starting with empty timing config\n');
        end
        
        % Determine test labels from available timing data
        available_tests = fieldnames(timing_config);
        
        % Also check _active directory for additional datasets
        active_dir = fullfile(config.base_input, '_active');
        if exist(active_dir, 'dir')
            active_datasets = dir(active_dir);
            active_datasets = active_datasets([active_datasets.isdir] & ~startsWith({active_datasets.name}, '.'));
            
            for i = 1:length(active_datasets)
                dataset_name = active_datasets(i).name;
                func_name = sprintf('get_timing_%s', dataset_name);
                func_file = fullfile(active_dir, dataset_name, sprintf('%s.m', func_name));
                
                if exist(func_file, 'file')
                    % Load this config using MATLAB function
                    fprintf('Loading timing function: %s\n', func_name);
                    dataset_dir = fullfile(active_dir, dataset_name);
                    addpath(dataset_dir);
                    try
                        loaded_config.test_config = feval(func_name);
                    catch ME
                        fprintf('Error calling %s: %s\n', func_name, ME.message);
                        rmpath(dataset_dir);
                        continue;
                    end
                    rmpath(dataset_dir);
                    
                    % Use full dataset name as test label for maximum flexibility
                    test_label = dataset_name;
                    fprintf('Using dataset name as test label: %s\n', test_label);
                    
                    % Override timing config if not already present or if this is more specific
                    if ~isfield(timing_config, test_label) || contains(dataset_name, 'Full')
                        timing_config.(test_label) = loaded_config.test_config;
                        timing_config.(test_label).dataset_name = dataset_name;
                        fprintf('✓ Found additional dataset: %s -> test %s\n', dataset_name, test_label);
                    end
                end
            end
        end
        
        available_tests = fieldnames(timing_config);
        if isempty(available_tests)
            fprintf('⚠ No timing data available for analysis\n');
            head_results = struct();
            das_results = struct();
        else
            fprintf('Analyzing tests: %s\n', strjoin(available_tests, ', '));
            
            % Debug: Show what datasets are mapped to what tests
            for i = 1:length(available_tests)
                test = available_tests{i};
                if isfield(timing_config.(test), 'dataset_name')
                    fprintf('  Test %s -> Dataset: %s\n', test, timing_config.(test).dataset_name);
                else
                    fprintf('  Test %s -> No dataset mapping\n', test);
                end
            end
            
            % Analyze head data
            fprintf('Running head data analysis...\n');
            head_results = analyze_head_data(timing_config, available_tests, config);
            
            % Analyze DAS data
            fprintf('Running DAS data analysis...\n');
            das_results = analyze_das_data(timing_config, available_tests, config);
        end
        
        % Generate plots
        fprintf('Generating analysis plots...\n');
        plot_results = generate_plots(head_results, das_results, config);
        
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

% Check for actual datasets in _active directory instead of hardcoded legacy names
active_dir = fullfile(config.base_input, '_active');
if exist(active_dir, 'dir')
    dataset_dirs = dir(active_dir);
    dataset_dirs = dataset_dirs([dataset_dirs.isdir] & ~startsWith({dataset_dirs.name}, '.'));
    
    if ~isempty(dataset_dirs)
        fprintf('Active datasets:\n');
        for i = 1:length(dataset_dirs)
            dataset_name = dataset_dirs(i).name;
            data_file = sprintf('%s_1Hz.mat', dataset_name);
            timing_file = sprintf('timing_%s.txt', dataset_name);
            
            data_path = fullfile(active_dir, dataset_name, data_file);
            timing_path = fullfile(active_dir, dataset_name, timing_file);
            
            if exist(data_path, 'file') && exist(timing_path, 'file')
                fprintf('  ✓ %s (complete with timing config)\n', dataset_name);
            elseif exist(data_path, 'file')
                fprintf('  ✓ %s (data only, missing timing)\n', dataset_name);
            else
                fprintf('  ✗ %s (incomplete)\n', dataset_name);
            end
        end
    else
        fprintf('  ⚠ No datasets found in _active directory\n');
    end
else
    fprintf('  ⚠ _active directory not found\n');
    
    % Fallback: check legacy locations (only if _active doesn't exist)
    fprintf('Legacy file check:\n');
    for i = 1:length(config.test_labels)
        final_file = sprintf('Dataset_%s_1Hz.mat', config.test_labels{i});
        if exist(fullfile(config.base_input, final_file), 'file')
            fprintf('  ✓ %s (legacy location)\n', final_file);
        else
            fprintf('  ✗ %s (not created)\n', final_file);
        end
    end
end
if config.run_timing_extraction
    fprintf('  ✓ Individual dataset timing configs\n');
end
if config.run_data_analysis && exist('plot_results', 'var')
    fprintf('  ✓ Data analysis completed\n');
    if plot_results.save_enabled && ~isempty(plot_results.figures_created)
        fprintf('  ✓ Charts saved: %d files\n', length(plot_results.figures_created));
    end
end
fprintf('\nReady for analysis!\n');
