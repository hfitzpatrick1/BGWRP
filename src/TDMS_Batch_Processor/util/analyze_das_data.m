function das_results = analyze_das_data(timing_config, test_labels, config)
%ANALYZE_DAS_DATA Dynamic DAS data analysis utility
%
% Analyzes DAS strain rate data for any number of tests using
% timing configuration from batch processor
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

%% DAS analysis parameters (should be configurable)
% These could be moved to config structure
das_params = struct();
das_params.smooth_window = 10;
das_params.decimation_factor = 100;  % From batch processor config

% Default DAS calibration parameters (can be overridden per test)
das_params.default_C1 = 513;
das_params.default_MperChan = 0.25;

%% Analyze DAS data for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Analyzing DAS data for test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if isfield(timing_config, test_label)
        test_timing = timing_config.(test_label);
        
        % Need to find the source folder name for this test
        source_folder = find_source_folder_for_test(test_label, config);
        
        if ~isempty(source_folder)
            % Look for concatenated DAS data file in dynamic structure
            das_filename = sprintf('Dataset_%s_1Hz.mat', source_folder);
            das_filepath_concatenated = fullfile(config.base_input, '_concatenated', source_folder, das_filename);
            das_filepath_active = fullfile(config.base_input, '_active', source_folder, das_filename);
        else
            % Fallback to old naming scheme
            das_filename = sprintf('Dataset_%s_1Hz.mat', test_label);
            das_filepath_concatenated = fullfile(config.base_input, '_concatenated', das_filename);
            das_filepath_active = fullfile(config.base_input, '_active', das_filename);
        end
        
        if exist(das_filepath_concatenated, 'file')
            das_filepath = das_filepath_concatenated;
        elseif exist(das_filepath_active, 'file')
            das_filepath = das_filepath_active;
        else
            das_filepath = das_filepath_active; % For error reporting
        end
        
        if exist(das_filepath, 'file')
            fprintf('  Loading DAS data: %s\n', das_filename);
            
            % Load DAS data
            load(das_filepath, 'decdata');
            
            % Create time array for DAS data
            % Use timing from batch processor
            data_start = test_timing.start;
            n_samples = size(decdata, 1);
            time_array = data_start + seconds(0:n_samples-1);
            
            fprintf('  DAS data: %d samples, %d channels\n', size(decdata, 1), size(decdata, 2));
            fprintf('  Time range: %s to %s\n', min(time_array), max(time_array));
            
            % Store DAS results
            das_results.(test_label).data_file = das_filename;
            das_results.(test_label).time_array = time_array;
            das_results.(test_label).data_size = size(decdata);
            das_results.(test_label).time_range.start = min(time_array);
            das_results.(test_label).time_range.end = max(time_array);
            
            % Apply smoothing
            smoothed_data = movmean(decdata, das_params.smooth_window, 1);
            das_results.(test_label).smoothed_data = smoothed_data;
            
            % Calculate depth array and channel parameters (from PM07_Recovery_Analysis.m)
            channels = 1:size(decdata, 2);
            
            % Use test-specific calibration parameters
            if strcmp(test_label, 'c')
                C1 = 110;  % PT-01c uses different reference channel
            else
                C1 = das_params.default_C1;  % PT-01a and PT-01b use 513
            end
            
            depth_ft = ((channels - C1 - 1) * das_params.default_MperChan) / 0.3048;
            das_results.(test_label).depth_ft = depth_ft;
            das_results.(test_label).C1 = C1;
            das_results.(test_label).MperChan = das_params.default_MperChan;
            
            % Define pumping zone for this test (from PM07_Recovery_Analysis.m)
            switch test_label
                case 'a'
                    zone_min_ft = 450; zone_max_ft = 510;
                case 'b'
                    zone_min_ft = 350; zone_max_ft = 400;
                case 'c'
                    zone_min_ft = 260; zone_max_ft = 310;
                otherwise
                    zone_min_ft = 300; zone_max_ft = 500;  % Default range
            end
            
            % Find channel in middle of pumping zone
            zone_mid_ft = (zone_min_ft + zone_max_ft) / 2;
            [~, channel_idx] = min(abs(depth_ft - zone_mid_ft));
            
            das_results.(test_label).pumping_zone.min_ft = zone_min_ft;
            das_results.(test_label).pumping_zone.max_ft = zone_max_ft;
            das_results.(test_label).pumping_zone.mid_ft = zone_mid_ft;
            das_results.(test_label).pumping_zone.channel_idx = channel_idx;
            das_results.(test_label).pumping_zone.channel_depth_ft = depth_ft(channel_idx);
            
            % Extract strain rate for representative channel
            strain_rate = smoothed_data(:, channel_idx);
            das_results.(test_label).strain_rate = strain_rate;
            
            % Filter to analysis window
            analysis_start = test_timing.start;
            analysis_end = test_timing.end;
            analysis_mask = time_array >= analysis_start & time_array <= analysis_end;
            
            das_results.(test_label).analysis_time = time_array(analysis_mask);
            das_results.(test_label).analysis_strain_rate = strain_rate(analysis_mask);
            das_results.(test_label).analysis_points = sum(analysis_mask);
            
            fprintf('  ✓ DAS analysis completed\n');
            fprintf('    Representative channel: %d at %.1f ft (target: %.1f ft)\n', ...
                channel_idx, depth_ft(channel_idx), zone_mid_ft);
            fprintf('    Analysis window: %d data points\n', sum(analysis_mask));
            
        else
            fprintf('  ⚠ DAS data file not found: %s\n', das_filepath);
            das_results.(test_label).error = 'das_file_not_found';
        end
        
    else
        fprintf('  WARNING: No timing data found for test %s\n', test_label);
        das_results.(test_label).error = 'no_timing_data';
    end
end

fprintf('\n=== DAS DATA ANALYSIS COMPLETE ===\n');

end

function source_folder = find_source_folder_for_test(test_label, config)
%FIND_SOURCE_FOLDER_FOR_TEST Find the source folder name for a given test label
    source_folder = '';
    
    % Try to get workspace info from base workspace
    try
        workspace_info = evalin('base', 'workspace_info');
        if isfield(workspace_info, 'input_folders')
            for i = 1:length(workspace_info.input_folders)
                folder_name = workspace_info.input_folders{i};
                if contains(folder_name, test_label) || ...
                   (strcmp(test_label, 'a') && contains(folder_name, 'PT01a')) || ...
                   (strcmp(test_label, 'b') && contains(folder_name, 'PT01b')) || ...
                   (strcmp(test_label, 'c') && contains(folder_name, 'PT01c'))
                    source_folder = folder_name;
                    break;
                end
            end
        end
    catch
        % workspace_info not available, continue with empty source_folder
    end
end
