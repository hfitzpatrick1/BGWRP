%CHECK_AMPLITUDE_VALUES Check actual amplitude values from your data
% Compare with advisor's values to find the difference

% Don't clear workspace - we need das_results!
% clear all  % REMOVED - preserves workspace variables
close all
clc

fprintf('=== CHECKING YOUR AMPLITUDE VALUES ===\n\n');

% Load your linear regression results
fprintf('Loading your linear regression results...\n');
try
    % First check if das_results exists in workspace (even if empty)
    if exist('das_results', 'var')
        if isempty(das_results)
            fprintf('  ⚠ das_results exists but is empty\n');
        else
            fprintf('  ✓ Found das_results in workspace\n');
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
                fprintf('  ✓ Loaded from: %s\n', results_file);
                loaded = true;
                break;
            end
        end
        
        if ~loaded
            fprintf('  ✗ Could not find das_results file. Tried:\n');
            for i = 1:length(possible_files)
                fprintf('    - %s\n', possible_files{i});
            end
            fprintf('\n  Please ensure das_results is in your workspace or run:\n');
            fprintf('    mode = ''run_correlation_analysis''; BGWRP_Toolkit\n');
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
    
    fprintf('\n=== YOUR LINEAR REGRESSION RESULTS ===\n');
    fprintf('Slope: %.4e (1/s)/(ft/s)\n', lr.slope);
    
    % Check if amplitude mode was used
    if isfield(lr, 'use_amplitude') && lr.use_amplitude
        fprintf('  ✓ Amplitude mode was used\n');
        
        % Get amplitude values
        if isfield(lr, 'strain_rate') && isfield(lr, 'drawdown_rate')
            strain_amp = max(lr.strain_rate) - min(lr.strain_rate);
            head_amp = max(lr.drawdown_rate) - min(lr.drawdown_rate);
            
            fprintf('\n  Amplitude values:\n');
            fprintf('    Strain rate amplitude: %.4e 1/s\n', strain_amp);
            fprintf('    Head rate amplitude: %.4e ft/s\n', head_amp);
            
            % Convert to displacement rate amplitude
            gauge_length_m = 10;
            displacement_amp = strain_amp * (gauge_length_m * 1e9);  % nm/s
            fprintf('    Displacement rate amplitude: %.2f nm/s\n', displacement_amp);
            
            % Convert head rate to ft/min
            head_amp_ft_per_min = head_amp * 60;
            fprintf('    Head rate amplitude: %.4f ft/min\n', head_amp_ft_per_min);
            
            % Compare with advisor
            fprintf('\n=== COMPARISON WITH ADVISOR ===\n');
            fprintf('Advisor''s values:\n');
            fprintf('  Displacement rate amplitude: 1.3 nm/s\n');
            fprintf('  Head rate amplitude: 0.09 ft/min\n');
            fprintf('  Slope: 2.8434e-07 (1/s)/(m/s)\n');
            
            fprintf('\nYour values:\n');
            fprintf('  Displacement rate amplitude: %.2f nm/s\n', displacement_amp);
            fprintf('  Head rate amplitude: %.4f ft/min\n', head_amp_ft_per_min);
            
            % Calculate what slope should be
            head_amp_m_per_s = head_amp * 0.3048;  % Convert to m/s
            slope_calc = strain_amp / head_amp_m_per_s;  % (1/s)/(m/s)
            fprintf('  Calculated slope (1/s)/(m/s): %.4e\n', slope_calc);
            fprintf('  Advisor''s slope: 2.8434e-07 (1/s)/(m/s)\n');
            fprintf('  Difference: %.2fx\n', 2.8434e-07 / slope_calc);
            
        end
    else
        fprintf('  ⚠ Amplitude mode was NOT used\n');
        fprintf('  Advisor uses amplitude (max - min) method\n');
        fprintf('  You should run linear regression with config.use_amplitude = true\n');
    end
    
catch ME
    fprintf('ERROR: %s\n', ME.message);
end

fprintf('\n=== CHECK COMPLETE ===\n');

