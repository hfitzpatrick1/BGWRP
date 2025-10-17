function storage_results = analyze_storage_parameters(das_results, head_results, timing_config, test_labels, config)
%ANALYZE_STORAGE_PARAMETERS Calculate storage parameters from DAS strain rate vs head data
%
% Based on poroelastic theory (Wang, 2017, Equation 4.65):
%   α * Ss,ε * ∂h/∂t + ∇·q = ∂ε_vol/∂t
%
% Inputs:
%   das_results   - DAS results from analyze_das_data (with filtered data)
%   head_results  - Head results from analyze_head_data
%   timing_config - Timing configuration
%   test_labels   - Cell array of test labels
%   config        - Configuration structure
%
% Outputs:
%   storage_results - Structure with storage parameter estimates

fprintf('=== STORAGE PARAMETER ANALYSIS ===\n');

% Initialize results
storage_results = struct();
storage_results.tests = test_labels;

for i = 1:length(test_labels)
    test_label = test_labels{i};
    fprintf('\nAnalyzing storage parameters for test: %s\n', test_label);
    
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
    
    % Extract strain rate from DAS data (already filtered and time-shifted)
    if ~isfield(das_data, 'analysis_strain_rate') || ~isfield(das_data, 'analysis_time')
        fprintf('  No analysis_strain_rate found in DAS data for %s\n', test_label);
        continue;
    end
    
    das_strain_rate = das_data.analysis_strain_rate;  % nm/s
    das_time = das_data.analysis_time;
    
    % Analyze for both z4 and z5
    zones_to_analyze = {'z4', 'z5'};
    
    for z_idx = 1:length(zones_to_analyze)
        zone_name = zones_to_analyze{z_idx};
        
        if ~isfield(head_data, 'zones') || ~isfield(head_data.zones, zone_name)
            fprintf('  No %s zone data found\n', zone_name);
            continue;
        end
        
        zone_data = head_data.zones.(zone_name);
        
        % Check if recovery data exists
        if ~isfield(zone_data, 'recovery_data') || isempty(zone_data.recovery_data)
            fprintf('  No recovery data found for zone %s\n', zone_name);
            continue;
        end
        
        % Calculate drawdown rate for this zone
        [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft/min');
        
        % Synchronize time series
        [das_sync, head_sync, sync_time] = synchronize_time_series(das_strain_rate, das_time, drawdown_rate, rate_time);
        
        % Find peak correlation window (look for max values)
        % Use a sliding window to find the period with highest correlation
        window_size = 30;  % 30 seconds
        best_corr = -inf;
        best_start_idx = 1;
        
        for start_idx = 1:(length(sync_time) - window_size)
            end_idx = start_idx + window_size - 1;
            window_das = das_sync(start_idx:end_idx);
            window_head = head_sync(start_idx:end_idx);
            
            % Calculate correlation for this window
            if std(window_das) > 0 && std(window_head) > 0
                corr_matrix = corrcoef(window_das, window_head);
                window_corr = abs(corr_matrix(1,2));
                
                if window_corr > best_corr
                    best_corr = window_corr;
                    best_start_idx = start_idx;
                end
            end
        end
        
        % Extract the best correlation window
        best_end_idx = best_start_idx + window_size - 1;
        window_das = das_sync(best_start_idx:best_end_idx);
        window_head = head_sync(best_start_idx:best_end_idx);
        window_time = sync_time(best_start_idx:best_end_idx);
        
        % Calculate linear regression
        p = polyfit(window_head, window_das, 1);
        slope = p(1);  % nm/s per ft/min
        intercept = p(2);
        
        % Calculate correlation coefficient
        corr_matrix = corrcoef(window_head, window_das);
        r_value = corr_matrix(1,2);
        r_squared = r_value^2;
        
        % Calculate time lag (cross-correlation)
        [xcorr_values, lags] = xcorr(window_das - mean(window_das), window_head - mean(window_head), 'coeff');
        [~, max_idx] = max(xcorr_values);
        time_lag = lags(max_idx);  % in samples (seconds for 1Hz data)
        
        % Convert slope to physical units for storage calculation
        % Slope units: (nm/s) / (ft/min) = (nm/s) / (ft/min)
        % Need to convert to strain/s per m/s
        % 1 ft/min = 0.00508 m/s
        % strain rate in 1/s, head change rate in m/s
        slope_SI = slope / 0.00508;  % (nm/s) / (m/s) = nm/m = nanostrain
        
        % Estimate specific storage (assuming α ≈ 1 for typical aquifers)
        % From: α * Ss,ε * ∂h/∂t ≈ ∂ε/∂t
        % Therefore: Ss,ε ≈ (∂ε/∂t) / (∂h/∂t) / α
        % Units: (1/s) / (m/s) = 1/m
        alpha_biot = 1.0;  % Biot-Willis coefficient (typically 0.7-1.0)
        Ss_estimate = (slope_SI * 1e-9) / alpha_biot;  % Convert from nanostrain to strain, result in 1/m
        
        % Store results
        result_key = sprintf('%s_%s', test_label, zone_name);
        storage_results.(result_key) = struct();
        storage_results.(result_key).zone = zone_name;
        storage_results.(result_key).das_strain_rate = das_sync;
        storage_results.(result_key).head_drawdown_rate = head_sync;
        storage_results.(result_key).time = sync_time;
        storage_results.(result_key).window_das = window_das;
        storage_results.(result_key).window_head = window_head;
        storage_results.(result_key).window_time = window_time;
        storage_results.(result_key).slope = slope;
        storage_results.(result_key).slope_SI = slope_SI;
        storage_results.(result_key).intercept = intercept;
        storage_results.(result_key).r_squared = r_squared;
        storage_results.(result_key).correlation = r_value;
        storage_results.(result_key).time_lag_seconds = time_lag;
        storage_results.(result_key).Ss_estimate = Ss_estimate;
        storage_results.(result_key).alpha_biot = alpha_biot;
        
        fprintf('  Zone %s results:\n', zone_name);
        fprintf('    Correlation window: %s to %s\n', window_time(1), window_time(end));
        fprintf('    Slope: %.6f (nm/s)/(ft/min)\n', slope);
        fprintf('    R²: %.4f\n', r_squared);
        fprintf('    Time lag: %d seconds\n', time_lag);
        fprintf('    Specific storage (Ss,ε): %.2e 1/m\n', Ss_estimate);
        fprintf('    Storativity (S = Ss × b, assuming b=100m): %.2e\n', Ss_estimate * 100);
    end
end

fprintf('\n=== STORAGE PARAMETER ANALYSIS COMPLETE ===\n');

end

