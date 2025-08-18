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

%% Recovery rate calculation function (from PM07_Recovery_Analysis.m)
function [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(Date, Drawdownft, recovery_start, recovery_end, smooth_window)
    % Filter to recovery period
    recovery_mask = Date >= recovery_start & Date <= recovery_end;
    recovery_data.Date = Date(recovery_mask);
    recovery_data.Drawdownft = Drawdownft(recovery_mask);
    
    if length(recovery_data.Date) < 2
        recovery_rate_ms = [];
        recovery_time = [];
        return;
    end
    
    % Calculate recovery rate (positive = recovery, negative = continued drawdown)
    drawdown_smooth = movmean(recovery_data.Drawdownft, smooth_window);
    recovery_rate = diff(drawdown_smooth) ./ seconds(diff(recovery_data.Date));
    recovery_rate_ms = recovery_rate * 0.3048;  % Convert to m/s (ft/min * 0.3048 m/ft / 60 s/min)
    recovery_time = recovery_data.Date(1:end-1);
    
    % Note: Positive rate means water level is rising (recovery)
    % Negative rate means water level is still falling
end

%% Load and analyze data for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\n--- Analyzing test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if isfield(timing_config, test_label)
        test_timing = timing_config.(test_label);
        
        % Define analysis window - prioritize batch config analysis_windows over extracted timing
        if isfield(config, 'analysis_windows') && isfield(config.analysis_windows, test_timing.dataset_name)
            % Use configured analysis window from batch config
            analysis_start = config.analysis_windows.(test_timing.dataset_name).start;
            analysis_end = config.analysis_windows.(test_timing.dataset_name).end;
            fprintf('Using configured analysis window from batch config\n');
        elseif isfield(config, 'analysis_windows') && isfield(config.analysis_windows, test_label)
            % Try test label as fallback
            analysis_start = config.analysis_windows.(test_label).start;
            analysis_end = config.analysis_windows.(test_label).end;
            fprintf('Using configured analysis window from batch config\n');
        else
            % Fallback to extracted timing
            analysis_start = test_timing.start;
            analysis_end = test_timing.end;
            fprintf('Using extracted timing (no analysis window configured)\n');
        end
        analysis_duration = minutes(analysis_end - analysis_start);
        
        fprintf('Analysis window: %s to %s (%.1f minutes)\n', ...
            analysis_start, analysis_end, analysis_duration);
        
        % Store timing info
        analysis_results.(test_label).timing.start = analysis_start;
        analysis_results.(test_label).timing.end = analysis_end;
        analysis_results.(test_label).timing.duration_minutes = analysis_duration;
        
        % Look for head data files in multiple possible locations
        possible_dirs = {
            fullfile(config.base_input, '..', '..', 'BGWRP', 'data', 'head');  % Relative to project
            'C:\Coding\BGWRP\data\head';  % Absolute fallback
            fullfile(config.base_input, 'head_data');  % In data directory
            fullfile(config.base_input, '..', 'head')  % Sibling to recovery_extract
        };
        
        % Determine head file pattern from test label FIRST
        head_pattern = '';  % Initialize to prevent undefined variable error
        
        if length(test_label) == 1 && ismember(test_label, {'a', 'b', 'c'})
            % Traditional single-letter test labels
            head_pattern = sprintf('head_%s_z*.mat', test_label);
        else
            % Dynamic dataset names - extract test identifier
            if contains(upper(test_label), 'PT01A') || contains(test_label, '_a_') || endsWith(test_label, '_a')
                head_pattern = 'head_a_z*.mat';
            elseif contains(upper(test_label), 'PT01B') || contains(test_label, '_b_') || endsWith(test_label, '_b')
                head_pattern = 'head_b_z*.mat';
            elseif contains(upper(test_label), 'PT01C') || contains(upper(test_label), 'C')
                head_pattern = 'head_c_z*.mat';
            else
                fprintf('  WARNING: Cannot determine head file pattern for test label: %s\n', test_label);
                head_pattern = 'head_*_z*.mat';  % Try all
            end
        end
        
        head_files = [];
        head_data_dir = '';
        
        for dir_idx = 1:length(possible_dirs)
            test_dir = possible_dirs{dir_idx};
            if exist(test_dir, 'dir')
                test_files = dir(fullfile(test_dir, head_pattern));
                if ~isempty(test_files)
                    head_files = test_files;
                    head_data_dir = test_dir;
                    break;
                end
            end
        end
        fprintf('  Looking for head data files: %s\n', head_pattern);
        if ~isempty(head_files)
            fprintf('  Found %d head data files in: %s\n', length(head_files), head_data_dir);
            
            % Actually load and process the head data
            for j = 1:length(head_files)
                head_file = head_files(j);
                fprintf('    Loading: %s\n', head_file.name);
                
                try
                    head_file_path = fullfile(head_data_dir, head_file.name);
                    % Load variables into a structure to avoid workspace conflicts
                    head_data = load(head_file_path);
                    
                    % Extract zone name (z2, z3, etc.)
                    zone_match = regexp(head_file.name, 'head_[abc]_(z\d+)\.mat', 'tokens');
                    if ~isempty(zone_match)
                        zone_name = zone_match{1}{1};
                        
                        % Store and process head data
                        if isfield(head_data, 'Date') && isfield(head_data, 'Drawdownft') && isfield(head_data, 'Depthft')
                            Date = head_data.Date;
                            Drawdownft = head_data.Drawdownft;
                            Depthft = head_data.Depthft;
                            
                            % Apply dataset-specific timing adjustment
                            timing_adjustment = 0;  % Default: no adjustment
                            
                            % Check if dataset has specific timing adjustment in config
                            if isfield(test_timing, 'head_timing_adjustment')
                                timing_adjustment = test_timing.head_timing_adjustment;
                                fprintf('      Using dataset-specific timing adjustment: +%d seconds\n', timing_adjustment);
                            else
                                % Fallback: use legacy adjustment for PT-01c datasets
                                if contains(upper(test_label), 'C') || contains(upper(test_label), 'PT01C')
                                    timing_adjustment = head_timing_adjustment_c;  % Default 10 seconds
                                    fprintf('      Using legacy PT-01c timing adjustment: +%d seconds\n', timing_adjustment);
                                end
                            end
                            
                            if timing_adjustment ~= 0
                                Date = Date + seconds(timing_adjustment);
                            end
                            Date.TimeZone = 'UTC';
                            
                            % Store raw data
                            analysis_results.(test_label).zones.(zone_name).Date = Date;
                            analysis_results.(test_label).zones.(zone_name).Drawdownft = Drawdownft;
                            analysis_results.(test_label).zones.(zone_name).Depthft = mean(Depthft, 'omitnan');
                            analysis_results.(test_label).zones.(zone_name).n_points = length(Date);
                            analysis_results.(test_label).zones.(zone_name).file = head_file.name;
                            
                            % Calculate recovery rates using extracted timing
                            [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(...
                                Date, Drawdownft, analysis_start, analysis_end, smooth_window);
                            
                            analysis_results.(test_label).zones.(zone_name).recovery_rate_ms = recovery_rate_ms;
                            analysis_results.(test_label).zones.(zone_name).recovery_time = recovery_time;
                            analysis_results.(test_label).zones.(zone_name).recovery_data = recovery_data;
                            
                            if ~isempty(recovery_rate_ms)
                                max_recovery_rate = max(recovery_rate_ms);
                                min_recovery_rate = min(recovery_rate_ms);
                                avg_recovery_rate = mean(recovery_rate_ms);
                                
                                analysis_results.(test_label).zones.(zone_name).stats.avg = avg_recovery_rate;
                                analysis_results.(test_label).zones.(zone_name).stats.max = max_recovery_rate;
                                analysis_results.(test_label).zones.(zone_name).stats.min = min_recovery_rate;
                                
                                fprintf('      Zone %s (%.1f ft): Avg=%.6f m/s, Max=%.6f m/s, Min=%.6f m/s\n', ...
                                    zone_name, analysis_results.(test_label).zones.(zone_name).Depthft, ...
                                    avg_recovery_rate, max_recovery_rate, min_recovery_rate);
                            else
                                fprintf('      Zone %s (%.1f ft): NO DATA IN RECOVERY WINDOW\n', ...
                                    zone_name, analysis_results.(test_label).zones.(zone_name).Depthft);
                            end
                        else
                            fprintf('      Missing required variables in %s\n', head_file.name);
                        end
                    end
                    
                catch ME
                    fprintf('      Error loading %s: %s\n', head_file.name, ME.message);
                end
            end
        else
            fprintf('  No head data files found in any location\n');
            fprintf('  Searched locations:\n');
            for dir_idx = 1:length(possible_dirs)
                fprintf('    %s\n', possible_dirs{dir_idx});
            end
        end
        
    else
        fprintf('  WARNING: No timing data found for test %s\n', test_label);
        analysis_results.(test_label).error = 'no_timing_data';
    end
end

fprintf('\n=== HEAD DATA ANALYSIS COMPLETE ===\n');

end
