%% Standalone ROI Analysis Script
% Run this after correlation analysis to test ROI spatial difference method

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

% Set up ROI analysis configuration - MATCH SINGLE CHANNEL SUCCESS PARAMETERS
lr_config = struct();
lr_config.zone = 'z5';
lr_config.depth_range_ft = [250, 350];  % Full range around most responsive zone (matching R²=0.715 result)
lr_config.timing_correction_sec = 15;  % Testing 15s timing
lr_config.show_plots = true;  % Set to false for cleaner output

% Focus on PEAK REGION for best correlation
lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                            datetime('2023-10-24 19:16:30', 'TimeZone', 'UTC')];

fprintf('=== RUNNING ROI STRAIN RATE ANALYSIS (260-310 ft) ===\n');
fprintf('Depth range: %.0f-%.0f ft (narrower range around 284.7 ft target)\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
fprintf('Method: Proper Becker spatial difference ε̇ = [u̇(z+L) - u̇(z)] / L\n');
fprintf('Parameters: 20s timing correction, maximum envelope method, Bourdet, 19:14-19:17 window\n\n');

% Run ROI depth range analysis
roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);

fprintf('\n=== ROI STRAIN RATE RESULTS (260-310 FT) ===\n');
fprintf('Depth range: 260-310 ft (narrower range around 284.7 ft target)\n');
fprintf('Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
fprintf('R²: %.4f\n', roi_results.R_squared);
fprintf('Correlation (R): %.4f\n', roi_results.R);
fprintf('RMSE: %.4e 1/s\n', roi_results.RMSE);
fprintf('Method: Proper Becker ε̇ = [u̇(z+L) - u̇(z)] / L\n');
fprintf('Processing: 20s timing correction, maximum envelope method, Bourdet, 19:14-19:17 window\n');

% Compare with single channel results if available
if isfield(das_results.PT01c_Recovery_short, 'linear_regression')
    single_results = das_results.PT01c_Recovery_short.linear_regression;
    fprintf('\n=== COMPARISON WITH SINGLE CHANNEL ===\n');
    fprintf('Single Channel (285 ft):\n');
    fprintf('  Slope: %.4e (1/s)/(ft/s)\n', single_results.slope);
    fprintf('  R²: %.4f\n', single_results.R_squared);
    fprintf('  Method: ε̇ = u̇(z,t) / L\n');
    fprintf('\nROI Spatial Difference (260-310 ft):\n');
    fprintf('  Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
    fprintf('  R²: %.4f\n', roi_results.R_squared);
    fprintf('  Method: ε̇ = [u̇(z+L) - u̇(z)] / L\n');
    fprintf('\nSlope ratio (ROI/Single): %.2f\n', roi_results.slope / single_results.slope);
    fprintf('R² difference: %.4f\n', roi_results.R_squared - single_results.R_squared);
end

fprintf('\n=== ANALYSIS COMPLETE ===\n');

%% STEP 2: CALCULATE STORAGE PARAMETERS
fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║  STORAGE CALCULATION (Becker 2022 Method)                     ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

% Storage configuration - MATCH SINGLE CHANNEL SETTINGS
storage_config = struct();
storage_config.alpha = 0.90;  % Same as single channel (was 0.95)
storage_config.gamma_unit = 'SI';  % Use SI units
storage_config.poisson_ratio = 0.30;  % Typical for sand/sandstone

% Calculate aquifer thickness from depth range
aquifer_thickness_ft = roi_results.depth_range_ft(2) - roi_results.depth_range_ft(1);
storage_config.aquifer_thickness_ft = aquifer_thickness_ft;

fprintf('Parameters:\n');
fprintf('  Biot-Willis coefficient (α): %.2f\n', storage_config.alpha);
fprintf('  Poisson ratio (ν): %.2f\n', storage_config.poisson_ratio);
fprintf('  Aquifer thickness: %.0f ft (%.1f m)\n', aquifer_thickness_ft, aquifer_thickness_ft * 0.3048);
fprintf('\n');

% Calculate storage using Becker method
storage_results = calculate_specific_storage_becker(roi_results, storage_config);

% Store results
das_results.PT01c_Recovery_short.roi_storage = storage_results;
das_results.PT01c_Recovery_short.roi_linear_regression = roi_results;

%% Final Summary
fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║  FINAL STORAGE RESULTS (ROI Method)                          ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n');
fprintf('\n');
fprintf('ROI ANALYSIS (%.0f-%.0f ft, %d channels):\n', ...
    roi_results.depth_range_ft(1), roi_results.depth_range_ft(2), roi_results.n_channels);
fprintf('  Regression R²: %.4f\n', roi_results.R_squared);
fprintf('  Regression Slope: %.4e (1/s)/(m/s)\n', roi_results.slope);
fprintf('\n');
fprintf('SPECIFIC STORAGE:\n');
fprintf('  Ss (ROI method): %.4e 1/m\n', storage_results.S_s);
fprintf('  S_ε (constrained): %.4e 1/Pa\n', storage_results.S_epsilon);
fprintf('\n');

% Compare with single channel if available
if isfield(das_results.PT01c_Recovery_short, 'storage_results')
    single_storage = das_results.PT01c_Recovery_short.storage_results;
    fprintf('COMPARISON WITH SINGLE CHANNEL (285 ft):\n');
    fprintf('  Single Channel Ss: %.4e 1/m\n', single_storage.S_s);
    fprintf('  ROI Ss: %.4e 1/m\n', storage_results.S_s);
    fprintf('  Ratio (ROI/Single): %.2f\n', storage_results.S_s / single_storage.S_s);
    fprintf('\n');
    fprintf('  Single Channel Slope: %.4e\n', single_storage.slope_raw);
    fprintf('  ROI Slope: %.4e\n', roi_results.slope);
    fprintf('  Slope Ratio: %.2f\n', roi_results.slope / single_storage.slope_raw);
end

fprintf('\n✓ ROI storage calculation complete!\n');
