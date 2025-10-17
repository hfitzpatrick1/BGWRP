function correlation_results = analyze_strain_head_correlation(timing_config, test_labels, config)
    %ANALYZE_STRAIN_HEAD_CORRELATION Analyze linear relationship between strain rate and head data
    %
    % Inputs:
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
        
    % Load DAS data (this should be the filtered results from run_filter_matlab_movmean_5sec)
    das_data = load_das_data(test_label, config);
    if isempty(das_data)
        continue;
    end
    
    % Load head data
    head_data = load_head_data(test_label, config);
    if isempty(head_data)
        continue;
    end
    
    % Extract strain rate from filtered DAS data
    if isfield(das_data, 'analysis_strain_rate')
        strain_rate = das_data.analysis_strain_rate;
        strain_time = das_data.analysis_time;
    else
        fprintf('  No analysis_strain_rate found in DAS data for %s\n', test_label);
        continue;
    end
        
    % Extract head data (drawdown rate) - use raw head data
    head_rate = calculate_drawdown_rate(head_data.time, head_data.head_levels);
    head_time = head_data.time;
    
    % Synchronize time series (strain_rate is already filtered from 5-second moving mean)
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