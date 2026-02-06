%% Calculate Storage for Depth Range (190-340 ft)
%
% This script runs depth-specific storage analysis for the zone where
% DAS signal is strongest (190-340 ft) instead of just one channel at 285 ft.
%
% BEFORE RUNNING:
% 1. Run: mode = 'run_correlation_analysis'; BGWRP_Toolkit
% 2. Ensure das_results and head_results are in workspace

console_log('\n');
console_log('╔═══════════════════════════════════════════════════════════════╗\n');
console_log('║  DEPTH-SPECIFIC STORAGE CALCULATION (190-340 ft)              ║\n');
console_log('║  Becker (2022) Simplified Poroelasticity Method              ║\n');
console_log('╚═══════════════════════════════════════════════════════════════╝\n');
console_log('\n');

%% Check if data exists
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('das_results and head_results not found in workspace!\nRun: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

test_name = 'PT01c_Recovery_short';  % Modify if analyzing different test

% Check if test exists
if ~isfield(das_results, test_name)
    error('Test "%s" not found in das_results!', test_name);
end

%% Step 1: Linear Regression for Depth Range 190-340 ft
console_log('\n=== STEP 1: LINEAR REGRESSION FOR DEPTH RANGE ===\n');

lr_config.timing_correction_sec = 8;  % Optimized timing correction
lr_config.zone = 'z5';
lr_config.depth_range_ft = [190, 340];  % Strong signal zone
lr_config.show_plots = true;

lr_results = linear_regression_depth_range(das_results, head_results, test_name, lr_config);

% Store in das_results
das_results.(test_name).linear_regression_depth_range = lr_results;

console_log('\n✓ Linear regression complete for %.0f-%.0f ft (R=%.3f, R^2=%.3f)\n', ...
    lr_results.depth_range_ft(1), lr_results.depth_range_ft(2), lr_results.R, lr_results.R_squared);

%% Step 2: Calculate Storage Parameters
console_log('\n=== STEP 2: CALCULATE STORAGE PARAMETERS ===\n');

storage_config.alpha = 0.95;  % Biot-Willis coefficient for clean/gravelly sand
storage_config.gamma_unit = 'SI';
storage_config.aquifer_thickness_ft = lr_results.depth_range_ft(2) - lr_results.depth_range_ft(1);  % Use depth range thickness!
storage_config.S_traditional = 0.002955;  % From Aqtesolv for comparison

console_log('Using aquifer thickness: %.0f ft (depth range %.0f-%.0f ft)\n', ...
    storage_config.aquifer_thickness_ft, lr_results.depth_range_ft(1), lr_results.depth_range_ft(2));

storage_results = calculate_specific_storage_becker(lr_results, storage_config);

%% Step 3: Summary comparison
console_log('\n');
console_log('╔═══════════════════════════════════════════════════════════════╗\n');
console_log('║  COMPARISON: SINGLE CHANNEL vs DEPTH RANGE                   ║\n');
console_log('╚═══════════════════════════════════════════════════════════════╝\n');
console_log('\n');

if isfield(das_results.(test_name), 'linear_regression')
    single_channel = das_results.(test_name).linear_regression;
    
    console_log('SINGLE CHANNEL (285 ft):\n');
    console_log('  R^2: %.4f\n', single_channel.R_squared);
    console_log('  Slope: %.4e (1/s) per (ft/min)\n', single_channel.slope);
    console_log('  N points: %d\n', single_channel.n_points);
    console_log('\n');
end

console_log('DEPTH RANGE (%.0f-%.0f ft, %d channels averaged):\n', ...
    lr_results.depth_range_ft(1), lr_results.depth_range_ft(2), lr_results.n_channels);
console_log('  R^2: %.4f\n', lr_results.R_squared);
console_log('  Slope: %.4e (1/s) per (ft/min)\n', lr_results.slope);
console_log('  N points: %d\n', lr_results.n_points);
console_log('  Storage (S): %.4e\n', storage_results.S);
console_log('  Specific storage (Ss): %.4e 1/m\n', storage_results.S_s);
console_log('\n');

console_log('TRADITIONAL (Aqtesolv, bulk 380 ft):\n');
console_log('  Storage (S): %.4e\n', storage_config.S_traditional);
console_log('  Ratio (DAS/Traditional): %.4f\n', storage_results.S / storage_config.S_traditional);
console_log('\n');

console_log('✓ Depth-specific storage analysis complete!\n');
console_log('  Results stored in: das_results.%s.linear_regression_depth_range\n', test_name);
console_log('\n');



