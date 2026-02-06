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

console_log('=== DAS DATA ANALYSIS ===\n');

% DEBUG: Check if config has dataset_smoothing when function is called
console_log('DEBUG analyze_das_data ENTRY: Checking config.dataset_smoothing...\n');
if isfield(config, 'dataset_smoothing')
    ds_fields = fieldnames(config.dataset_smoothing);
    console_log('  ✓ config.dataset_smoothing EXISTS with fields: %s\n', strjoin(ds_fields, ', '));
else
    console_log('  ✗ config.dataset_smoothing DOES NOT EXIST in config struct\n');
    all_fields = fieldnames(config);
    console_log('  Available config fields (%d total): %s...\n', length(all_fields), strjoin(all_fields(1:min(10,end)), ', '));
end

% Initialize results structure
das_results = struct();
das_results.tests = test_labels;
das_results.timing = timing_config;

%% Simple DAS parameters (based on PM07_PT01c_Simple.m approach)
% Configurable smoothing parameters
% NOTE: This default is overridden by dataset-specific config later
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
    console_log('\n--- Analyzing DAS data for test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if ~isfield(timing_config, test_label)
        console_log('  WARNING: No timing data found for test %s\n', test_label);
        das_results.(test_label).error = 'no_timing_data';
        continue;
    end
    
        test_timing = timing_config.(test_label);
    
    % Simple file discovery - look only in _active datasets
    % Find exactly one .mat file in _das subdirectory
    dataset_dir = fullfile(config.base_input, '_active', test_label);
    das_subdir = fullfile(dataset_dir, '_das');
    
    if ~exist(das_subdir, 'dir')
        console_log('  ⚠ _das subdirectory not found for %s\n', test_label);
        das_results.(test_label).error = 'das_subdir_not_found';
        continue;
    end
    
    % Find all .mat files in _das subdirectory
    mat_files = dir(fullfile(das_subdir, '*.mat'));
    
    if length(mat_files) == 0
        console_log('  ⚠ No .mat files found in _das subdirectory for %s\n', test_label);
        das_results.(test_label).error = 'no_das_files';
        continue;
    elseif length(mat_files) > 1
        console_log('  ⚠ Multiple .mat files found in _das subdirectory for %s:\n', test_label);
        for i = 1:length(mat_files)
            console_log('    %s\n', mat_files(i).name);
        end
        das_results.(test_label).error = 'multiple_das_files';
        continue;
    end
    
    % Found exactly one .mat file - use it
    das_filepath = fullfile(das_subdir, mat_files(1).name);
    console_log('  Found DAS data file: %s\n', mat_files(1).name);
    
    console_log('  Loading DAS data: %s\n', das_filepath);
    
    % Load DAS data (handle multiple variable naming conventions)
    loaded_data = load(das_filepath);
    if isfield(loaded_data, 'decdata')
        data1Hz = loaded_data.decdata;
        console_log('  Loaded decimated data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    elseif isfield(loaded_data, 'fulldata')
        data1Hz = loaded_data.fulldata;
        console_log('  Loaded full-resolution data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    elseif isfield(loaded_data, 'Data')
        data1Hz = loaded_data.Data;
        console_log('  Loaded processed data: [%d x %d]\n', size(data1Hz, 1), size(data1Hz, 2));
    else
        % Show available variables to help debug
        available_vars = fieldnames(loaded_data);
        console_log('  Available variables in file: %s\n', strjoin(available_vars, ', '));
        error('No valid data variable found. Expected ''decdata'', ''fulldata'', or ''Data''');
    end
    
    % OPTIONAL: Convert from nm/sample to nm/s
    % Only apply if explicitly enabled via config flag
    % This corrects for TDMS conversion not multiplying by sampling frequency
    if isfield(config, 'apply_sampling_freq_correction') && config.apply_sampling_freq_correction
    % Determine the actual sampling frequency of THIS file
    if isfield(loaded_data, 'decdata')
        % DECIMATED data: Need to determine if units are correct
        % The check_tdms_units script showed values are ~±330, which is 1300x too large
        % This suggests the data might already be in wrong units or scale
        % For now, DON'T apply conversion - investigate the actual issue
        sampling_freq = 1.0;  % Don't convert - investigate first
        console_log('  ℹ DECIMATED DATA - NOT applying sampling frequency conversion\n');
        console_log('    Data appears to have unit/scale issues (check_tdms_units showed ~±330)\n');
        console_log('    Need to investigate actual units before applying conversion\n');
        console_log('    Current range will be checked against advisor''s ~±0.25 nm/s\n');
        elseif isfield(loaded_data, 'fs_f')
            % Use the stored sampling frequency (for non-decimated data)
            sampling_freq = loaded_data.fs_f;  % Hz
            console_log('  ⚠ APPLYING SAMPLING FREQUENCY CORRECTION\n');
            console_log('    Data type: Original or full-resolution\n');
            console_log('    Stored sampling frequency: %.2f Hz\n', sampling_freq);
        else
            % Default fallback
            sampling_freq = 1.0;  % Hz (assume 1 Hz decimated data)
            console_log('  ⚠ WARNING: No sampling frequency (fs_f) found in file!\n');
            console_log('    Assuming decimated data at 1 Hz\n');
        end
        
        console_log('    Data was saved as nm/sample, converting to nm/s\n');
        console_log('    Using sampling frequency: %.2f Hz\n', sampling_freq);
        console_log('    Before correction: [%.3e, %.3e] nm/sample\n', min(data1Hz(:)), max(data1Hz(:)));
        
        data1Hz = data1Hz * sampling_freq;  % Convert nm/sample → nm/s
        
        console_log('    After correction: [%.3e, %.3e] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
        console_log('    ✓ Data now represents displacement RATE (nm/s)\n');
    else
        console_log('  Sampling frequency correction: DISABLED (data assumed to be already in nm/s)\n');
    end
    
    % DEBUG: Check data quality after correction
    console_log('  DEBUG: Corrected data range: [%.3f, %.3f]\n', min(data1Hz(:)), max(data1Hz(:)));
    nan_count = sum(isnan(data1Hz(:)));
    console_log('  DEBUG: NaN values in loaded data: %d out of %d (%.1f%%)\n', nan_count, numel(data1Hz), (nan_count/numel(data1Hz))*100);
    
    % Apply concatenation artifact filtering if enabled
    if isfield(config, 'apply_concatenation_filter') && config.apply_concatenation_filter
        console_log('  Applying concatenation artifact filter...\n');
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
        console_log('  Using dataset-specific calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01A')
        cal_params = calibration.PT01a;
        console_log('  Using PT01a calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01B') 
        cal_params = calibration.PT01b;
        console_log('  Using PT01b calibration for %s\n', test_label);
    elseif contains(upper(test_label), 'PT01C')
        cal_params = calibration.PT01c;
        console_log('  Using PT01c calibration for %s\n', test_label);
    else
        cal_params = calibration.dynamic_default;
        console_log('  Using dynamic_default calibration for %s\n', test_label);
    end
    
    C1 = cal_params.C1;
    MperChan = cal_params.MperChan;
    zone_min_ft = cal_params.zone_min_ft;
    zone_max_ft = cal_params.zone_max_ft;
    
    console_log('  Calibration: C1=%d, MperChan=%.3f\n', C1, MperChan);
    
    % Calculate depth array (from simple script)
    channels = 1:size(data1Hz, 2);
    depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
    
    % Create time array with timing adjustment
    data_start = test_timing.start;
    
    % Apply DAS timing adjustment if specified
    if isfield(test_timing, 'das_timing_adjustment') && test_timing.das_timing_adjustment ~= 0
        data_start = data_start + seconds(test_timing.das_timing_adjustment);
        console_log('  Applied DAS timing adjustment: +%d seconds\n', test_timing.das_timing_adjustment);
    end
    
    n_samples = size(data1Hz, 1);
    time_array = data_start + seconds(0:n_samples-1);
    
    % Check for dataset-specific smoothing configuration
    % Keys are stored in UPPERCASE (e.g., PT01A_RECOVERY_SHORT), so convert test_label
    test_label_upper = upper(strrep(test_label, ' ', '_'));
    console_log('  DEBUG: Checking dataset-specific smoothing for test_label="%s" (key="%s")\n', test_label, test_label_upper);
    if isfield(config, 'dataset_smoothing')
        console_log('    DEBUG: config.dataset_smoothing exists\n');
        if isfield(config.dataset_smoothing, test_label_upper)
            console_log('    DEBUG: Found config for %s\n', test_label_upper);
            ds_config = config.dataset_smoothing.(test_label_upper);
            if isfield(ds_config, 'fs') && isfield(ds_config, 'preprocessing_window_sec')
                % Convert smoothing window from seconds to samples based on sampling rate
                smooth_window = round(ds_config.preprocessing_window_sec * ds_config.fs);
                % Override the global config with dataset-specific value
                config.matlab_movmean_window = smooth_window;
                console_log('  ✓ Using dataset-specific smoothing: %d seconds = %d samples at %d Hz\n', ...
                    ds_config.preprocessing_window_sec, smooth_window, ds_config.fs);
            else
                console_log('    DEBUG: Missing fs or preprocessing_window_sec fields\n');
            end
        else
            console_log('    DEBUG: No config found for key="%s" (from test_label="%s")\n', test_label_upper, test_label);
            if isfield(config, 'dataset_smoothing')
                available = fieldnames(config.dataset_smoothing);
                console_log('    DEBUG: Available configs: %s\n', strjoin(available, ', '));
            end
        end
    else
        console_log('    DEBUG: config.dataset_smoothing does NOT exist\n');
    end
            
    % Apply configurable smoothing (from simple script approach)
    if isfield(config, 'disable_analysis_smoothing') && config.disable_analysis_smoothing
        console_log('  Smoothing disabled by config\n');
        smoothed_data = data1Hz;  % No smoothing
    else
        % Apply smoothing based on config
        smoothing_method = 'movmean';
        if isfield(config, 'smoothing_method')
            smoothing_method = config.smoothing_method;
        end
        
        % Use new unified filter system
        addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'filter'));
        
        % Apply bad channel masking if enabled (removes horizontal artifacts)
        if isfield(config, 'mask_bad_channels') && config.mask_bad_channels
            data1Hz = mask_bad_channels(data1Hz, depth_ft, config);
        end
        
        % Apply spatial common mode removal if enabled (removes vertical banding)
        if isfield(config, 'apply_spatial_common_mode_removal') && config.apply_spatial_common_mode_removal
            console_log('  Applying spatial common mode removal (removes vertical bands)...\n');
            console_log('    Original data range: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            data_before_cm_removal = data1Hz;
            % At each time point, subtract the spatial average (average across all channels)
            spatial_mean = mean(data1Hz, 2, 'omitnan');  % Average across channels (dim 2)
            data1Hz = data1Hz - repmat(spatial_mean, 1, size(data1Hz, 2));  % Subtract from all channels
            console_log('    After spatial common mode removal: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            console_log('    Removed common mode component with range: [%.3f, %.3f] nm/s\n', min(spatial_mean), max(spatial_mean));
        end
        
        % Apply spatial median common mode removal if enabled (more robust, preserves signal better)
        if isfield(config, 'apply_spatial_median_removal') && config.apply_spatial_median_removal
            console_log('  Applying spatial median common mode removal (robust, preserves signal)...\n');
            console_log('    Original data range: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            % At each time point, subtract the spatial median (median across all channels)
            % This is more robust to outliers and preserves local signals better
            spatial_median = median(data1Hz, 2, 'omitnan');  % Median across channels (dim 2)
            data1Hz = data1Hz - repmat(spatial_median, 1, size(data1Hz, 2));  % Subtract from all channels
            console_log('    After spatial median removal: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            console_log('    Removed common mode component (median) with range: [%.3f, %.3f] nm/s\n', min(spatial_median), max(spatial_median));
        end
        
        % Apply reference channel subtraction if enabled (subtract a channel far from signal)
        if isfield(config, 'apply_reference_channel_subtraction') && config.apply_reference_channel_subtraction
            console_log('  Applying reference channel subtraction (preserves local signals)...\n');
            console_log('    Original data range: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            % Use a channel far from the pumping zone (e.g., shallow or deep) as reference
            % This captures common mode but not local signals
            if isfield(config, 'reference_channel_idx') && ~isempty(config.reference_channel_idx)
                ref_ch_idx = config.reference_channel_idx;
            else
                % Default: use channel at 200 ft (shallow, away from pumping zone at 350-400 ft)
                ref_depth_ft = 200;
                [~, ref_ch_idx] = min(abs(depth_ft - ref_depth_ft));
            end
            console_log('    Using reference channel %d at %.1f ft\n', ref_ch_idx, depth_ft(ref_ch_idx));
            reference_signal = data1Hz(:, ref_ch_idx);  % Reference channel time series
            data1Hz = data1Hz - repmat(reference_signal, 1, size(data1Hz, 2));  % Subtract from all channels
            console_log('    After reference channel subtraction: [%.3f, %.3f] nm/s\n', min(data1Hz(:)), max(data1Hz(:)));
            console_log('    Reference channel range: [%.3f, %.3f] nm/s\n', min(reference_signal), max(reference_signal));
        end
        
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
                console_log('  Applying Chen et al. complete framework...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_full', config);
            case 'chen_stage1'
                % Chen Stage 1: Bandpass only
                console_log('  Applying Chen Stage 1 (bandpass)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage1', config);
            case 'chen_stage2'
                % Chen Stage 2: SOMF only
                console_log('  Applying Chen Stage 2 (SOMF)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage2', config);
            case 'chen_stage3'
                % Chen Stage 3: F-K filter only (KEY for grid patterns)
                console_log('  Applying Chen Stage 3 (F-K dip filter)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_stage3', config);
            case 'spatial_median'
                % Spatial median filter
                console_log('  Applying spatial median filtering...\n');
                smoothed_data = apply_filter(data1Hz, 'spatial_median', config);
            case 'chen'
                % Legacy Chen - redirect to complete framework
                console_log('  Applying Chen et al. complete framework (legacy)...\n');
                smoothed_data = apply_filter(data1Hz, 'chen_full', config);
            case 'ensemble'
                % Multi-channel ensemble averaging (signal extraction)
                console_log('  Applying ensemble averaging (signal extraction)...\n');
                config.depth_ft = depth_ft;  % Pass depth information to filter
                smoothed_data = apply_filter(data1Hz, 'ensemble', config);
            case 'dual_bandstop'
                % Targeted grid pattern removal
                console_log('  Applying dual bandstop filter (grid pattern removal)...\n');
                config.sampling_rate = 1.0;  % 1Hz decimated data
                smoothed_data = apply_filter(data1Hz, 'dual_bandstop', config);
            case 'matlab_movmean'
                % Direct MATLAB movmean implementation with configurable window
                console_log('  Applying MATLAB movmean filter...\n');
                smoothed_data = apply_filter(data1Hz, 'matlab_movmean', config);
            case 'resample_antialias'
                % Resample anti-aliasing filter (same as decimation uses)
                console_log('  Applying resample anti-aliasing filter...\n');
                smoothed_data = apply_filter(data1Hz, 'resample_antialias', config);
            case 'none'
                smoothed_data = data1Hz;  % No smoothing
            otherwise
                console_log('  Warning: Unknown smoothing method %s, using movmean\n', smoothing_method);
                config.temporal_window = smooth_window;
                smoothed_data = apply_filter(data1Hz, 'movmean', config);
        end
        % Report the window size used
        if strcmp(smoothing_method, 'matlab_movmean') && isfield(config, 'matlab_movmean_window')
            actual_window = config.matlab_movmean_window;
            console_log('  Using MATLAB movmean with window=%d samples (%.1f seconds)\n', actual_window, actual_window);
        else
            actual_window = smooth_window;
        end
        console_log('  Applied %s smoothing (window: %d)\n', smoothing_method, actual_window);
        
        % Apply F-K filter after smoothing if enabled (removes common mode noise)
        if isfield(config, 'filter_method') && strcmp(config.filter_method, 'chen_stage3')
            console_log('  Applying F-K filter after smoothing (common mode removal)...\n');
            smoothed_data = apply_filter(smoothed_data, 'chen_stage3', config);
            console_log('  F-K filter complete\n');
        end
    end
    
    % DEBUG: Check data after smoothing
    console_log('  DEBUG: After smoothing data range: [%.3f, %.3f]\n', min(smoothed_data(:)), max(smoothed_data(:)));
    nan_count_smooth = sum(isnan(smoothed_data(:)));
    console_log('  DEBUG: NaN values after smoothing: %d out of %d (%.1f%%)\n', nan_count_smooth, numel(smoothed_data), (nan_count_smooth/numel(smoothed_data))*100);
    
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
        console_log('  Applied DAS time shift: +%d seconds\n', config.das_time_shift_seconds);
    else
        time_array_shifted = time_array;
    end
    
    % Store essential results (simplified structure)
    das_results.(test_label).data_file = das_filepath;
    das_results.(test_label).time_array = time_array_shifted;  % Use shifted time
    
    % NO CORRECTION FACTOR NEEDED: Using downsample() (no anti-aliasing filter)
    % downsample() preserves amplitude by taking every Nth sample without filtering
    % This matches the advisor's method and gives correct e^-10 strain rates
    % Amplitude is preserved, so plots will match advisor's with proper blue/red colors
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
    
    % Check data range in analysis window only (not full dataset)
    analysis_window_data = das_results.(test_label).smoothed_data(analysis_mask, :);
    console_log('  Analysis window data range: [%.3f, %.3f] nm/s\n', min(analysis_window_data(:)), max(analysis_window_data(:)));
    
    % Extract analysis_strain_rate from smoothed_data (amplitude preserved via downsample())
    analysis_strain_rate = das_results.(test_label).smoothed_data(analysis_mask, channel_idx);
    
    % Flip sign if requested (for sign convention correction)
    if isfield(config, 'flip_displacement_rate_sign') && config.flip_displacement_rate_sign
        console_log('  Flipping displacement rate sign (multiplying by -1)...\n');
        analysis_strain_rate = -analysis_strain_rate;
        das_results.(test_label).smoothed_data = -das_results.(test_label).smoothed_data;
        analysis_window_data = -analysis_window_data;
        console_log('  After sign flip - Analysis window range: [%.3f, %.3f] nm/s\n', min(analysis_window_data(:)), max(analysis_window_data(:)));
    end
    
    das_results.(test_label).analysis_strain_rate = analysis_strain_rate;
            
    console_log('  ✓ DAS analysis completed for %s\n', test_label);
    console_log('    Representative channel: %d at %.1f ft\n', channel_idx, depth_ft(channel_idx));
            console_log('    Analysis window: %d data points\n', sum(analysis_mask));
end

console_log('\n=== DAS DATA ANALYSIS COMPLETE ===\n');

end


