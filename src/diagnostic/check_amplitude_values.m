%CHECK_AMPLITUDE_VALUES Check actual amplitude values from your data
% Compare with advisor's values to find the difference

% Don't clear workspace - we need das_results!
% clear all  % REMOVED - preserves workspace variables
close all
clc

console_log('=== CHECKING YOUR AMPLITUDE VALUES ===\n\n');

% Load your linear regression results
console_log('Loading your linear regression results...\n');
try
    % First check if das_results exists in workspace (even if empty)
    if exist('das_results', 'var')
        if isempty(das_results)
            console_log('  ⚠ das_results exists but is empty\n');
        else
            console_log('  ✓ Found das_results in workspace\n');
        end
    else
        % Try multiple possible file locations
        possible_files = {
            'C:\Coding\BGWRP\data\_BATCH\_results\das_results_filtered.mat'
            'C:\Coding\BGWRP\data\_results\das_results_filtered.mat'
            fullfile(pwd, '..', 'data', '_BATCH', '_results', 'das_results_filtered.mat')
            fullfile(pwd, '..', 'data', '_results', 'das_results_filtered.mat')
        };
        
        loaded = false;
        for i = 1:length(possible_files)
            results_file = possible_files{i};
            if exist(results_file, 'file')
                load(results_file);
                console_log('  ✓ Loaded from: %s\n', results_file);
                loaded = true;
                break;
            end
        end
        
        if ~loaded
            console_log('  ✗ Could not find das_results file. Tried:\n');
            for i = 1:length(possible_files)
                console_log('    - %s\n', possible_files{i});
            end
            console_log('\n  Please ensure das_results is in your workspace or run:\n');
            console_log('    mode = ''run_correlation_analysis''; BGWRP_Toolkit\n');
            error('das_results not found');
        end
    end
    
    test_name = 'PT01c_Recovery_short';
    if ~isfield(das_results, test_name)
        test_names = fieldnames(das_results);
        if ~isempty(test_names)
            test_name = test_names{1};
        else
            error('No test data found');
        end
    end
    
    if ~isfield(das_results.(test_name), 'linear_regression')
        error('Linear regression results not found. Run linear regression first.');
    end
    
    lr = das_results.(test_name).linear_regression;
    
    console_log('\n=== YOUR LINEAR REGRESSION RESULTS ===\n');
    console_log('Slope: %.4e (1/s)/(ft/s)\n', lr.slope);
    
    % Check if amplitude mode was used
    if isfield(lr, 'use_amplitude') && lr.use_amplitude
        console_log('  ✓ Amplitude mode was used\n');
        
        % Get amplitude values
        if isfield(lr, 'strain_rate') && isfield(lr, 'drawdown_rate')
            strain_amp = max(lr.strain_rate) - min(lr.strain_rate);
            head_amp = max(lr.drawdown_rate) - min(lr.drawdown_rate);
            
            console_log('\n  Amplitude values:\n');
            console_log('    Strain rate amplitude: %.4e 1/s\n', strain_amp);
            console_log('    Head rate amplitude: %.4e ft/s\n', head_amp);
            
            % Convert to displacement rate amplitude
            gauge_length_m = 10;
            displacement_amp = strain_amp * (gauge_length_m * 1e9);  % nm/s
            console_log('    Displacement rate amplitude: %.2f nm/s\n', displacement_amp);
            
            % Convert head rate to ft/min
            head_amp_ft_per_min = head_amp * 60;
            console_log('    Head rate amplitude: %.4f ft/min\n', head_amp_ft_per_min);
            
            % Compare with advisor
            console_log('\n=== COMPARISON WITH ADVISOR ===\n');
            console_log('Advisor''s values:\n');
            console_log('  Displacement rate amplitude: 1.3 nm/s\n');
            console_log('  Head rate amplitude: 0.09 ft/min\n');
            console_log('  Slope: 2.8434e-07 (1/s)/(m/s)\n');
            
            console_log('\nYour values:\n');
            console_log('  Displacement rate amplitude: %.2f nm/s\n', displacement_amp);
            console_log('  Head rate amplitude: %.4f ft/min\n', head_amp_ft_per_min);
            
            % Calculate what slope should be
            head_amp_m_per_s = head_amp * 0.3048;  % Convert to m/s
            slope_calc = strain_amp / head_amp_m_per_s;  % (1/s)/(m/s)
            console_log('  Calculated slope (1/s)/(m/s): %.4e\n', slope_calc);
            console_log('  Advisor''s slope: 2.8434e-07 (1/s)/(m/s)\n');
            console_log('  Difference: %.2fx\n', 2.8434e-07 / slope_calc);
            
        end
    else
        console_log('  ⚠ Amplitude mode was NOT used\n');
        console_log('  Advisor uses amplitude (max - min) method\n');
        console_log('  You should run linear regression with config.use_amplitude = true\n');
    end
    
catch ME
    console_log('ERROR: %s\n', ME.message);
end

console_log('\n=== CHECK COMPLETE ===\n');

