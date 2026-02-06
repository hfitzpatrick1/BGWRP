%% TEST DIFFERENT TIMING CORRECTIONS FOR LINEAR REGRESSION
% Quick script to test different timing corrections
% 
% USAGE:
% 1. Run correlation analysis first: mode = 'run_correlation_analysis'; BGWRP_Toolkit
% 2. Adjust TIMING_CORRECTION_SECONDS below
% 3. Run this script

clc;  % Clear command window but KEEP workspace variables!

%% CONFIGURATION
test_name = 'PT01c_Recovery_short';
TIMING_CORRECTION_SECONDS = 7.5;  % <-- ADJUST THIS VALUE (reduce to move green forward/right)
zone = 'z5';

%% Check if correlation results exist
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Please run correlation analysis first!\nmode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

%% Run linear regression with specified timing correction
console_log('\n========================================\n');
console_log('TESTING TIMING CORRECTION: %d seconds\n', TIMING_CORRECTION_SECONDS);
console_log('========================================\n\n');

config.timing_correction_sec = TIMING_CORRECTION_SECONDS;
config.zone = zone;
config.show_plots = true;

try
    results = linear_regression_strain_drawdown(das_results, head_results, test_name, config);
    
    console_log('\n========================================\n');
    console_log('RESULTS SUMMARY\n');
    console_log('========================================\n');
    console_log('Timing correction: %d seconds backward\n', TIMING_CORRECTION_SECONDS);
    console_log('Correlation (R): %.4f\n', results.R);
    console_log('R²: %.4f\n', results.R_squared);
    console_log('Slope: %.4e ns/s per ft/min\n', results.slope);
    console_log('Data points: %d\n', results.n_points);
    console_log('========================================\n\n');
    
    if results.R_squared > 0.5
        console_log('✓ EXCELLENT correlation! Ready for storage calculation.\n');
    elseif results.R_squared > 0.4
        console_log('⚠ GOOD correlation. Try fine-tuning ±1-2 seconds for improvement.\n');
    elseif results.R_squared > 0.25
        console_log('⚠ MODERATE correlation. Try adjusting timing ±5 seconds.\n');
    else
        console_log('✗ WEAK correlation. Check data quality or try different timing range.\n');
    end
    
    console_log('\nTIP: Adjust TIMING_CORRECTION_SECONDS at the top of this script and re-run.\n');
    console_log('     Look at Figure 20 (right plot) to check if peaks are aligned.\n\n');
    
catch ME
    console_log('\n✗ ERROR: %s\n', ME.message);
    console_log('   at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

