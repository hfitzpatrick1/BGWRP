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
        
        % Look for concatenated DAS data file in _active directory
        das_filename = sprintf('Dataset_%s_1Hz.mat', test_label);
        das_filepath = fullfile(config.base_input, '_active', das_filename);
        
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
            
            % Calculate depth array (using default parameters for now)
            channels = 1:size(decdata, 2);
            depth_ft = ((channels - das_params.default_C1 - 1) * das_params.default_MperChan) / 0.3048;
            das_results.(test_label).depth_ft = depth_ft;
            
            fprintf('  ✓ DAS analysis completed\n');
            
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
