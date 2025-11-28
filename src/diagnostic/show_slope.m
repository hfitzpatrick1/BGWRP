% Simple script to show slope and amplitude values

if ~exist('das_results', 'var')
    fprintf('ERROR: das_results not in workspace\n');
    return
end

% Show what's actually in das_results
fprintf('Fields in das_results:\n');
test_names = fieldnames(das_results);
for i = 1:length(test_names)
    fprintf('  - %s\n', test_names{i});
    if isstruct(das_results.(test_names{i}))
        subfields = fieldnames(das_results.(test_names{i}));
        fprintf('    Subfields: %s\n', strjoin(subfields, ', '));
    end
end
fprintf('\n');

test_name = 'PT01c_Recovery_short';
if ~isfield(das_results, test_name)
    if ~isempty(test_names)
        test_name = test_names{1};
        fprintf('Using test: %s\n', test_name);
    else
        fprintf('ERROR: No test data found\n');
        return
    end
end

if ~isfield(das_results.(test_name), 'linear_regression')
    fprintf('Linear regression not found. Running it now...\n');
    if ~exist('head_results', 'var')
        fprintf('ERROR: Need head_results in workspace\n');
        fprintf('Run: mode = ''run_correlation_analysis''; BGWRP_Toolkit\n');
        return
    end
    
    % Run linear regression
    lr_config = struct();
    lr_config.zone = 'z5';
    % Use middle of screened zone: 260-310 ft -> center at 285 ft
    lr_config.depth_range_ft = [284.5, 285.5];  % Center of 260-310 ft screened zone
    lr_config.depth_averaging_method = 'representative';
    lr_config.use_amplitude = true;
    lr_config.use_displacement_rate = false;
    lr_config.show_plots = false;
    
    lr = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config);
    das_results.(test_name).linear_regression = lr;
else
    lr = das_results.(test_name).linear_regression;
end

fprintf('\n=== YOUR RESULTS ===\n');
fprintf('Slope: %.4e (1/s)/(m/s)\n', lr.slope);
fprintf('R: %.4f\n', lr.R);
fprintf('R²: %.4f\n\n', lr.R_squared);

fprintf('=== ADVISOR GROUND TRUTH ===\n');
fprintf('Advisor slope: 2.8434e-07 (1/s)/(m/s)\n');
fprintf('Your slope: %.4e (1/s)/(m/s)\n', lr.slope);
fprintf('Difference: %.2fx\n\n', 2.8434e-07 / lr.slope);

% Check if amplitude values are stored in results
if isfield(lr, 'displacement_amplitude_nm_per_s')
    fprintf('=== AMPLITUDE COMPARISON (from results) ===\n');
    fprintf('Your displacement amplitude: %.2f nm/s\n', lr.displacement_amplitude_nm_per_s);
    fprintf('Advisor displacement amplitude: 1.3 nm/s\n');
    fprintf('Difference: %.2fx\n\n', 1.3 / lr.displacement_amplitude_nm_per_s);
    
    fprintf('Your head rate amplitude: %.4f ft/min\n', lr.head_rate_amplitude_ft_per_min);
    fprintf('Advisor head rate amplitude: 0.09 ft/min\n');
    fprintf('Difference: %.2fx\n\n', 0.09 / lr.head_rate_amplitude_ft_per_min);
    
    fprintf('Your strain rate amplitude: %.4e 1/s\n', lr.strain_rate_amplitude);
    fprintf('Advisor strain rate amplitude: 1.3e-10 1/s\n');
    fprintf('Difference: %.2fx\n', 1.3e-10 / lr.strain_rate_amplitude);
elseif isfield(lr, 'strain_rate') && isfield(lr, 'drawdown_rate')
    % Calculate from data
    strain_amp = max(lr.strain_rate) - min(lr.strain_rate);
    head_amp_mps = max(lr.drawdown_rate) - min(lr.drawdown_rate);
    head_amp_ft_min = (head_amp_mps / 0.3048) * 60;
    disp_amp = strain_amp * 10e9;
    
    fprintf('=== AMPLITUDE COMPARISON (calculated) ===\n');
    fprintf('Your displacement amplitude: %.2f nm/s\n', disp_amp);
    fprintf('Advisor displacement amplitude: 1.3 nm/s\n');
    fprintf('Difference: %.2fx\n\n', 1.3 / disp_amp);
    
    fprintf('Your head rate amplitude: %.4f ft/min\n', head_amp_ft_min);
    fprintf('Advisor head rate amplitude: 0.09 ft/min\n');
    fprintf('Difference: %.2fx\n\n', 0.09 / head_amp_ft_min);
    
    fprintf('Your strain rate amplitude: %.4e 1/s\n', strain_amp);
    fprintf('Advisor strain rate amplitude: 1.3e-10 1/s\n');
    fprintf('Difference: %.2fx\n', 1.3e-10 / strain_amp);
else
    fprintf('No amplitude data available\n');
end

