function das_results = analyze_das_data(timing_config, test_labels, config)
%ANALYZE_DAS_DATA Simplified DAS data analysis utility
%
% Analyzes DAS strain rate data using batch processor timing configuration
%
% Inputs:
%   timing_config - Timing configuration from batch processor
%   test_labels   - Cell array of test labels (e.g., {'a', 'b', 'c'})
%   config        - Batch processor configuration structure
%
% Outputs:
%   das_results - Structure containing DAS analysis results for all tests

fprintf('=== DAS DATA ANALYSIS ===\n');

% Initialize results structure
das_results = struct();
das_results.tests = test_labels;
das_results.timing = timing_config;

%% Simple DAS parameters (based on PM07_PT01c_Simple.m approach)
% Configurable smoothing parameters
default_smooth_window = 10;
if isfield(config, 'smoothing_window_factor')
    smooth_window = round(default_smooth_window * config.smoothing_window_factor);
else
    smooth_window = default_smooth_window;
end

% Simple calibration lookup table
calibration = struct();
calibration.PT01c.C1 = 140;          % From your simple script
calibration.PT01c.MperChan = 0.263;  % From your simple script
calibration.PT01c.zone_min_ft = 260;
calibration.PT01c.zone_max_ft = 310;
calibration.PT01a.C1 = 513;
calibration.PT01a.MperChan = 0.25;
calibration.PT01a.zone_min_ft = 450;
calibration.PT01a.zone_max_ft = 510;
calibration.PT01b.C1 = 513;
calibration.PT01b.MperChan = 0.25;
calibration.PT01b.zone_min_ft = 350;
calibration.PT01b.zone_max_ft = 400;

% Dynamic default for any dataset name
calibration.dynamic_default.C1 = 200;
calibration.dynamic_default.MperChan = 0.25;
calibration.dynamic_default.zone_min_ft = 200;
calibration.dynamic_default.zone_max_ft = 400;

