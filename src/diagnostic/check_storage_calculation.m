%CHECK_STORAGE_CALCULATION Diagnostic script to understand Ss calculation
% Compares your calculation with advisor's to find the 10x difference

clear all
close all
clc

fprintf('=== STORAGE CALCULATION DIAGNOSTIC ===\n\n');

% Load your linear regression results
fprintf('Loading your linear regression results...\n');
try
    % Try to load from workspace or file
    if exist('das_results', 'var')
        fprintf('  Found das_results in workspace\n');
    else
        % Try to load from file
        results_file = 'C:\Coding\BGWRP\data\_BATCH\_results\das_results_filtered.mat';
        if exist(results_file, 'file')
            load(results_file);
            fprintf('  Loaded from: %s\n', results_file);
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
            fprintf('  Using test: %s\n', test_name);
        else
            error('No test data found in das_results');
        end
    end
    
    if ~isfield(das_results.(test_name), 'linear_regression')
        error('Linear regression results not found. Run linear regression first.');
    end
    
    lr = das_results.(test_name).linear_regression;
    
    fprintf('\n=== YOUR LINEAR REGRESSION RESULTS ===\n');
    fprintf('Slope: %.4e (1/s)/(ft/s)\n', lr.slope);
    fprintf('R: %.4f\n', lr.R);
    fprintf('R²: %.4f\n', lr.R_squared);
    
    % Calculate storage with current method
    fprintf('\n=== YOUR STORAGE CALCULATION ===\n');
    config.alpha = 0.95;
    config.gamma_unit = 'SI';
    config.poisson_ratio = 0.30;
    
    storage = calculate_specific_storage_becker(lr, config);
    
    fprintf('\nYour Ss: %.4e 1/m\n', storage.S_s);
    fprintf('Advisor''s Ss: ~1e-07 1/m (expected)\n');
    fprintf('Difference: %.1fx\n', 1e-07 / storage.S_s);
    
    % Check if characteristic length scaling would fix it
    fprintf('\n=== TESTING CHARACTERISTIC LENGTH SCALING ===\n');
    fprintf('If advisor uses L_char = 1 m instead of 10 m:\n');
    L_gauge = 10;  % Your gauge length
    L_char = 1;    % Possible advisor's characteristic length
    scaling_factor = L_gauge / L_char;
    fprintf('  Scaling factor: %.1f (= %.1f m / %.1f m)\n', scaling_factor, L_gauge, L_char);
    
    % Recalculate with scaling
    config.strain_rate_characteristic_length_m = L_char;
    storage_scaled = calculate_specific_storage_becker(lr, config);
    
    fprintf('  Scaled Ss: %.4e 1/m\n', storage_scaled.S_s);
    fprintf('  Match advisor? %s\n', abs(storage_scaled.S_s - 1e-07) < 0.5e-07 ? 'YES ✓' : 'NO ✗');
    
    % Check other possible causes
    fprintf('\n=== OTHER POSSIBLE CAUSES ===\n');
    fprintf('1. Gauge length: You use %.1f m, advisor might use different?\n', L_gauge);
    fprintf('2. Unit conversion: Check if advisor converts ft/s differently\n');
    fprintf('3. Poisson ratio: You use %.2f, advisor might use different?\n', config.poisson_ratio);
    fprintf('4. Alpha (Biot-Willis): You use %.2f, advisor might use different?\n', config.alpha);
    
    % Check actual strain rate values
    if isfield(lr, 'strain_rate')
        fprintf('\n=== STRAIN RATE VALUES ===\n');
        fprintf('Mean |strain_rate|: %.4e 1/s\n', mean(abs(lr.strain_rate)));
        fprintf('Max |strain_rate|: %.4e 1/s\n', max(abs(lr.strain_rate)));
        fprintf('Expected range: 1e-10 to 1e-11 1/s\n');
    end
    
    % Check drawdown rate values
    if isfield(lr, 'drawdown_rate')
        fprintf('\n=== DRAWDOWN RATE VALUES ===\n');
        fprintf('Mean |drawdown_rate|: %.4e ft/s\n', mean(abs(lr.drawdown_rate)));
        fprintf('Max |drawdown_rate|: %.4e ft/s\n', max(abs(lr.drawdown_rate)));
    end
    
catch ME
    fprintf('ERROR: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('\n=== DIAGNOSTIC COMPLETE ===\n');

