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
% Add all subdirectories to path
addpath(genpath(script_dir));
fprintf('Added all subdirectories to path: %s\n', script_dir);

%% Configuration Setup
% Load config from file first (clear cache to ensure fresh config)
clear config
file_config = config();


% Handle shorthand mode parameter
if exist('mode', 'var') && ischar(mode)
    fprintf('Using shorthand mode: %s\n', mode);
    config = file_config; % Start with file config
    
    % Parse mode
    mode_parts = strsplit(lower(mode), '_');
    base_mode = mode_parts{1};
    
    switch lower(mode)
        case 'prep'
            % Full prep: TDMS conversion + concatenation + timing extraction with cleanup
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = true;
            
        case 'prep_tdms'
            % TDMS conversion only
            config.run_tdms_conversion = true;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = false;
            
        case 'prep_concat'
            % Concatenation only
            config.run_tdms_conversion = false;
            config.run_concatenation = true;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = false;
            
        case 'prep_timing'
            % Timing extraction only
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = false;
            
        case 'prep_no_decim'
            % Full prep with no decimation (preserve 100Hz)
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = true;
            config.decimation_factor = 1;  % Override: no decimation
            
        case 'prep_purge'
            % Full prep with purge mode (delete all previous data)
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = true;  % This triggers purge mode via selective_mode
            
        case 'prep_single_step'
            % Full prep with single-step scaling (fixes grid artifacts)
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = true;
            config.tdms_scaling_method = 'single_step';
            
        case 'prep_double_precision'
            % Full prep with double precision scaling
            config.run_tdms_conversion = true;
            config.run_concatenation = true;
            config.run_timing_extraction = true;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.cleanup_dirs = true;
            config.tdms_scaling_method = 'double_precision';
            config.tdms_force_double = true;
            
        case 'purge_inactive'
            % Clean up intermediate directories that don't match _active content
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_purge_inactive = true;
            
        case 'purge_unraw'
            % Archive non-underscore directories to _raw and purge intermediate processing
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_purge_unraw = true;
            
        case {'run', 'analyze'}
            % Analysis mode: analysis-only (no timing extraction)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;  % Skip - use existing configs
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            % Reset filtering options to defaults
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            
        case 'diagnostic_quantization'
            % Quantization analysis diagnostic mode
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_quantization_analysis = true;
            % Reset other diagnostic options to defaults
            config.run_boundary_diagnostic = false;
            config.run_enhanced_diagnostic = false;
            fprintf('Diagnostic mode: quantization analysis\n');
            
        case 'run_detrend'
            % Analysis mode with detrend filtering
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'detrend';
            % Reset diagnostic options to defaults
            config.run_boundary_diagnostic = false;
            config.run_enhanced_diagnostic = false;
            fprintf('Filter mode: detrend\n');
            
        case 'run_highpass'
            % Analysis mode with highpass filtering
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'highpass';
            fprintf('Filter mode: highpass\n');
            
        case 'run_median'
            % Analysis mode with median filtering
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'median';
            fprintf('Filter mode: median\n');
            
        case 'run_filter_chen'
            % Run Chen et al. complete denoising framework
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.chen_denoising = true;
            config.smoothing_method = 'chen_full';
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            fprintf('Running Chen et al. complete denoising framework\n');
            
        case 'run_filter_chen_fk'
            % Run Chen Stage 3 F-K filter only (grid pattern focus)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'chen_stage3';
            config.chen_fk_strength = 0.02;  % Chen paper default
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running Chen F-K dip filter (grid pattern removal)\n');
            
        case 'run_filter_spatial'
            % Run spatial median filtering
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'spatial_median';
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running spatial median filtering\n');
            
        case 'run_filter_temporal'
            % Run temporal median filtering
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'movmedian';
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running temporal median filtering\n');
            
        case 'run_filter_baseline'
            % Run baseline (no filtering)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'none';
            config.chen_denoising = false;
            config.disable_analysis_smoothing = true;
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            fprintf('Running baseline (no filtering)\n');
            
        case 'run_filter_ensemble'
            % Run multi-channel ensemble averaging (signal extraction)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'ensemble';
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running ensemble averaging (signal extraction approach)\n');
            
        case 'run_filter_grid'
            % Run targeted grid pattern removal
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'dual_bandstop';
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running targeted grid pattern removal (dual bandstop)\n');
            
        case 'run_filter_movavg'
            % Run parameterized moving average filter
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'movmean';  % Use enhanced existing filter
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running parameterized moving average filter\n');
            
        case 'run_filter_matlab_movmean'
            % Run MATLAB movmean filter (like PM07_PT01a_Simple.m)
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = false;
            config.smoothing_method = 'matlab_movmean';  % Use new MATLAB movmean
            % Reset other filtering
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            config.chen_denoising = false;
            fprintf('Running MATLAB movmean filter (10-sample window)\n');
            
            case 'run_filter_movmean_plus_grid'
        % Run MATLAB movmean + grid pattern removal (0.35 Hz target)
        config.run_tdms_conversion = false;
        config.run_concatenation = false;
        config.run_timing_extraction = false;
        config.run_data_analysis = true;
        config.save_charts = false;
        config.smoothing_method = 'matlab_movmean';  % First: MATLAB movmean
        config.apply_concatenation_filter = true;   % Then: Apply grid removal
        config.filter_method = 'dual_bandstop';     % Target 0.35 Hz pattern
        config.chen_denoising = false;
        fprintf('Running MATLAB movmean + 0.35 Hz grid removal\n');
        
    case 'run_filter_matlab_movmean_5sec'
        % Run MATLAB movmean filter with 5-second window (5 samples at 1Hz)
        config.run_tdms_conversion = false;
        config.run_concatenation = false;
        config.run_timing_extraction = false;
        config.run_data_analysis = true;
        config.save_charts = false;
        config.smoothing_method = 'matlab_movmean';  % Use MATLAB movmean
        config.matlab_movmean_window = 5;           % 5-second window (5 samples)
        % Reset other filtering
        config.apply_concatenation_filter = false;
        config.filter_method = 'none';
        config.chen_denoising = false;
        fprintf('Running MATLAB movmean filter (5-second window)\n');
            
        case 'run_correlation_analysis'
            % Analysis mode with strain rate vs head data correlation
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.correlation_analysis = true;
            config.signal_onset_detection = true;
            fprintf('Running strain rate vs head data correlation analysis\n');
            
        case 'run_smooth'
            % Analysis mode with boundary smoothingg
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'overlap_smooth';
            fprintf('Filter mode: overlap_smooth\n');
            
        case 'diagnostic_boundaries'
            % Diagnostic mode: analyze file boundary discontinuities
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_boundary_diagnostic = true;
            % Reset filtering options to defaults
            config.apply_concatenation_filter = false;
            config.filter_method = 'none';
            % Reset other diagnostic options
            config.run_enhanced_diagnostic = false;
            fprintf('Diagnostic mode: file boundaries\n');
            
        case 'diagnostic_enhanced'
            % Enhanced diagnostic mode: focused boundary analysis
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_enhanced_diagnostic = true;
            fprintf('Enhanced diagnostic mode\n');
            
        case 'diagnostic_tdms'
            % TDMS metadata diagnostic mode: analyze raw file metadata
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = false;
            config.save_charts = false;
            config.run_tdms_metadata_diagnostic = true;
            fprintf('Diagnostic mode: TDMS metadata analysis\n');
            
        case 'run_phase_align'
            % Analysis mode with phase alignment correction
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'phase_align';
            fprintf('Phase correction mode: phase_align\n');
            
        case 'run_smooth_transition'
            % Analysis mode with smooth transition correction
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'smooth_transition';
            fprintf('Phase correction mode: smooth_transition\n');
            
        case 'run_local_detrend'
            % Analysis mode with local detrending correction
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'local_detrend';
            fprintf('Phase correction mode: local_detrend\n');
            
        case 'run_rms_normalize'
            % Analysis mode with RMS amplitude normalization
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'rms_normalize';
            fprintf('Amplitude correction mode: rms_normalize\n');
            
        case 'run_adaptive_normalize'
            % Analysis mode with adaptive amplitude normalization
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'adaptive_normalize';
            fprintf('Amplitude correction mode: adaptive_normalize\n');
            
        case 'run_percentile_normalize'
            % Analysis mode with percentile-based normalization
            config.run_tdms_conversion = false;
            config.run_concatenation = false;
            config.run_timing_extraction = false;
            config.run_data_analysis = true;
            config.save_charts = contains(mode, 'save');
            config.apply_concatenation_filter = true;
            config.filter_method = 'percentile_normalize';
            fprintf('Amplitude correction mode: percentile_normalize\n');
            
        case {'run_timing', 'analyze_timing'}
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
            error('Unknown mode: %s. Valid modes: prep, prep_single_step, prep_double_precision, prep_no_decim, prep_purge, prep_tdms, prep_concat, prep_timing, analyze, analyze_save, all, all_save, purge_inactive, purge_unraw, diagnostic_boundaries, diagnostic_enhanced, diagnostic_tdms', mode);
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
    % Determine selective mode from current mode
    if contains(mode, 'purge')
        selective_mode = 'purge';
    else
        selective_mode = 'selective';
    end
    
    workspace_info = organize_workspace(config.base_input, config.cleanup_dirs, selective_mode);
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
        % Read TDMS files from original input directory _das subdirectory
        config.silixa.directory = [fullfile(config.base_input, current_folder, '_das') '\'];
        config.silixa.filesearch = '*.tdms';
        config.silixa.fileindex = [];
        config.silixa.save_data = 1;
        % Write MAT files to _tdms_to_mat/_das directory  
        config.silixa.save_directory = [fullfile(config.base_input, '_tdms_to_mat', current_folder, '_das') '\'];
        
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
        silixa_script = fullfile(script_dir, 'prepare', 'Silixa_TDMSDataToPhysicalDispRate.m');
        run(silixa_script);
        fprintf('✓ TDMS conversion completed for %s\n', current_folder);
    catch ME
        fprintf('✗ TDMS conversion failed for %s: %s\n', current_folder, ME.message);
    end
    end
else
    fprintf('\n=== STEP 1: SKIPPED (TDMS conversion disabled) ===\n');
end

%% Step 2: Process head data (combine zones into single files)
if config.run_concatenation  % Run head processing if concatenation is enabled
    fprintf('\n=== STEP 2A: HEAD DATA PROCESSING ===\n');
    
    % Use the same folders that were processed in TDMS conversion step
    if exist('workspace_info', 'var') && isfield(workspace_info, 'input_folders')
        folders_to_process = workspace_info.input_folders;
    else
        folders_to_process = config.test_directories;
    end
    
    for i = 1:length(folders_to_process)
        current_folder = folders_to_process{i};
        fprintf('\n--- Processing head data for %s ---\n', current_folder);
        
        % Head data input directory (expect _head subdirectory)
        head_input_dir = fullfile(config.base_input, current_folder, '_head');
        
        % Head data output directory 
        head_output_dir = fullfile(config.base_input, '_combined_head', current_folder);
        if ~exist(head_output_dir, 'dir')
            mkdir(head_output_dir);
        end
        head_output_file = fullfile(head_output_dir, 'head_data.mat');
        
        % Check if head data directory exists
        if ~exist(head_input_dir, 'dir')
            fprintf('⚠ Head data directory not found: %s\n', head_input_dir);
            continue;
        end
        
        % Process head data
        success = process_head_data(head_input_dir, head_output_file);
        
        if success
            fprintf('✓ Head data processing completed: %s\n', current_folder);
        else
            fprintf('✗ Head data processing failed for %s\n', current_folder);
        end
    end
else
    fprintf('\n=== STEP 2A: SKIPPED (Head data processing disabled) ===\n');
end

%% Step 2B: Concatenate and downsample individual MAT files
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
    
    % Read from _tdms_to_mat/_das subdirectory (new structure)
    mat_directory = fullfile(local_base_input, '_tdms_to_mat', current_folder, '_das');
    fprintf('DEBUG: Looking for DAS MAT files in: %s\n', mat_directory);
    
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
    
    % Run MAT data processing (concatenation + downsampling)
    success = process_mat_data(mat_directory, output_file, local_decimation_factor);
    
    if success
        fprintf('✓ Concatenation completed: %s\n', outname);
        
        % Copy DAS data to _active/<current_folder>/_das directory
        active_dataset_dir = fullfile(local_base_input, '_active', current_folder);
        active_das_dir = fullfile(active_dataset_dir, '_das');
        if ~exist(active_das_dir, 'dir')
            mkdir(active_das_dir);
        end
        active_das_output = fullfile(active_das_dir, outname);
        copyfile(output_file, active_das_output);
        fprintf('✓ Copied DAS data to _active/%s/_das: %s\n', current_folder, outname);
        
        % Copy head data if it exists to _active/<current_folder>/_head directory
        head_source = fullfile(local_base_input, '_combined_head', current_folder, 'head_data.mat');
        if exist(head_source, 'file')
            active_head_dir = fullfile(active_dataset_dir, '_head');
            if ~exist(active_head_dir, 'dir')
                mkdir(active_head_dir);
            end
            active_head_output = fullfile(active_head_dir, 'head_data.mat');
            copyfile(head_source, active_head_output);
            fprintf('✓ Copied head data to _active/%s/_head: head_data.mat\n', current_folder);
        else
            fprintf('⚠ No head data found for %s\n', current_folder);
        end
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
    
    % Use actual folder name as test label - no hardcoded patterns
    test_label = folder_name;
    
    fprintf('Extracting timing for folder %s (label: %s)...\n', folder_name, test_label);
    
    % Look for TDMS files in original input folder _das subdirectory
    tdms_directory = fullfile(config.base_input, folder_name, '_das');
    fprintf('  🔍 Checking primary directory: %s\n', tdms_directory);
    if ~exist(tdms_directory, 'dir')
        % Try organized workspace location
        tdms_directory = fullfile(config.base_input, '_tdms_to_mat', folder_name, '_das');
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
                if strcmp(test_label, folder_name)
                    source_folder = folder_name;
                    break;
                end
            end
        end
        
        if isempty(source_folder)
            source_folder = test_label;  % Use test_label directly (which is now the folder name)
        end
        
        % Save as MATLAB function instead of MAT/TXT files
        test_config = timing_config.(test_label);
        save_timing_config(test_config, source_folder, configs_dir);
        
        % Configuration now saved as MATLAB function only
        
        % Also copy to _active/<source_folder>/_das_timing/ for dataset-specific analysis
        if ~isempty(source_folder)
            active_dataset_dir = fullfile(config.base_input, '_active', source_folder);
            active_timing_dir = fullfile(active_dataset_dir, '_das_timing');
            if ~exist(active_timing_dir, 'dir')
                mkdir(active_timing_dir);
            end
            
            % Copy the MATLAB timing function to _das_timing subdirectory
            func_filename = sprintf('get_timing_%s.m', source_folder);
            active_func_filepath = fullfile(active_timing_dir, func_filename);
            source_func_filepath = fullfile(configs_dir, func_filename);
            
            if exist(source_func_filepath, 'file')
                copyfile(source_func_filepath, active_func_filepath);
            end
            
            fprintf('✓ Copied configs to _active/%s/_das_timing/\n', source_folder);
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

%% Step 4: Boundary Diagnostic
if isfield(config, 'run_boundary_diagnostic') && config.run_boundary_diagnostic
    fprintf('\n=== STEP 4: FILE BOUNDARY DIAGNOSTIC ===\n');
    
    % Use unified dataset discovery for active (processed) datasets
    try
        dataset_info = discover_datasets(config.base_input, 'active');
        fprintf('Discovered %d processed datasets for boundary diagnostic\n', length(dataset_info.datasets));
    catch ME
        fprintf('✗ Active dataset discovery failed: %s\n', ME.message);
        fprintf('Cannot proceed with boundary diagnostic\n');
        return;
    end
    
    % Load timing configs for diagnostic
    timing_config = struct();
    
    for i = 1:length(dataset_info.datasets)
        dataset_name = dataset_info.datasets{i};
        dataset_dir = dataset_info.paths{i};
        
        fprintf('Processing dataset: %s\n', dataset_name);
        
        % Find .mat file and timing config file
            mat_files = dir(fullfile(dataset_dir, '*.mat'));
        m_files = dir(fullfile(dataset_dir, 'get_timing_*.m'));
            
            if length(m_files) == 1 && length(mat_files) == 1
                % Load timing config
                [~, func_name, ~] = fileparts(m_files(1).name);
                addpath(dataset_dir);
                try
                    loaded_config = feval(func_name);
                    timing_config.(dataset_name) = loaded_config;
                    
                    % Run boundary diagnostic
                    data_filepath = fullfile(dataset_dir, mat_files(1).name);
                    diagnose_file_boundaries(dataset_name, data_filepath, loaded_config);
                    
                catch ME
                    fprintf('Error in diagnostic for %s: %s\n', dataset_name, ME.message);
                end
                rmpath(dataset_dir);
        else
            fprintf('⚠ Skipping %s: Expected 1 MAT file and 1 timing config, found %d MAT, %d timing configs\n', ...
                dataset_name, length(mat_files), length(m_files));
        end
    end
    
    fprintf('\n=== BOUNDARY DIAGNOSTIC COMPLETE ===\n');
end

%% Step 4b: Enhanced Diagnostic
if isfield(config, 'run_enhanced_diagnostic') && config.run_enhanced_diagnostic
    fprintf('\n=== STEP 4B: ENHANCED BOUNDARY DIAGNOSTIC ===\n');
    
    % Use unified dataset discovery for active (processed) datasets
    try
        dataset_info = discover_datasets(config.base_input, 'active');
        fprintf('Discovered %d processed datasets for enhanced diagnostic\n', length(dataset_info.datasets));
    catch ME
        fprintf('✗ Active dataset discovery failed: %s\n', ME.message);
        fprintf('Cannot proceed with enhanced diagnostic\n');
        return;
    end
    
    % Load timing configs for enhanced diagnostic
    timing_config = struct();
    
    for i = 1:length(dataset_info.datasets)
        dataset_name = dataset_info.datasets{i};
        dataset_dir = dataset_info.paths{i};
        
        fprintf('Processing dataset: %s\n', dataset_name);
        
        % Find .mat file and timing config file
            mat_files = dir(fullfile(dataset_dir, '*.mat'));
        m_files = dir(fullfile(dataset_dir, 'get_timing_*.m'));
            
            if length(m_files) == 1 && length(mat_files) == 1
                % Load timing config
                [~, func_name, ~] = fileparts(m_files(1).name);
                addpath(dataset_dir);
                try
                    loaded_config = feval(func_name);
                    timing_config.(dataset_name) = loaded_config;
                    
                    % Run enhanced boundary diagnostic
                    data_filepath = fullfile(dataset_dir, mat_files(1).name);
                    diagnose_boundaries_enhanced(dataset_name, data_filepath, loaded_config);
                    
                catch ME
                    fprintf('Error in enhanced diagnostic for %s: %s\n', dataset_name, ME.message);
                end
                rmpath(dataset_dir);
        else
            fprintf('⚠ Skipping %s: Expected 1 MAT file and 1 timing config, found %d MAT, %d timing configs\n', ...
                dataset_name, length(mat_files), length(m_files));
        end
    end
    
    fprintf('\n=== ENHANCED DIAGNOSTIC COMPLETE ===\n');
end

%% Step 4c: TDMS Metadata Diagnostic
if isfield(config, 'run_tdms_metadata_diagnostic') && config.run_tdms_metadata_diagnostic
    fprintf('\n=== STEP 4C: TDMS METADATA DIAGNOSTIC ===\n');
    
    % Use unified dataset discovery for consistent behavior
    try
        dataset_info = discover_datasets(config.base_input, 'raw');
        folders_to_process = dataset_info.datasets;
        fprintf('Discovered %d datasets for TDMS diagnostic\n', length(folders_to_process));
    catch ME
        fprintf('✗ Dataset discovery failed: %s\n', ME.message);
        fprintf('Cannot proceed with TDMS diagnostic\n');
        folders_to_process = {};
    end
    
    for i = 1:length(folders_to_process)
        current_folder = folders_to_process{i};
        fprintf('\n--- Processing %s ---\n', current_folder);
        
        % Get directory path from discovery results
        dataset_base_path = dataset_info.paths{i};
        
        % Check if this dataset has TDMS files
        if strcmp(dataset_info.types{i}, 'mat')
            fprintf('⚠ Skipping %s: Only MAT files found, no TDMS metadata available\n', current_folder);
            continue;
        end
        
        % Determine TDMS directory (check for _das subdirectory first)
        das_subdir = fullfile(dataset_base_path, '_das');
        if exist(das_subdir, 'dir')
            tdms_directory = das_subdir;
            fprintf('Using structured _das subdirectory: %s\n', tdms_directory);
        else
            tdms_directory = dataset_base_path;
            fprintf('Using flat directory structure: %s\n', tdms_directory);
        end
        
        % Run TDMS metadata diagnostic
        try
            diagnose_tdms_metadata(current_folder, tdms_directory);
            fprintf('✓ TDMS metadata diagnostic completed for %s\n', current_folder);
        catch ME
            fprintf('✗ TDMS metadata diagnostic failed for %s: %s\n', current_folder, ME.message);
        end
    end
    
    fprintf('\n=== TDMS METADATA DIAGNOSTIC COMPLETE ===\n');
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
                
                % Look for timing config in _das_timing subdirectory
                timing_dir = fullfile(dataset_dir, '_das_timing');
                m_files = [];
                if exist(timing_dir, 'dir')
                    m_files = dir(fullfile(timing_dir, '*.m'));
                end
                
                % Look for DAS data in _das subdirectory
                das_dir = fullfile(dataset_dir, '_das');
                mat_files = [];
                if exist(das_dir, 'dir')
                    mat_files = dir(fullfile(das_dir, '*.mat'));
                end
                
                if length(m_files) == 1 && length(mat_files) == 1
                    % Extract function name from .m file
                    [~, func_name, ~] = fileparts(m_files(1).name);
                    
                    fprintf('Loading timing function: %s from %s\n', func_name, m_files(1).name);
                    % Add the timing directory to path temporarily
                    addpath(timing_dir);
                    try
                        loaded_config.test_config = feval(func_name);
                    catch ME
                        fprintf('Error calling %s: %s\n', func_name, ME.message);
                        rmpath(timing_dir);
                        continue;
                    end
                    rmpath(timing_dir);
                    
                    % Use full directory name as test label (authority for naming)
                    test_label = dataset_name;
                    
                    timing_config.(test_label) = loaded_config.test_config;
                    % Note: dataset_name removed - directory name is authority
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
                dataset_dir = fullfile(active_dir, dataset_name);
                
                % Find timing config in _das_timing subdirectory - accept any .m file
                timing_dir = fullfile(dataset_dir, '_das_timing');
                m_files = [];
                if exist(timing_dir, 'dir')
                    m_files = dir(fullfile(timing_dir, '*.m'));
                end
                
                if length(m_files) == 1
                    % Found exactly one .m file - use it
                    [~, func_name, ~] = fileparts(m_files(1).name);
                    
                    % Load this config using MATLAB function
                    fprintf('Loading timing function: %s from directory %s\n', func_name, dataset_name);
                    addpath(timing_dir);
                    try
                        loaded_config.test_config = feval(func_name);
                    catch ME
                        fprintf('Error calling %s: %s\n', func_name, ME.message);
                        rmpath(timing_dir);
                        continue;
                    end
                    rmpath(timing_dir);
                    
                    % Use directory name as test label (parent directory is authority)
                    test_label = dataset_name;
                    fprintf('Using dataset directory name as test label: %s\n', test_label);
                    
                    % Add to timing config
                    timing_config.(test_label) = loaded_config.test_config;
                    fprintf('✓ Found dataset: %s\n', dataset_name);
                elseif length(m_files) == 0
                    fprintf('⚠ No .m files found in _das_timing subdirectory for %s\n', dataset_name);
                else
                    fprintf('⚠ Multiple .m files found in _das_timing subdirectory for %s:\n', dataset_name);
                    for j = 1:length(m_files)
                        fprintf('    %s\n', m_files(j).name);
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
                fprintf('  Test %s -> Directory: %s\n', test, test);
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
            data_file = sprintf('Dataset_%s_1Hz.mat', dataset_name);
            timing_file = sprintf('get_timing_%s.m', dataset_name);
            
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

%% Step 6: Purge Modes (if enabled)
if isfield(config, 'run_purge_inactive') && config.run_purge_inactive
    fprintf('\n=== PURGE INACTIVE MODE ===\n');
    purge_inactive_directories(config.base_input);
    fprintf('=== PURGE INACTIVE COMPLETE ===\n');
elseif isfield(config, 'run_purge_unraw') && config.run_purge_unraw
    fprintf('\n=== PURGE UNRAW MODE ===\n');
    purge_unraw_directories(config.base_input);
    fprintf('=== PURGE UNRAW COMPLETE ===\n');
end

%% Step 7: Quantization Analysis (if enabled)
if isfield(config, 'run_quantization_analysis') && config.run_quantization_analysis
    fprintf('\n=== STEP 6: QUANTIZATION ANALYSIS ===\n');
    
    % Look for processed datasets in _concatenated directory
    concatenated_dir = fullfile(config.base_input, '_concatenated');
    if exist(concatenated_dir, 'dir')
        items = dir(concatenated_dir);
        datasets = {};
        for i = 1:length(items)
            if items(i).isdir && ~startsWith(items(i).name, '.')
                % Check if it has a 1Hz MAT file
                mat_file = fullfile(concatenated_dir, items(i).name, sprintf('Dataset_%s_1Hz.mat', items(i).name));
                if exist(mat_file, 'file')
                    datasets{end+1} = items(i).name;
                end
            end
        end
        
        if ~isempty(datasets)
            fprintf('Found %d datasets with processed 1Hz data:\n', length(datasets));
            for i = 1:length(datasets)
                dataset_name = datasets{i};
                fprintf('  %d. %s\n', i, dataset_name);
                try
                    analyze_quantization(dataset_name);
                catch ME
                    fprintf('✗ Quantization analysis failed for %s: %s\n', dataset_name, ME.message);
                end
            end
        else
            fprintf('No datasets with 1Hz data found in _concatenated directory\n');
        end
    else
        fprintf('_concatenated directory not found: %s\n', concatenated_dir);
    end
    
    fprintf('=== QUANTIZATION ANALYSIS COMPLETE ===\n');
end

%% Archive processed directories (selective mode only)
if exist('workspace_info', 'var') && isfield(workspace_info, 'archive_function') && ~isempty(workspace_info.archive_function)
    fprintf('\n=== ARCHIVING PROCESSED DIRECTORIES ===\n');
    workspace_info.archive_function();
end

if strcmp(mode, 'analyze') || strcmp(mode, 'analyze_timing')
    fprintf('\nAnalysis complete!\n');
else
    fprintf('\nReady for analysis!\n');
end