%% Analyze DAS data for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Analyzing DAS data for test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if ~isfield(timing_config, test_label)
        fprintf('  WARNING: No timing data found for test %s\n', test_label);
        das_results.(test_label).error = 'no_timing_data';
        continue;
    end
    
        test_timing = timing_config.(test_label);
    
    % Simple file discovery - look only in _active datasets
    % Find exactly one .mat file in _das subdirectory
    dataset_dir = fullfile(config.base_input, '_active', test_label);
    das_subdir = fullfile(dataset_dir, '_das');
    
    if ~exist(das_subdir, 'dir')
        fprintf('  ⚠ _das subdirectory not found for %s\n', test_label);
        das_results.(test_label).error = 'das_subdir_not_found';
        continue;
    end
    
    % Find all .mat files in _das subdirectory
    mat_files = dir(fullfile(das_subdir, '*.mat'));
    
    if length(mat_files) == 0
        fprintf('  ⚠ No .mat files found in _das subdirectory for %s\n', test_label);
        das_results.(test_label).error = 'no_das_files';
        continue;
    elseif length(mat_files) > 1
        fprintf('  ⚠ Multiple .mat files found in _das subdirectory for %s:\n', test_label);
        for i = 1:length(mat_files)
            fprintf('    %s\n', mat_files(i).name);
        end
        das_results.(test_label).error = 'multiple_das_files';
        continue;
    end
    
    % Found exactly one .mat file - use it
    das_filepath = fullfile(das_subdir, mat_files(1).name);
    fprintf('  Found DAS data file: %s\n', mat_files(1).name);
    
    fprintf('  Loading DAS data: %s\n', das_filepath);
    
    % Load DAS data (handle multiple variable naming conventions)
    loaded_data = load(das_filepath);
    if isfield(loaded_data, 'decdata')
        data1Hz = loaded_data.decdata;
        fprintf('  Loaded decimated data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    elseif isfield(loaded_data, 'fulldata')
        data1Hz = loaded_data.fulldata;
        fprintf('  Loaded full-resolution data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    elseif isfield(loaded_data, 'Data')
        data1Hz = loaded_data.Data;
        fprintf('  Loaded processed data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    else
        % Show available variables to help debug
        available_vars = fieldnames(loaded_data);
        fprintf('  Available variables in file: %s\n', strjoin(available_vars, ', '));
        error('No valid data variable found. Expected ''decdata'', ''fulldata'', or ''Data''');
    end
    
    % OPTIONAL: Convert from nm/sample to nm/s
    % Only apply if explicitly enabled via config flag
    % This corrects for TDMS conversion not multiplying by sampling frequency
    if isfield(config, 'apply_sampling_freq_correction') && config.apply_sampling_freq_correction
        % Determine the actual sampling frequency of THIS file
        if isfield(loaded_data, 'decdata')
            % This is DECIMATED data - averaging over 1 second means values are already rates!
            % When decimated from 100Hz to 1Hz, each sample = average over 1 second
            % This makes the values effectively "nm per second" = nm/s already
            % So NO correction needed (multiply by 1)
            sampling_freq = 1.0;  % Hz (no correction - data already in nm/s)
            fprintf('  ℹ Sampling frequency correction for decimated data\n');
            fprintf('    Data type: Decimated to 1 Hz (from 100 Hz original)\n');
            fprintf('    Decimated values represent average over 1 second → already in nm/s\n');
            fprintf('    Correction factor: %.0f (no change)\n', sampling_freq);
        elseif isfield(loaded_data, 'fs_f')
            % Use the stored sampling frequency (for non-decimated data)
            sampling_freq = loaded_data.fs_f;  % Hz
            fprintf('  ⚠ APPLYING SAMPLING FREQUENCY CORRECTION\n');
            fprintf('    Data type: Original or full-resolution\n');
            fprintf('    Stored sampling frequency: %.2f Hz\n', sampling_freq);
        else
            % Default fallback
            sampling_freq = 1.0;  % Hz (assume 1 Hz decimated data)
            fprintf('  ⚠ WARNING: No sampling frequency (fs_f) found in file!\n');
            fprintf('    Assuming decimated data at 1 Hz\n');
        end
        
        fprintf('    Data was saved as nm/sample, converting to nm/s\n');
        fprintf('    Using sampling frequency: %.2f Hz\n', sampling_freq);
        fprintf('    Before correction: [%.3e, %.3e] nm/sample\n', min(data1Hz(:)), max(data1Hz(:)));
        
        data1Hz = data1Hz * sampling_freq;  % Convert nm/sample → nm/s
        
        fprintf('    After correction: [%.3e, %.3e] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
        fprintf('    ✓ Data now represents displacement RATE (nm/s)\n');
    else
        fprintf('  Sampling frequency correction: DISABLED (data assumed to be already in nm/s)\n');
    end
    
    % DEBUG: Check data quality after correction
    fprintf('  DEBUG: Corrected data range: [%.3f, %.3f]\n', min(data1Hz(:)), max(data1Hz(:)));
    nan_count = sum(isnan(data1Hz(:)));
    fprintf('  DEBUG: NaN values in loaded data: %d out of %d (%.1f%%)\n', nan_count, numel(data1Hz), (nan_count/numel(data1Hz))*100);
    
    % Apply concatenation artifact filtering if enabled
    if isfield(config, 'apply_concatenation_filter') && config.apply_concatenation_filter
        fprintf('  Applying concatenation artifact filter...\n');
        filter_method = 'detrend';  % Default
        if isfield(config, 'filter_method')
            filter_method = config.filter_method;
        end
        
        % Check if this is a phase correction method
        phase_methods = {'phase_align', 'smooth_transition', 'local_detrend'};
        amplitude_methods = {'rms_normalize', 'adaptive_normalize', 'percentile_normalize'};
        
        if any(strcmp(filter_method, phase_methods))
            % Use phase boundary correction with timing information
            options = struct();
            options.method = filter_method;
            options.diagnostic_threshold = 0.01;
            options.correction_window = 10;
            options.test_channels = 450:470;
            
            data1Hz = phase_boundary_correction(data1Hz, test_timing, options);
            
        elseif any(strcmp(filter_method, amplitude_methods))
            % Use amplitude normalization correction
            options = struct();
            options.method = filter_method;
            options.reference_method = 'median';
            options.test_channels = 450:470;
            options.smoothing = contains(filter_method, 'adaptive');
            
            data1Hz = amplitude_normalization_correction(data1Hz, test_timing, options);
            
        else
            % Use standard filtering
            data1Hz = filter_concatenation_artifacts(data1Hz, filter_method);
        end
    end
    
    % Get calibration parameters - try dataset-specific, fallback to dynamic default
    if isfield(calibration, test_label)
        cal_params = calibration.(test_label);
        fprintf('  Using dataset-specific calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01A')
        cal_params = calibration.PT01a;
        fprintf('  Using PT01a calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01B') 
        cal_params = calibration.PT01b;
        fprintf('  Using PT01b calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01C')
        cal_params = calibration.PT01c;
        fprintf('  Using PT01c calibration for %s\n', test_label);
    else
        cal_params = calibration.dynamic_default;
        fprintf('  Using dynamic_default calibration for %s\n', test_label);
    end
    
    C1 = cal_params.C1;
    MperChan = cal_params.MperChan;
    zone_min_ft = cal_params.zone_min_ft;
    zone_max_ft = cal_params.zone_max_ft;
    
    fprintf('  Calibration: C1=%d, MperChan=%.3f\n', C1, MperChan);
    
    % Calculate depth array (from simple script)
    channels = 1:size(data1Hz, 2);
    depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
    
    % Create time array with timing adjustment
    data_start = test_timing.start;
    
    % Apply DAS timing adjustment if specified
    if isfield(test_timing, 'das_timing_adjustment') && test_timing.das_timing_adjustment ~= 0
        data_start = data_start + seconds(test_timing.das_timing_adjustment);
        fprintf('  Applied DAS timing adjustment: +%d seconds\n', test_timing.das_timing_adjustment);
    end
    
    n_samples = size(data1Hz, 1);
    time_array = data_start + seconds(0:n_samples-1);
            
    % Apply configurable smoothing (from simple script approach)
    if isfield(config, 'disable_analysis_smoothing') && config.disable_analysis_smoothing
        fprintf('  Smoothing disabled by config\n');
        smoothed_data = data1Hz;  % No smoothing
    else
        % Apply smoothing based on config
        smoothing_method = 'movmean';
        if isfield(config, 'smoothing_method')
            smoothing_method = config.smoothing_method;
        end
        
        % Use new unified filter system
        addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'filter'));
        
        switch lower(smoothing_method)
            case 'movmean'
                % Use config window if specified, otherwise use calculated smooth_window
                if isfield(config, 'movavg_window') && ~isempty(config.movavg_window)
                    config.temporal_window = config.movavg_window;
                else
                    config.temporal_window = smooth_window;
                end
                smoothed_data = apply_filter(data1Hz, 'movmean', config);
            case 'movmedian'
                config.temporal_window = smooth_window;
                smoothed_data = apply_filter(data1Hz, 'movmedian', config);
            case 'gaussian'
                % Gaussian smoothing (legacy)
                sigma = smooth_window / 3;
                smoothed_data = imgaussfilt(data1Hz, sigma);
            case 'chen_full'
                % Complete Chen et al. (2023) 3-stage framework
                fprintf('  Applying Chen et al. complete framework...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_full', config);
            case 'chen_stage1'
                % Chen Stage 1: Bandpass only
                fprintf('  Applying Chen Stage 1 (bandpass)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage1', config);
            case 'chen_stage2'
                % Chen Stage 2: SOMF only
                fprintf('  Applying Chen Stage 2 (SOMF)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage2', config);
            case 'chen_stage3'
                % Chen Stage 3: F-K filter only (KEY for grid patterns)
                fprintf('  Applying Chen Stage 3 (F-K dip filter)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage3', config);
            case 'spatial_median'
                % Spatial median filter
                fprintf('  Applying spatial median filtering...\n');
                smoothed_data = apply_filter(data1Hz, 'spatial_median', config);
            case 'chen'
                % Legacy Chen - redirect to complete framework
                fprintf('  Applying Chen et al. complete framework (legacy)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_full', config);
            case 'ensemble'
                % Multi-channel ensemble averaging (signal extraction)
                fprintf('  Applying ensemble averaging (signal extraction)...\n');
                config.depth_ft = depth_ft;  % Pass depth information to filter
                smoothed_data = apply_filter(data1Hz, 'ensemble', config);
            case 'dual_bandstop'
                % Targeted grid pattern removal
                fprintf('  Applying dual bandstop filter (grid pattern removal)...\n');
                config.sampling_rate = 1.0;  % 1Hz decimated data
                smoothed_data = apply_filter(data1Hz, 'dual_bandstop', config);
            case 'matlab_movmean'
                % Direct MATLAB movmean implementation with configurable window
                fprintf('  Applying MATLAB movmean filter...\n');
                smoothed_data = apply_filter(data1Hz, 'matlab_movmean', config);
            case 'none'
                smoothed_data = data1Hz;  % No smoothing
            otherwise
                fprintf('  Warning: Unknown smoothing method %s, using movmean\n', smoothing_method);
                config.temporal_window = smooth_window;
                smoothed_data = apply_filter(data1Hz, 'movmean', config);
        end
        % Report the window size used
        if strcmp(smoothing_method, 'matlab_movmean') && isfield(config, 'matlab_movmean_window')
            actual_window = config.matlab_movmean_window;
            fprintf('  Using MATLAB movmean with window=%d samples (%.1f seconds)\n', actual_window, actual_window);
        else
            actual_window = smooth_window;
        end
        fprintf('  Applied %s smoothing (window: %d)\n', smoothing_method, actual_window);
    end
    
    % DEBUG: Check data after smoothing
    fprintf('  DEBUG: After smoothing data range: [%.3f, %.3f]\n', min(smoothed_data(:)), max(smoothed_data(:)));
    nan_count_smooth = sum(isnan(smoothed_data(:)));
    fprintf('  DEBUG: NaN values after smoothing: %d out of %d (%.1f%%)\n', nan_count_smooth, numel(smoothed_data), (nan_count_smooth/numel(smoothed_data))*100);
    
    % Find representative channel in pumping zone
            zone_mid_ft = (zone_min_ft + zone_max_ft) / 2;
            [~, channel_idx] = min(abs(depth_ft - zone_mid_ft));
            
    % Get analysis window from config
    if isfield(config, 'analysis_windows') && isfield(config.analysis_windows, test_label)
        analysis_start = config.analysis_windows.(test_label).start;
        analysis_end = config.analysis_windows.(test_label).end;
    else
                analysis_start = test_timing.start;
                analysis_end = test_timing.end;
            end
            analysis_mask = time_array >= analysis_start & time_array <= analysis_end;
            
    % Apply time shift if configured (for alignment with head data)
    if isfield(config, 'das_time_shift_seconds') && config.das_time_shift_seconds ~= 0
        time_array_shifted = time_array + seconds(config.das_time_shift_seconds);
        fprintf('  Applied DAS time shift: +%d seconds\n', config.das_time_shift_seconds);
    else
        time_array_shifted = time_array;
    end
    
    % Store essential results (simplified structure)
    das_results.(test_label).data_file = das_filepath;
    das_results.(test_label).time_array = time_array_shifted;  % Use shifted time
    das_results.(test_label).smoothed_data = smoothed_data;
    % Store smoothing method info for verification
    if isfield(config, 'smoothing_method')
        das_results.(test_label).smoothing_method = config.smoothing_method;
        if strcmp(config.smoothing_method, 'matlab_movmean') && isfield(config, 'matlab_movmean_window')
            das_results.(test_label).smoothing_window = config.matlab_movmean_window;
        end
    end
    das_results.(test_label).depth_ft = depth_ft;
    das_results.(test_label).C1 = C1;
    das_results.(test_label).MperChan = MperChan;
    das_results.(test_label).pumping_zone.min_ft = zone_min_ft;
    das_results.(test_label).pumping_zone.max_ft = zone_max_ft;
    das_results.(test_label).pumping_zone.channel_idx = channel_idx;
    das_results.(test_label).pumping_zone.channel_depth_ft = depth_ft(channel_idx);
            das_results.(test_label).analysis_time = time_array_shifted(analysis_mask);  % Use shifted time
    das_results.(test_label).analysis_strain_rate = smoothed_data(analysis_mask, channel_idx);
            
    fprintf('  ✓ DAS analysis completed for %s\n', test_label);
    fprintf('    Representative channel: %d at %.1f ft\n', channel_idx, depth_ft(channel_idx));
            fprintf('    Analysis window: %d data points\n', sum(analysis_mask));
end

fprintf('\n=== DAS DATA ANALYSIS COMPLETE ===\n');

end


