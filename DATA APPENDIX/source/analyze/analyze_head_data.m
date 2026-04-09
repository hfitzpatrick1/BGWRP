function analysis_results = analyze_head_data(timing_config, test_labels, config)
%ANALYZE_HEAD_DATA Analyze head data using new unified structure
%
% Works with the new _active structure where head data is combined into
% single files located in _head subdirectories
%
% Inputs:
%   timing_config - Timing configuration from batch processor
%   test_labels   - Cell array of test labels (dataset names)
%   config        - Batch processor configuration structure
%
% Outputs:
%   analysis_results - Structure containing analysis results for all tests

console_log('=== HEAD DATA ANALYSIS (UNIFIED) ===\n');

% Initialize results structure
analysis_results = struct();
analysis_results.tests = test_labels;
analysis_results.timing = timing_config;

% Simple analysis parameters
smooth_window = 10;  % Moving average window

% Base active directory
active_base = fullfile(config.base_input, '_active');

%% Load and analyze data for each test
for i = 1:length(test_labels)
    test_label = test_labels{i};
    console_log('\n--- Analyzing test %s ---\n', upper(test_label));
    
    % Get timing info for this test
    if ~isfield(timing_config, test_label)
        console_log('  WARNING: No timing data found for test %s\n', test_label);
        analysis_results.(test_label).error = 'no_timing_data';
        continue;
    end
    
    test_timing = timing_config.(test_label);
    
    % Get analysis window from config  
    if isfield(config, 'analysis_windows') && isfield(config.analysis_windows, test_label)
        analysis_start = config.analysis_windows.(test_label).start;
        analysis_end = config.analysis_windows.(test_label).end;
    else
        analysis_start = test_timing.start;
        analysis_end = test_timing.end;
    end
    analysis_duration = minutes(analysis_end - analysis_start);
    
    console_log('Analysis window: %s to %s (%.1f minutes)\n', ...
        analysis_start, analysis_end, analysis_duration);
    
    % Store timing info
    analysis_results.(test_label).timing.start = analysis_start;
    analysis_results.(test_label).timing.end = analysis_end;
    analysis_results.(test_label).timing.duration_minutes = analysis_duration;
    
    % Look for head data file in _head subdirectory
    dataset_dir = fullfile(active_base, test_label);
    head_dir = fullfile(dataset_dir, '_head');
    head_file = fullfile(head_dir, 'head_data.mat');
    
    if ~exist(head_file, 'file')
        console_log('  ⚠ No head data file found: %s\n', head_file);
        analysis_results.(test_label).error = 'no_head_data';
        continue;
    end
    
    try
        console_log('  Loading combined head data: %s\n', head_file);
        head_data = load(head_file);
        
        % Validate head data structure
        if ~isfield(head_data, 'Date') || ~isfield(head_data, 'zones')
            console_log('  ⚠ Invalid head data structure in %s\n', head_file);
            analysis_results.(test_label).error = 'invalid_structure';
            continue;
        end
        
        % Get zone names
        zone_names = fieldnames(head_data.zones);
        console_log('  Found %d zones: %s\n', length(zone_names), strjoin(zone_names, ', '));
        
        % Process each zone
        for z = 1:length(zone_names)
            zone_name = zone_names{z};
            zone_data = head_data.zones.(zone_name);
            
            % Validate zone data
            if ~isfield(zone_data, 'Drawdownft') || ~isfield(zone_data, 'Depthft')
                console_log('    ⚠ Zone %s missing required fields\n', zone_name);
                continue;
            end
            
            % Set timezone for shared Date array
            Date = head_data.Date;
            Date.TimeZone = 'UTC';
            Drawdownft = zone_data.Drawdownft;
            Depthft = zone_data.Depthft;
            
            % Store raw data
            analysis_results.(test_label).zones.(zone_name).Date = Date;
            analysis_results.(test_label).zones.(zone_name).Drawdownft = Drawdownft;
            analysis_results.(test_label).zones.(zone_name).Depthft = Depthft;
            analysis_results.(test_label).zones.(zone_name).source_file = 'head_data.mat';
            
            % Calculate recovery rates using shared timestamp
            [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(...
                Date, Drawdownft, analysis_start, analysis_end, smooth_window);
            
            analysis_results.(test_label).zones.(zone_name).recovery_rate_ms = recovery_rate_ms;
            analysis_results.(test_label).zones.(zone_name).recovery_time = recovery_time;
            analysis_results.(test_label).zones.(zone_name).recovery_data = recovery_data;
            
            if ~isempty(recovery_rate_ms)
                avg_recovery_rate = mean(recovery_rate_ms);
                analysis_results.(test_label).zones.(zone_name).avg_recovery_rate = avg_recovery_rate;
                
                console_log('    Zone %s (%.1f ft): Avg recovery rate = %.6f m/s (%d points)\n', ...
                    zone_name, Depthft, avg_recovery_rate, length(recovery_data.Date));
            else
                console_log('    Zone %s: NO DATA IN RECOVERY WINDOW\n', zone_name);
            end
        end
        
    catch ME
        console_log('  ✗ Error processing head data for %s: %s\n', test_label, ME.message);
        analysis_results.(test_label).error = ME.message;
    end
end

console_log('\n=== HEAD DATA ANALYSIS COMPLETE ===\n');

end

%% Recovery rate calculation function
function [recovery_rate_ms, recovery_time, recovery_data] = calc_recovery_rate(Date, Drawdownft, recovery_start, recovery_end, smooth_window)
    % Filter to recovery period (include 15s buffer on each side for plotting/shifting)
    recovery_mask = Date >= recovery_start - seconds(15) & Date <= recovery_end + seconds(15);
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
    recovery_rate_ms = recovery_rate * 0.3048;  % Convert to m/s
    recovery_time = recovery_data.Date(1:end-1);
end