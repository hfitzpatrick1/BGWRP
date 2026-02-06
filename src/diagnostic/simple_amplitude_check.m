% Simple check of amplitude values - no file loading, just workspace

console_log('=== YOUR VALUES vs ADVISOR ===\n\n');

if ~exist('das_results', 'var')
    console_log('ERROR: das_results not in workspace\n');
    console_log('Run: mode = ''run_correlation_analysis''; BGWRP_Toolkit\n');
    return
end

test_name = 'PT01c_Recovery_short';
if ~isfield(das_results, test_name)
    test_names = fieldnames(das_results);
    if ~isempty(test_names)
        test_name = test_names{1};
    end
end

if ~isfield(das_results.(test_name), 'linear_regression')
    console_log('ERROR: No linear regression results\n');
    return
end

lr = das_results.(test_name).linear_regression;

% Your slope
console_log('YOUR SLOPE: %.4e (1/s)/(ft/s)\n', lr.slope);
console_log('  In (1/s)/(m/s): %.4e\n', lr.slope / 0.3048);
console_log('ADVISOR SLOPE: 2.8434e-07 (1/s)/(m/s)\n');
console_log('  Difference: %.1fx\n\n', 2.8434e-07 / (lr.slope / 0.3048));

% Get amplitudes if available
if isfield(lr, 'strain_rate') && isfield(lr, 'drawdown_rate')
    strain_amp = max(lr.strain_rate) - min(lr.strain_rate);
    head_amp_ft_s = max(lr.drawdown_rate) - min(lr.drawdown_rate);
    head_amp_ft_min = head_amp_ft_s * 60;
    disp_amp = strain_amp * 10e9;  % nm/s
    
    console_log('YOUR AMPLITUDES:\n');
    console_log('  Displacement: %.2f nm/s\n', disp_amp);
    console_log('  Head rate: %.4f ft/min\n', head_amp_ft_min);
    console_log('  Strain rate: %.4e 1/s\n\n', strain_amp);
    
    console_log('ADVISOR AMPLITUDES:\n');
    console_log('  Displacement: 1.3 nm/s\n');
    console_log('  Head rate: 0.09 ft/min\n');
    console_log('  Strain rate: 1.3e-10 1/s\n\n');
    
    console_log('DIFFERENCES:\n');
    console_log('  Displacement: %.2fx\n', 1.3 / disp_amp);
    console_log('  Head rate: %.2fx\n', 0.09 / head_amp_ft_min);
end

