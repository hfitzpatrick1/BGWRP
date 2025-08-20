function analysis_results = analyze_head_data(timing_config, test_labels, config)
%ANALYZE_HEAD_DATA Simplified head data analysis utility
%
% Analyzes head data (drawdown/recovery) using batch processor timing configuration
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

%% Simple analysis parameters
smooth_window = 10;  % Moving average window

% Simple head data file lookup
head_data_dir = 'C:\Coding\BGWRP\data\head';  % Direct path like in simple script

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
    if ~isfield(timing_config, test_label)
        fprintf('  WARNING: No timing data found for test %s\n', test_label);
        analysis_results.(test_label).error = 'no_timing_data';
        continue;
    end
    
    test_timing = timing_config.(test_label);
    dataset_name = test_timing.dataset_name;
    
    % Get analysis window from config
    if isfield(config, 'analysis_windows') && isfield(config.analysis_windows, dataset_name)
        analysis_start = config.analysis_windows.(dataset_name).start;
        analysis_end = config.analysis_windows.(dataset_name).end;
    else
        analysis_start = test_timing.start;
        analysis_end = test_timing.end;
    end
    analysis_duration = minutes(analysis_end - analysis_start);
    
    fprintf('Analysis window: %s to %s (%.1f minutes)\n', ...
        analysis_start, analysis_end, analysis_duration);
    
    % Store timing info
    analysis_results.(test_label).timing.start = analysis_start;
    analysis_results.(test_label).timing.end = analysis_end;
    analysis_results.(test_label).timing.duration_minutes = analysis_duration;
    
    % Simple head file pattern determination
    test_type = 'c';  % Default PT01c
    if contains(upper(dataset_name), 'PT01A')
        test_type = 'a';
    elseif contains(upper(dataset_name), 'PT01B')
        test_type = 'b';
    end
    
    head_pattern = sprintf('head_%s_z*.mat', test_type);
    head_files = dir(fullfile(head_data_dir, head_pattern));
    
    fprintf('  Looking for head data files: %s\n', head_pattern);
    if ~isempty(head_files)
        fprintf('  Found %d head data files in: %s\n', length(head_files), head_data_dir);
        
        % Process head data files (simplified approach)
        for j = 1:length(head_files)
            head_file = head_files(j);
            fprintf('    Loading: %s\n', head_file.name);
            
            try
                head_file_path = fullfile(head_data_dir, head_file.name);
                head_data = load(head_file_path);
                
                % Extract zone name (z2, z3, etc.)
                zone_match = regexp(head_file.name, 'head_[abc]_(z\d+)\.mat', 'tokens');
                if ~isempty(zone_match)
                    zone_name = zone_match{1}{1};
                    
                    % Check for required variables
                    if isfield(head_data, 'Date') && isfield(head_data, 'Drawdownft') && isfield(head_data, 'Depthft')
                        Date = head_data.Date;
                        Drawdownft = head_data.Drawdownft;
                        Depthft = head_data.Depthft;
                        
                        % Apply timing adjustment for PT01c (simplified approach)
                        if strcmp(test_type, 'c')
                            Date = Date + seconds(10);  % Fixed 10 second adjustment for PT01c
                            fprintf('      Applied PT01c timing adjustment: +10 seconds\n');
                        end
                        Date.TimeZone = 'UTC';
                        
                        % Store raw data
                        analysis_results.(test_label).zones.(zone_name).Date = Date;
                        analysis_results.(test_label).zones.(zone_name).Drawdownft = Drawdownft;
                        analysis_results.(test_label).zones.(zone_name).Depthft = mean(Depthft, 'omitnan');
                        analysis_results.(test_label).zones.(zone_name).file = head_file.name;
                        
                        % Calculate recovery rates
                        [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(...
                            Date, Drawdownft, analysis_start, analysis_end, smooth_window);
                        
                        analysis_results.(test_label).zones.(zone_name).recovery_rate_ms = recovery_rate_ms;
                        analysis_results.(test_label).zones.(zone_name).recovery_time = recovery_time;
                        analysis_results.(test_label).zones.(zone_name).recovery_data = recovery_data;
                        
                        if ~isempty(recovery_rate_ms)
                            avg_recovery_rate = mean(recovery_rate_ms);
                            analysis_results.(test_label).zones.(zone_name).stats.avg = avg_recovery_rate;
                            
                            fprintf('      Zone %s (%.1f ft): Avg recovery rate = %.6f m/s\n', ...
                                zone_name, analysis_results.(test_label).zones.(zone_name).Depthft, avg_recovery_rate);
                        else
                            fprintf('      Zone %s: NO DATA IN RECOVERY WINDOW\n', zone_name);
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
        fprintf('  No head data files found: %s\n', head_pattern);
    end
end

fprintf('\n=== HEAD DATA ANALYSIS COMPLETE ===\n');

end
