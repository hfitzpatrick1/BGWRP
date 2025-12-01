%% Standalone ROI Analysis Script
% Run this after correlation analysis to test ROI spatial difference method

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis''; BGWRP_Toolkit');
end

% Set up ROI analysis configuration
lr_config = struct();
lr_config.zone = 'z5';
lr_config.depth_range_ft = [175, 335];  % Larger ROI section
lr_config.timing_correction_sec = 8;
lr_config.show_plots = true;  % Set to false for cleaner output

fprintf('=== RUNNING ROI SPATIAL DIFFERENCE ANALYSIS ===\n');
fprintf('Depth range: %.0f-%.0f ft\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
fprintf('Method: Spatial difference across gauge length\n\n');

% Run ROI depth range analysis
roi_results = linear_regression_depth_range(das_results, head_results, 'PT01c_Recovery_short', lr_config);

fprintf('\n=== ROI RESULTS SUMMARY ===\n');
fprintf('Depth range: %.0f-%.0f ft\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
fprintf('Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
fprintf('R²: %.4f\n', roi_results.R_squared);
fprintf('Correlation (R): %.4f\n', roi_results.R);
fprintf('RMSE: %.4e 1/s\n', roi_results.RMSE);
fprintf('Method: Spatial difference ε̇ = [u̇(z+L) - u̇(z)] / L\n');
fprintf('Channels analyzed: %d\n', length(find(das_results.PT01c_Recovery_short.depth_ft >= lr_config.depth_range_ft(1) & das_results.PT01c_Recovery_short.depth_ft <= lr_config.depth_range_ft(2))));

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
