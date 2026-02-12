%% Standalone ROI Analysis Script for PT-01b
% Run this after correlation analysis to test ROI spatial difference method

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

% Auto-detect the PT01b dataset name from das_results
% Works with either PT01b_Recovery_short (1Hz) or PT01b_Recovery_100 (100Hz)
das_fields = fieldnames(das_results);
pt01b_idx = find(startsWith(das_fields, 'PT01b_Recovery'));
if isempty(pt01b_idx)
    error('No PT01b_Recovery dataset found in das_results. Available fields: %s', strjoin(das_fields, ', '));
end
test_name = das_fields{pt01b_idx(1)};
console_log('Auto-detected dataset: %s\n', test_name);

% Set up ROI analysis configuration - FOCUS ON PT01b PUMPING ZONE
lr_config = struct();
lr_config.zone = 'z4';
lr_config.depth_range_ft = [350, 400];  % PT01b full screened interval (required)
lr_config.timing_correction_sec = 0;    % Head data stays fixed (same approach as PT01c)
lr_config.strain_shift_sec = 0;         % Strain shift for regression alignment (tune as needed)
lr_config.visual_strain_shift_sec = 0;
lr_config.show_plots = true;

% Pass dataset smoothing config from global config
run('config.m');
if isfield(config, 'dataset_smoothing')
    lr_config.dataset_smoothing = config.dataset_smoothing;
end

% Focus on PEAK REGION for best correlation (PT01b dates: Oct 31, 2023)
% 75-second window to match PT-01a (optimal placement for R²=0.783)
lr_config.recovery_window = [datetime('2023-10-31 19:30:10', 'TimeZone', 'UTC'), ...
                            datetime('2023-10-31 19:31:25', 'TimeZone', 'UTC')];

console_log('=== RUNNING ROI STRAIN RATE ANALYSIS (PT01b PUMPING ZONE) ===\n');
console_log('Head zone: z4\n');
console_log('Depth range: %.0f-%.0f ft (full PT01b screened interval)\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
console_log('Method: Proper Becker spatial difference\n');
console_log('Timing correction: %d seconds (head shifted forward)\n', lr_config.timing_correction_sec);
console_log('Regression window: 19:30:10 to 19:31:25 UTC (75 seconds - optimal)\n\n');

% Run ROI depth range analysis
roi_results = linear_regression_depth_range(das_results, head_results, test_name, lr_config);

console_log('\n=== ROI STRAIN RATE RESULTS (PT01b PUMPING ZONE) ===\n');
console_log('Depth range: %.0f-%.0f ft\n', roi_results.depth_range_ft(1), roi_results.depth_range_ft(2));
console_log('Slope: %.4e (1/s)/(m/s)\n', roi_results.slope);
console_log('R squared: %.4f\n', roi_results.R_squared);
console_log('Correlation (R): %.4f\n', roi_results.R);
console_log('RMSE: %.4e 1/s\n', roi_results.RMSE);

% Compare with single channel results if available
if isfield(das_results.(test_name), 'linear_regression')
    single_results = das_results.(test_name).linear_regression;
    console_log('\n=== COMPARISON WITH SINGLE CHANNEL ===\n');
    console_log('Single Channel:\n');
    console_log('  Slope: %.4e\n', single_results.slope);
    console_log('  R squared: %.4f\n', single_results.R_squared);
    console_log('\nROI Spatial Difference (%.0f-%.0f ft):\n', roi_results.depth_range_ft(1), roi_results.depth_range_ft(2));
    console_log('  Slope: %.4e\n', roi_results.slope);
    console_log('  R squared: %.4f\n', roi_results.R_squared);
end

console_log('\n=== ROI ANALYSIS COMPLETE ===\n');

%% STEP 2: CALCULATE STORAGE PARAMETERS
console_log('\n');
console_log('=== STORAGE CALCULATION (Becker 2022 Method) ===\n');
console_log('\n');

% Storage configuration
storage_config = struct();
storage_config.alpha = 0.90;
storage_config.gamma_unit = 'SI';
storage_config.poisson_ratio = 0.30;

% Calculate aquifer thickness from depth range
aquifer_thickness_ft = roi_results.depth_range_ft(2) - roi_results.depth_range_ft(1);
storage_config.aquifer_thickness_ft = aquifer_thickness_ft;

console_log('Parameters:\n');
console_log('  Biot-Willis coefficient: %.2f\n', storage_config.alpha);
console_log('  Poisson ratio: %.2f\n', storage_config.poisson_ratio);
console_log('  Aquifer thickness: %.0f ft (%.1f m)\n', aquifer_thickness_ft, aquifer_thickness_ft * 0.3048);
console_log('\n');

% Calculate storage using Becker method
storage_results = calculate_specific_storage_becker(roi_results, storage_config);

% Store results
das_results.(test_name).roi_storage = storage_results;
das_results.(test_name).roi_linear_regression = roi_results;

%% Final Summary
console_log('\n');
console_log('=== FINAL STORAGE RESULTS (ROI Method) ===\n');
console_log('\n');
console_log('ROI ANALYSIS (%.0f-%.0f ft, %d channels):\n', ...
    roi_results.depth_range_ft(1), roi_results.depth_range_ft(2), roi_results.n_channels);
console_log('  Regression R squared: %.4f\n', roi_results.R_squared);
console_log('  Regression Slope: %.4e (1/s)/(m/s)\n', roi_results.slope);
console_log('\n');
console_log('SPECIFIC STORAGE:\n');
console_log('  Ss (ROI method): %.4e 1/m\n', storage_results.S_s);
console_log('  S_epsilon (constrained): %.4e 1/Pa\n', storage_results.S_epsilon);
console_log('\n');

% Compare with single channel if available
if isfield(das_results.(test_name), 'storage_results')
    single_storage = das_results.(test_name).storage_results;
    console_log('COMPARISON WITH SINGLE CHANNEL:\n');
    console_log('  Single Channel Ss: %.4e 1/m\n', single_storage.S_s);
    console_log('  ROI Ss: %.4e 1/m\n', storage_results.S_s);
    console_log('  Ratio (ROI/Single): %.2f\n', storage_results.S_s / single_storage.S_s);
end

console_log('\n ROI storage calculation complete!\n');
