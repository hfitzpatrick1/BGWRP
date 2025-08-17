function analysis_results = analyze_head_data(timing_config, test_labels, config)
%ANALYZE_HEAD_DATA Dynamic head data analysis utility
%
% Analyzes head data (drawdown/recovery) for any number of tests using
% timing configuration from batch processor
%
% Inputs:
%   timing_config - Timing configuration from batch processor
%   test_labels   - Cell array of test labels (e.g., {'a', 'b', 'c'})
%   config        - Batch processor configuration structure
%
% Outputs:
%   analysis_results - Structure containing analysis results for all tests

fprintf('=== HEAD DATA ANALYSIS ===\n');

% Initialize results structure
analysis_results = struct();
analysis_results.tests = test_labels;
analysis_results.timing = timing_config;

%% Analysis parameters (configurable)
smooth_window = 10;  % Moving average window
head_timing_adjustment_c = 10;  % Adjustment for test c (can be parameterized)

%% Load and analyze data for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Analyzing test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if isfield(timing_config, test_label)
        test_timing = timing_config.(test_label);
        
        % Define analysis window (using extracted timing)
        analysis_start = test_timing.start;
        analysis_end = test_timing.end;
        analysis_duration = minutes(analysis_end - analysis_start);
        
        fprintf('Analysis window: %s to %s (%.1f minutes)\n', ...
            analysis_start, analysis_end, analysis_duration);
        
        % Store timing info
        analysis_results.(test_label).timing.start = analysis_start;
        analysis_results.(test_label).timing.end = analysis_end;
        analysis_results.(test_label).timing.duration_minutes = analysis_duration;
        
        % Look for head data files in project data directory
        head_data_dir = 'C:\Coding\BGWRP\data\head';
        head_files = dir(fullfile(head_data_dir, sprintf('head_%s_z*.mat', test_label)));
        
        fprintf('  Looking for head data files: head_%s_z*.mat in %s\n', test_label, head_data_dir);
        fprintf('  Found %d head data files\n', length(head_files));
        
        if length(head_files) > 0
            for j = 1:length(head_files)
                head_file = head_files(j);
                fprintf('    Loading: %s\n', head_file.name);
                % Load head data here
            end
        else
            fprintf('  No head data files found\n');
        end
        
        % Initialize results structure for this test
        analysis_results.(test_label).zones = struct();
        analysis_results.(test_label).summary = struct();
        
    else
        fprintf('  WARNING: No timing data found for test %s\n', test_label);
        analysis_results.(test_label).error = 'no_timing_data';
    end
end

fprintf('\n=== HEAD DATA ANALYSIS COMPLETE ===\n');

end
