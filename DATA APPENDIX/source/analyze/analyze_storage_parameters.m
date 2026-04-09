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

console_log('=== STORAGE PARAMETER ANALYSIS ===\n');

% Initialize results
storage_results = struct();
storage_results.tests = test_labels;

for i = 1:length(test_labels)
    test_label = test_labels{i};
    console_log('\nAnalyzing storage parameters for test: %s\n', test_label);
    
    % Get DAS data from already-processed results
    if ~isfield(das_results, test_label) || isfield(das_results.(test_label), 'error')
        console_log('  No DAS results found for %s\n', test_label);
        continue;
    end
    das_data = das_results.(test_label);
    
    % Get head data from already-processed results
    if ~isfield(head_results, test_label) || isfield(head_results.(test_label), 'error')
        console_log('  No head results found for %s\n', test_label);
        continue;
    end
    head_data = head_results.(test_label);
    
    % Extract strain rate from DAS data (already filtered and time-shifted)
    if ~isfield(das_data, 'analysis_strain_rate') || ~isfield(das_data, 'analysis_time')
        console_log('  No analysis_strain_rate found in DAS data for %s\n', test_label);
        continue;
    end
    
    das_strain_rate = das_data.analysis_strain_rate;  % nm/s
    das_time = das_data.analysis_time;
    
    % Analyze for both z4 and z5
    zones_to_analyze = {'z4', 'z5'};
    
    for z_idx = 1:length(zones_to_analyze)
        zone_name = zones_to_analyze{z_idx};
        
        if ~isfield(head_data, 'zones') || ~isfield(head_data.zones, zone_name)
            console_log('  No %s zone data found\n', zone_name);
            continue;
        end
        
        zone_data = head_data.zones.(zone_name);
        
        % Check if recovery data exists
        if ~isfield(zone_data, 'recovery_data') || isempty(zone_data.recovery_data)
            console_log('  No recovery data found for zone %s\n', zone_name);
            continue;
        end
        
        % Calculate drawdown rate for this zone
        [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, zone_data.recovery_data.Drawdownft, 'ft_per_min');
        
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
        
        % Calculate storativity (using aquifer thickness from config or default)
        if isfield(config, 'aquifer_thickness_m') && ~isnan(config.aquifer_thickness_m)
            aquifer_thickness = config.aquifer_thickness_m;  % meters from config
        else
            aquifer_thickness = 100;  % meters (default fallback)
        end
        S_storativity = Ss_estimate * aquifer_thickness;
        
        % Estimate transmissivity and hydraulic conductivity
        % If we have transmissivity from traditional pump test analysis, we can calculate K
        % For now, we'll provide the framework and use typical values for demonstration
        
        % Method 1: From time lag (if measurable)
        % Hydraulic diffusivity: D = r²/(4*t_lag) where r is radial distance
        % Then: T = D * S
        if abs(time_lag) > 0
            % Assume radial distance (distance from DAS to monitoring well)
            radial_distance = 10;  % meters (adjustable - typical wellbore to formation distance)
            time_lag_sec = abs(time_lag);
            hydraulic_diffusivity = (radial_distance^2) / (4 * time_lag_sec);  % m²/s
            T_from_lag = hydraulic_diffusivity * S_storativity;  % m²/s
            K_from_lag = T_from_lag / aquifer_thickness;  % m/s
            K_from_lag_ft_day = K_from_lag * 283168.47;  % Convert m/s to ft/day
            T_from_lag_ft2_day = T_from_lag * 283168.47;  % Convert m²/s to ft²/day
        else
            % No measurable time lag
            T_from_lag = NaN;
            K_from_lag = NaN;
            K_from_lag_ft_day = NaN;
            T_from_lag_ft2_day = NaN;
        end
        
        % Method 2: Use traditional pump test T value (if available in config)
        if isfield(config, 'traditional_T_ft2_day') && ~isnan(config.traditional_T_ft2_day)
            T_traditional_ft2_day = config.traditional_T_ft2_day;
            T_traditional_m2_s = T_traditional_ft2_day / 283168.47;  % Convert ft²/day to m²/s
            K_traditional_m_s = T_traditional_m2_s / aquifer_thickness;
            K_traditional_ft_day = K_traditional_m_s * 283168.47;  % Convert m/s to ft/day
            
            % Calculate hydraulic diffusivity from traditional analysis
            D_traditional = T_traditional_m2_s / S_storativity;
            
            % Storativity from traditional test (if available)
            if isfield(config, 'traditional_S') && ~isnan(config.traditional_S)
                S_traditional = config.traditional_S;
            else
                S_traditional = NaN;
            end
        else
            T_traditional_ft2_day = NaN;
            T_traditional_m2_s = NaN;
            K_traditional_m_s = NaN;
            K_traditional_ft_day = NaN;
            D_traditional = NaN;
            S_traditional = NaN;
        end
        
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
        storage_results.(result_key).S_storativity = S_storativity;
        storage_results.(result_key).aquifer_thickness_m = aquifer_thickness;
        storage_results.(result_key).alpha_biot = alpha_biot;
        storage_results.(result_key).T_from_lag_m2_s = T_from_lag;
        storage_results.(result_key).T_from_lag_ft2_day = T_from_lag_ft2_day;
        storage_results.(result_key).K_from_lag_m_s = K_from_lag;
        storage_results.(result_key).K_from_lag_ft_day = K_from_lag_ft_day;
        storage_results.(result_key).T_traditional_ft2_day = T_traditional_ft2_day;
        storage_results.(result_key).T_traditional_m2_s = T_traditional_m2_s;
        storage_results.(result_key).K_traditional_m_s = K_traditional_m_s;
        storage_results.(result_key).K_traditional_ft_day = K_traditional_ft_day;
        storage_results.(result_key).S_traditional = S_traditional;
        storage_results.(result_key).D_traditional = D_traditional;
        
        console_log('  Zone %s results:\n', zone_name);
        console_log('    Correlation window: %s to %s\n', window_time(1), window_time(end));
        console_log('    Slope: %.6f (nm/s)/(ft/min)\n', slope);
        console_log('    R²: %.4f\n', r_squared);
        console_log('    Time lag: %d seconds\n', time_lag);
        console_log('    Specific storage (Ss,ε): %.2e 1/m\n', Ss_estimate);
        console_log('    Storativity (S = Ss × b, b=%.0fm): %.2e\n', aquifer_thickness, S_storativity);
        if ~isnan(T_traditional_ft2_day)
            console_log('    Traditional T: %.1f ft²/day, K: %.2f ft/day\n', T_traditional_ft2_day, K_traditional_ft_day);
            if ~isnan(S_traditional)
                console_log('    Traditional S: %.2e (DAS/Traditional ratio: %.2f)\n', S_traditional, S_storativity/S_traditional);
            end
        end
    end
end

console_log('\n=== STORAGE PARAMETER ANALYSIS COMPLETE ===\n');

end

