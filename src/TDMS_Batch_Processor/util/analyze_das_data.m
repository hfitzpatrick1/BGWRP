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
        
        % Check if timing config has dataset_name (from _active scan)
        if isfield(test_timing, 'dataset_name')
            dataset_name = test_timing.dataset_name;
            
            % Try multiple naming patterns to handle inconsistencies
            possible_filenames = {
                sprintf('%s_1Hz.mat', dataset_name);            % Direct dataset name
                sprintf('Dataset_%s_1Hz.mat', dataset_name)     % With Dataset_ prefix
            };
            
            das_filepath = '';
            das_filename = '';
            
            for fn = 1:length(possible_filenames)
                test_filename = possible_filenames{fn};
                test_filepath_concatenated = fullfile(config.base_input, '_concatenated', dataset_name, test_filename);
                test_filepath_active = fullfile(config.base_input, '_active', dataset_name, test_filename);
                
                if exist(test_filepath_concatenated, 'file')
                    das_filepath = test_filepath_concatenated;
                    das_filename = test_filename;
                    break;
                elseif exist(test_filepath_active, 'file')
                    das_filepath = test_filepath_active;
                    das_filename = test_filename;
                    break;
                end
            end
            
            if isempty(das_filepath)
                % Default for error reporting
                das_filename = possible_filenames{1};
                das_filepath = fullfile(config.base_input, '_active', dataset_name, das_filename);
            end
            
            fprintf('  Looking for dataset-specific file: %s\n', das_filename);
        else
            % Fallback: find source folder name for this test
            source_folder = find_source_folder_for_test(test_label, config);
            
            if ~isempty(source_folder)
                % Look for concatenated DAS data file in dynamic structure
                das_filename = sprintf('Dataset_%s_1Hz.mat', source_folder);
                if exist(fullfile(config.base_input, '_concatenated', source_folder, das_filename), 'file')
                    das_filepath = fullfile(config.base_input, '_concatenated', source_folder, das_filename);
                elseif exist(fullfile(config.base_input, '_active', source_folder, das_filename), 'file')
                    das_filepath = fullfile(config.base_input, '_active', source_folder, das_filename);
                else
                    das_filepath = fullfile(config.base_input, '_active', source_folder, das_filename); % For error reporting
                end
            else
                % Fallback to old naming scheme
                das_filename = sprintf('Dataset_%s_1Hz.mat', test_label);
                if exist(fullfile(config.base_input, '_concatenated', das_filename), 'file')
                    das_filepath = fullfile(config.base_input, '_concatenated', das_filename);
                elseif exist(fullfile(config.base_input, '_active', das_filename), 'file')
                    das_filepath = fullfile(config.base_input, '_active', das_filename);
                else
                    das_filepath = fullfile(config.base_input, '_active', das_filename); % For error reporting
                end
            end
        end
        
        % File path determined above in the naming pattern loop
        
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
            
            % Use dataset-specific calibration parameters if available
            if isfield(test_timing, 'C1')
                C1 = test_timing.C1;
                fprintf('  Using dataset-specific C1: %d\n', C1);
            else
                % Use dataset name to determine calibration parameters
                dataset_name = '';
                if isfield(test_timing, 'dataset_name')
                    dataset_name = upper(test_timing.dataset_name);
                else
                    dataset_name = upper(test_label);
                end
                
                if contains(dataset_name, 'PT01C') || contains(dataset_name, '_C_') || endsWith(dataset_name, '_C')
                    C1 = 110;  % PT-01c uses different reference channel
                    fprintf('  Using PT-01c calibration C1: %d (from dataset: %s)\n', C1, dataset_name);
                else
                    C1 = das_params.default_C1;  % PT-01a and PT-01b use 513
                    fprintf('  Using default calibration C1: %d (from dataset: %s)\n', C1, dataset_name);
                end
            end
            
            % Use dataset-specific MperChan if available
            if isfield(test_timing, 'MperChan')
                MperChan = test_timing.MperChan;
                fprintf('  Using dataset-specific MperChan: %.3f\n', MperChan);
            else
                MperChan = das_params.default_MperChan;
                fprintf('  Using default MperChan: %.3f\n', MperChan);
            end
            
            depth_ft = ((channels - C1 - 1) * MperChan) / 0.3048;
            das_results.(test_label).depth_ft = depth_ft;
            das_results.(test_label).C1 = C1;
            das_results.(test_label).MperChan = MperChan;
            
            % Define pumping zone - use dataset-specific if available, otherwise derive from source
            if isfield(test_timing, 'pumping_zone_min_ft') && isfield(test_timing, 'pumping_zone_max_ft')
                zone_min_ft = test_timing.pumping_zone_min_ft;
                zone_max_ft = test_timing.pumping_zone_max_ft;
                fprintf('  Using dataset-specific pumping zone: %.0f-%.0f ft\n', zone_min_ft, zone_max_ft);
            else
                % Use dataset name to determine test type directly
                dataset_name = '';
                if isfield(test_timing, 'dataset_name')
                    dataset_name = upper(test_timing.dataset_name);
                else
                    dataset_name = upper(test_label);
                end
                
                % Map based on actual dataset name patterns
                if contains(dataset_name, 'PT01A') || contains(dataset_name, '_A_') || endsWith(dataset_name, '_A')
                    zone_min_ft = 450; zone_max_ft = 510;
                    fprintf('  Using PT-01a pumping zone: %.0f-%.0f ft (from dataset: %s)\n', zone_min_ft, zone_max_ft, dataset_name);
                elseif contains(dataset_name, 'PT01B') || contains(dataset_name, '_B_') || endsWith(dataset_name, '_B')
                    zone_min_ft = 350; zone_max_ft = 400;
                    fprintf('  Using PT-01b pumping zone: %.0f-%.0f ft (from dataset: %s)\n', zone_min_ft, zone_max_ft, dataset_name);
                elseif contains(dataset_name, 'PT01C') || contains(dataset_name, '_C_') || endsWith(dataset_name, '_C')
                    zone_min_ft = 260; zone_max_ft = 310;
                    fprintf('  Using PT-01c pumping zone: %.0f-%.0f ft (from dataset: %s)\n', zone_min_ft, zone_max_ft, dataset_name);
                else
                    zone_min_ft = 300; zone_max_ft = 500;  % Default range
                    fprintf('  Using default pumping zone: %.0f-%.0f ft (unknown dataset: %s)\n', zone_min_ft, zone_max_ft, dataset_name);
                end
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
