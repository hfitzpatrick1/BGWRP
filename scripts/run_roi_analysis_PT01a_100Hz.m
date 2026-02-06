%% ROI Analysis Script for PT01a 100 Hz Data
% Run this after correlation analysis with 100 Hz data

% Make sure you've run correlation analysis first
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Need to run correlation analysis first: mode = ''run_correlation_analysis_lowpass_PT01a''; BGWRP_Toolkit');
end

% Detect which PT01a dataset was processed
fprintf('DEBUG: Checking for PT01a datasets in das_results...\n');
all_datasets = fieldnames(das_results);
fprintf('DEBUG: Available datasets: %s\n', strjoin(all_datasets, ', '));

if isfield(das_results, 'PT01a_Recovery_100')
    dataset_name = 'PT01a_Recovery_100';
    fprintf('Using 100 Hz dataset: PT01a_Recovery_100\n');
elseif isfield(das_results, 'PT01a_Recovery_short')
    dataset_name = 'PT01a_Recovery_short';
    fprintf('Using 1 Hz dataset: PT01a_Recovery_short\n');
else
    error('No PT01a dataset found in das_results. Available datasets: %s', strjoin(all_datasets, ', '));
end

% DEBUG: Check what fields exist in the selected dataset
dataset_fields = fieldnames(das_results.(dataset_name));
fprintf('DEBUG: Fields in %s: %s\n', dataset_name, strjoin(dataset_fields, ', '));

% Set up ROI analysis configuration - FOCUS ON PT01a PUMPING ZONE
lr_config = struct();
lr_config.zone = 'z2';  % USING ZONE 2 (PT01a pumping zone)
lr_config.depth_range_ft = [450, 510];  % PT01a pumping zone (includes channel 1099 at 480 ft)
lr_config.timing_correction_sec = 14;  % Optimal timing correction
lr_config.show_plots = true;  % Set to false for cleaner output

% Focus on PEAK REGION for best correlation (PT01a dates: Nov 7, 2023)
lr_config.recovery_window = [datetime('2023-11-07 20:45:15', 'TimeZone', 'UTC'), ...
                            datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC')];

fprintf('\n=== RUNNING ROI STRAIN RATE ANALYSIS (PT01a PUMPING ZONE) ===\n');
fprintf('Dataset: %s\n', dataset_name);
fprintf('Depth range: %.0f-%.0f ft (PT01a pumping zone - includes channel 1099 at 480 ft)\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
fprintf('Method: Proper Becker spatial difference ε̇ = [u̇(z+L) - u̇(z)] / L\n');
fprintf('Parameters: Temporal weighting, maximum envelope, Bourdet, narrowed window\n\n');

% Run ROI depth range analysis
roi_results = linear_regression_depth_range(das_results, head_results, dataset_name, lr_config);

fprintf('\n=== ROI STRAIN RATE RESULTS (PT01a PUMPING ZONE) ===\n');
fprintf('Dataset: %s\n', dataset_name);
fprintf('Depth range: %.0f-%.0f ft (PT01a pumping zone centered on 480 ft)\n', roi_results.depth_range_ft(1), roi_results.depth_range_ft(2));
fprintf('Slope: %.4e (1/s)/(ft/s)\n', roi_results.slope);
fprintf('R²: %.4f\n', roi_results.R_squared);
fprintf('Correlation (R): %.4f\n', roi_results.R);
fprintf('RMSE: %.4e 1/s\n', roi_results.RMSE);
fprintf('Method: Proper Becker ε̇ = [u̇(z+L) - u̇(z)] / L\n');
fprintf('Processing: Temporal weighting, maximum envelope, Bourdet derivative\n');

% Compare with single channel results if available
dataset_struct = das_results.(dataset_name);
if isfield(dataset_struct, 'linear_regression')
    single_results = dataset_struct.linear_regression;
    fprintf('\n=== COMPARISON WITH SINGLE CHANNEL ===\n');
    fprintf('Single Channel (285 ft):\n');
    fprintf('  Slope: %.4e (1/s)/(ft/s)\n', single_results.slope);
    fprintf('  R²: %.4f\n', single_results.R_squared);
    fprintf('  Method: ε̇ = u̇(z,t) / L\n');
    fprintf('\nROI Spatial Difference (%.0f-%.0f ft):\n', roi_results.depth_range_ft(1), roi_results.depth_range_ft(2));
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

% Storage configuration
storage_config = struct();
storage_config.alpha = 0.90;  % Biot-Willis coefficient
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

% Store results in appropriate dataset
das_results.(dataset_name).roi_storage = storage_results;
das_results.(dataset_name).roi_linear_regression = roi_results;

%% Final Summary
fprintf('\n');
fprintf('╔═══════════════════════════════════════════════════════════════╗\n');
fprintf('║  FINAL STORAGE RESULTS (ROI Method)                          ║\n');
fprintf('╚═══════════════════════════════════════════════════════════════╝\n');
fprintf('\n');
fprintf('Dataset: %s\n', dataset_name);
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
if isfield(dataset_struct, 'storage_results')
    single_storage = dataset_struct.storage_results;
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
