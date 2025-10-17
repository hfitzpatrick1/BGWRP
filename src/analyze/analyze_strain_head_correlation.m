function correlation_results = analyze_strain_head_correlation(das_results, head_results, timing_config, test_labels, config)
%ANALYZE_STRAIN_HEAD_CORRELATION Analyze linear relationship between strain rate and head data
%
% Inputs:
%   das_results   - DAS results from analyze_das_data (with filtered data)
%   head_results  - Head results from analyze_head_data
%   timing_config - Timing configuration
%   test_labels   - Cell array of test labels
%   config        - Configuration structure
%
% Outputs:
%   correlation_results - Structure with correlation analysis results

fprintf('=== STRAIN RATE vs HEAD DATA CORRELATION ANALYSIS ===\n');

% Initialize results
correlation_results = struct();
correlation_results.tests = test_labels;

for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('Analyzing correlation for test: %s\n', test_label);
    
    % Get DAS data from already-processed results
    if ~isfield(das_results, test_label) || isfield(das_results.(test_label), 'error')
        fprintf('  No DAS results found for %s\n', test_label);
        continue;
    end
    das_data = das_results.(test_label);
    
    % Get head data from already-processed results
    if ~isfield(head_results, test_label) || isfield(head_results.(test_label), 'error')
        fprintf('  No head results found for %s\n', test_label);
        continue;
    end
    head_data = head_results.(test_label);
    
    % Extract strain rate from filtered DAS data (already has 5-sec filter applied)
    if isfield(das_data, 'analysis_strain_rate')
        strain_rate = das_data.analysis_strain_rate;
        strain_time = das_data.analysis_time;
    else
        fprintf('  No analysis_strain_rate found in DAS data for %s\n', test_label);
        continue;
    end
        
    % Extract head data (drawdown rate) from zone z5 (best signal)
    if ~isfield(head_data, 'zones') || ~isfield(head_data.zones, 'z5')
        fprintf('  No z5 zone data found in head results for %s\n', test_label);
        continue;
    end
    zone_data = head_data.zones.z5;
    
    % Calculate drawdown rate for z5
    head_rate = calculate_drawdown_rate(zone_data.time, zone_data.head_levels, 'ft/min');
    head_time = zone_data.rate_time;
    
    % Synchronize time series (strain_rate is already filtered and time-shifted)
    [strain_sync, head_sync, sync_time] = synchronize_time_series(strain_rate, strain_time, head_rate, head_time);
        
        % Detect signal onset for both datasets
        strain_onset = detect_signal_onset(strain_sync, sync_time, 'strain');
        head_onset = detect_signal_onset(head_sync, sync_time, 'head');
        
        % Calculate correlation
        correlation_coeff = corrcoef(strain_sync, head_sync);
        r_value = correlation_coeff(1,2);
        
        % Store results
        correlation_results.(test_label) = struct();
        correlation_results.(test_label).strain_rate = strain_sync;
        correlation_results.(test_label).head_rate = head_sync;
        correlation_results.(test_label).time = sync_time;
        correlation_results.(test_label).correlation_coefficient = r_value;
        correlation_results.(test_label).strain_onset_time = strain_onset;
        correlation_results.(test_label).head_onset_time = head_onset;
        correlation_results.(test_label).onset_delay = strain_onset - head_onset;
        
        fprintf('  Correlation coefficient: %.3f\n', r_value);
        fprintf('  Strain onset: %s\n', strain_onset);
        fprintf('  Head onset: %s\n', head_onset);
        fprintf('  Onset delay: %.2f seconds\n', seconds(correlation_results.(test_label).onset_delay));
    end
    end