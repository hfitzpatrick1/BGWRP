%CHECK_STORAGE_CALCULATION Diagnostic script to understand Ss calculation
% Compares your calculation with advisor's to find the 10x difference

clear all
close all
clc

console_log('=== STORAGE CALCULATION DIAGNOSTIC ===\n\n');

% Load your linear regression results
console_log('Loading your linear regression results...\n');
try
    % Try to load from workspace or file
    if exist('das_results', 'var')
        console_log('  Found das_results in workspace\n');
    else
        % Try to load from file
        results_file = 'C:\Coding\BGWRP\data\_BATCH\_results\das_results_filtered.mat';
        if exist(results_file, 'file')
            load(results_file);
            console_log('  Loaded from: %s\n', results_file);
        else
            error('das_results not found. Run correlation analysis first.');
        end
    end
    
    % Get test name (adjust as needed)
    test_name = 'PT01c_Recovery_short';
    if ~isfield(das_results, test_name)
        % Try to find any test name
        test_names = fieldnames(das_results);
        if ~isempty(test_names)
            test_name = test_names{1};
            console_log('  Using test: %s\n', test_name);
        else
            error('No test data found in das_results');
        end
    end
    
    if ~isfield(das_results.(test_name), 'linear_regression')
        error('Linear regression results not found. Run linear regression first.');
    end
    
    lr = das_results.(test_name).linear_regression;
    
    console_log('\n=== YOUR LINEAR REGRESSION RESULTS ===\n');
    console_log('Slope: %.4e (1/s)/(ft/s)\n', lr.slope);
    console_log('R: %.4f\n', lr.R);
    console_log('R²: %.4f\n', lr.R_squared);
    
    % Calculate storage with current method
    console_log('\n=== YOUR STORAGE CALCULATION ===\n');
    config.alpha = 0.95;
    config.gamma_unit = 'SI';
    config.poisson_ratio = 0.30;
    
    storage = calculate_specific_storage_becker(lr, config);
    
    console_log('\nYour Ss: %.4e 1/m\n', storage.S_s);
    console_log('Advisor''s Ss: ~1e-07 1/m (expected)\n');
    console_log('Difference: %.1fx\n', 1e-07 / storage.S_s);
    
    % Check if characteristic length scaling would fix it
    console_log('\n=== TESTING CHARACTERISTIC LENGTH SCALING ===\n');
    console_log('If advisor uses L_char = 1 m instead of 10 m:\n');
    L_gauge = 10;  % Your gauge length
    L_char = 1;    % Possible advisor's characteristic length
    scaling_factor = L_gauge / L_char;
    console_log('  Scaling factor: %.1f (= %.1f m / %.1f m)\n', scaling_factor, L_gauge, L_char);
    
    % Recalculate with scaling
    config.strain_rate_characteristic_length_m = L_char;
    storage_scaled = calculate_specific_storage_becker(lr, config);
    
    console_log('  Scaled Ss: %.4e 1/m\n', storage_scaled.S_s);
    console_log('  Match advisor? %s\n', abs(storage_scaled.S_s - 1e-07) < 0.5e-07 ? 'YES ✓' : 'NO ✗');
    
    % Check other possible causes
    console_log('\n=== OTHER POSSIBLE CAUSES ===\n');
    console_log('1. Gauge length: You use %.1f m, advisor might use different?\n', L_gauge);
    console_log('2. Unit conversion: Check if advisor converts ft/s differently\n');
    console_log('3. Poisson ratio: You use %.2f, advisor might use different?\n', config.poisson_ratio);
    console_log('4. Alpha (Biot-Willis): You use %.2f, advisor might use different?\n', config.alpha);
    
    % Check actual strain rate values
    if isfield(lr, 'strain_rate')
        console_log('\n=== STRAIN RATE VALUES ===\n');
        console_log('Mean |strain_rate|: %.4e 1/s\n', mean(abs(lr.strain_rate)));
        console_log('Max |strain_rate|: %.4e 1/s\n', max(abs(lr.strain_rate)));
        console_log('Expected range: 1e-10 to 1e-11 1/s\n');
    end
    
    % Check drawdown rate values
    if isfield(lr, 'drawdown_rate')
        console_log('\n=== DRAWDOWN RATE VALUES ===\n');
        console_log('Mean |drawdown_rate|: %.4e ft/s\n', mean(abs(lr.drawdown_rate)));
        console_log('Max |drawdown_rate|: %.4e ft/s\n', max(abs(lr.drawdown_rate)));
    end
    
catch ME
    console_log('ERROR: %s\n', ME.message);
    console_log('Stack trace:\n');
    for i = 1:length(ME.stack)
        console_log('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

console_log('\n=== DIAGNOSTIC COMPLETE ===\n');

