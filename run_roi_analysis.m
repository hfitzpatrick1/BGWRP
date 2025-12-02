%% Standalone ROI Analysis Script
% Run this after correlation analysis to test ROI spatial difference method

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

% Set up ROI analysis configuration - MATCH SINGLE CHANNEL SUCCESS PARAMETERS
lr_config = struct();
lr_config.zone = 'z5';
lr_config.depth_range_ft = [255, 320];  % 255-320 ft - focused range with enough channels for forward diff
lr_config.timing_correction_sec = 14;  % Testing 14s timing (between 12s=0.515 and 15s=0.534)
lr_config.show_plots = true;  % Set to false for cleaner output

% Focus on PEAK REGION ONLY (19:14 to 19:17 UTC) where signals align best
lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                            datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];

fprintf('=== RUNNING FOCUSED STRAIN RATE ANALYSIS AT 284.7 FT ===\n');
fprintf('Depth range: %.0f-%.0f ft (wide range to ensure sufficient channels for forward differencing)\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
fprintf('Method: Centered spatial difference ε̇ = [u̇(z+5m) - u̇(z-5m)] / L at 284.7 ft\n');
fprintf('Parameters: SAME as successful single-channel (8s timing, 5s smoothing)\n\n');

% Run ROI depth range analysis
roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);

fprintf('\n=== FOCUSED STRAIN RATE RESULTS (284.7 FT) ===\n');
fprintf('Target depth: 284.7 ft (same as single-channel success)\n');
fprintf('Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
fprintf('R²: %.4f\n', roi_results.R_squared);
fprintf('Correlation (R): %.4f\n', roi_results.R);
fprintf('RMSE: %.4e 1/s\n', roi_results.RMSE);
fprintf('Method: Centered difference ε̇ = [u̇(z+5m) - u̇(z-5m)] / L\n');
fprintf('Processing: Same as single-channel (8s timing, 5s smoothing)\n');

% Compare with single channel results if available
if isfield(das_results.PT01c_Recovery_short, 'linear_regression')
    single_results = das_results.PT01c_Recovery_short.linear_regression;
    fprintf('\n=== COMPARISON WITH SINGLE CHANNEL ===\n');
    fprintf('Single Channel (285 ft):\n');
    fprintf('  Slope: %.4e (1/s)/(ft/s)\n', single_results.slope);
    fprintf('  R²: %.4f\n', single_results.R_squared);
    fprintf('  Method: ε̇ = u̇(z,t) / L\n');
    fprintf('\nROI Spatial Difference (190-310 ft):\n');
    fprintf('  Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
    fprintf('  R²: %.4f\n', roi_results.R_squared);
    fprintf('  Method: ε̇ = [u̇(z+L) - u̇(z)] / L\n');
    fprintf('\nSlope ratio (ROI/Single): %.2f\n', roi_results.slope / single_results.slope);
    fprintf('R² difference: %.4f\n', roi_results.R_squared - single_results.R_squared);
end

fprintf('\n=== ANALYSIS COMPLETE ===\n');
