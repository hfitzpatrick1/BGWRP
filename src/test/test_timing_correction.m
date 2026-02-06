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
fprintf('\n========================================\n');
fprintf('TESTING TIMING CORRECTION: %d seconds\n', TIMING_CORRECTION_SECONDS);
fprintf('========================================\n\n');

config.timing_correction_sec = TIMING_CORRECTION_SECONDS;
config.zone = zone;
config.show_plots = true;

try
    results = linear_regression_strain_drawdown(das_results, head_results, test_name, config);
    
    fprintf('\n========================================\n');
    fprintf('RESULTS SUMMARY\n');
    fprintf('========================================\n');
    fprintf('Timing correction: %d seconds backward\n', TIMING_CORRECTION_SECONDS);
    fprintf('Correlation (R): %.4f\n', results.R);
    fprintf('R²: %.4f\n', results.R_squared);
    fprintf('Slope: %.4e ns/s per ft/min\n', results.slope);
    fprintf('Data points: %d\n', results.n_points);
    fprintf('========================================\n\n');
    
    if results.R_squared > 0.5
        fprintf('✓ EXCELLENT correlation! Ready for storage calculation.\n');
    elseif results.R_squared > 0.4
        fprintf('⚠ GOOD correlation. Try fine-tuning ±1-2 seconds for improvement.\n');
    elseif results.R_squared > 0.25
        fprintf('⚠ MODERATE correlation. Try adjusting timing ±5 seconds.\n');
    else
        fprintf('✗ WEAK correlation. Check data quality or try different timing range.\n');
    end
    
    fprintf('\nTIP: Adjust TIMING_CORRECTION_SECONDS at the top of this script and re-run.\n');
    fprintf('     Look at Figure 20 (right plot) to check if peaks are aligned.\n\n');
    
catch ME
    fprintf('\n✗ ERROR: %s\n', ME.message);
    fprintf('   at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

