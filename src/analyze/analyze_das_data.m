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
smooth_window = 10;

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
    
    % Simple file discovery - find any MAT file in the dataset directory
    dataset_name = test_timing.dataset_name;
    dataset_dirs = {
        fullfile(config.base_input, '_active', dataset_name);
        fullfile(config.base_input, '_concatenated', dataset_name);
    };
    
    das_filepath = '';
    for dir_idx = 1:length(dataset_dirs)
        dataset_dir = dataset_dirs{dir_idx};
        if exist(dataset_dir, 'dir')
            mat_files = dir(fullfile(dataset_dir, '*.mat'));
            % Filter out timing config files
            data_files = mat_files(~contains({mat_files.name}, 'get_timing'));
            
            if length(data_files) == 1
                das_filepath = fullfile(dataset_dir, data_files(1).name);
                fprintf('  Found data file: %s\n', data_files(1).name);
                break;
            elseif length(data_files) > 1
                error('Multiple data MAT files found in %s - cannot determine which to use', dataset_dir);
            end
        end
    end
    
    if isempty(das_filepath)
        fprintf('  ⚠ DAS data file not found for %s\n', dataset_name);
        das_results.(test_label).error = 'das_file_not_found';
        continue;
    end
    
    fprintf('  Loading DAS data: %s\n', das_filepath);
    
    % Load DAS data (following PM07_PT01c_Simple.m approach)
    load(das_filepath, 'decdata');
    data1Hz = decdata;  % Use naming from simple script
    
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
    
    % Get calibration parameters - simple lookup based on dataset name
    test_type = 'PT01c';  % Default
    if contains(upper(dataset_name), 'PT01A')
        test_type = 'PT01a';
    elseif contains(upper(dataset_name), 'PT01B')
        test_type = 'PT01b';
    end
    
    C1 = calibration.(test_type).C1;
    MperChan = calibration.(test_type).MperChan;
    zone_min_ft = calibration.(test_type).zone_min_ft;
    zone_max_ft = calibration.(test_type).zone_max_ft;
    
    fprintf('  Using %s calibration: C1=%d, MperChan=%.3f\n', test_type, C1, MperChan);
    
    % Calculate depth array (from simple script)
    channels = 1:size(data1Hz, 2);
    depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
    
    % Create time array
            data_start = test_timing.start;
    n_samples = size(data1Hz, 1);
            time_array = data_start + seconds(0:n_samples-1);
            
    % Apply smoothing (from simple script approach)
    smoothed_data = movmean(data1Hz, smooth_window, 1);
    
    % Find representative channel in pumping zone
            zone_mid_ft = (zone_min_ft + zone_max_ft) / 2;
            [~, channel_idx] = min(abs(depth_ft - zone_mid_ft));
            
    % Get analysis window from config
    if isfield(config, 'analysis_windows') && isfield(config.analysis_windows, dataset_name)
        analysis_start = config.analysis_windows.(dataset_name).start;
        analysis_end = config.analysis_windows.(dataset_name).end;
    else
                analysis_start = test_timing.start;
                analysis_end = test_timing.end;
            end
            analysis_mask = time_array >= analysis_start & time_array <= analysis_end;
            
    % Store essential results (simplified structure)
    das_results.(test_label).data_file = das_filepath;
    das_results.(test_label).time_array = time_array;
    das_results.(test_label).smoothed_data = smoothed_data;
    das_results.(test_label).depth_ft = depth_ft;
    das_results.(test_label).C1 = C1;
    das_results.(test_label).MperChan = MperChan;
    das_results.(test_label).pumping_zone.min_ft = zone_min_ft;
    das_results.(test_label).pumping_zone.max_ft = zone_max_ft;
    das_results.(test_label).pumping_zone.channel_idx = channel_idx;
    das_results.(test_label).pumping_zone.channel_depth_ft = depth_ft(channel_idx);
            das_results.(test_label).analysis_time = time_array(analysis_mask);
    das_results.(test_label).analysis_strain_rate = smoothed_data(analysis_mask, channel_idx);
            
    fprintf('  ✓ DAS analysis completed for %s\n', test_type);
    fprintf('    Representative channel: %d at %.1f ft\n', channel_idx, depth_ft(channel_idx));
            fprintf('    Analysis window: %d data points\n', sum(analysis_mask));
end

fprintf('\n=== DAS DATA ANALYSIS COMPLETE ===\n');

end


