%% PT-01b Depth-Range Linear Regression Analysis
% Runs linear regression between DAS strain rate and head drawdown rate
% using depth-averaged method for PT01b_Recovery_short

clear; clc;

%% Load configuration
config_main = config();

%% Step 1: Load or generate DAS and head results
console_log('=== LOADING DATA ===\n');

% Check if data already exists in workspace
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    console_log('Running data analysis to generate das_results and head_results...\n');
    
    % Run the toolkit in analysis mode to generate results
    cd('C:\Coding\BGWRP\src');
    mode = 'run';
    BGWRP_Toolkit;
    
    console_log('✓ Data analysis complete\n');
end

%% Step 2: Configure regression parameters for PT-01b
console_log('\n=== CONFIGURING PT-01B REGRESSION ===\n');

lr_config = struct();

% Test configuration
lr_config.test_name = 'PT01b_Recovery_short';

% Zone selection - using z4 (zone 4 monitoring well)
lr_config.zone = 'z4';

% Depth range: 340-440 ft (104-134 m, ~30 m range)
% This matches PT-01c's approach of ~31 m vertical extent
lr_config.depth_range_ft = [340, 440];  % 100 ft range around pumping zone

% Timing correction - adjust head data timing relative to DAS
% Negative values shift head data FORWARD (earlier in time)
% Positive values shift head data BACKWARD (later in time)
lr_config.timing_correction_sec = -50;  % Shift head data later by 60 seconds to align peaks

% Recovery window - use focused 3-minute peak signal period
% This matches the analysis window used in Figure 102
lr_config.recovery_window = [
    datetime(2023, 10, 31, 19, 29, 30, 'TimeZone', 'UTC')
    datetime(2023, 10, 31, 19, 32, 30, 'TimeZone', 'UTC')
];

% Display options
lr_config.show_plots = true;
lr_config.use_si_units = true;  % Use m/s for rates

console_log('Configuration:\n');
console_log('  Test: %s\n', lr_config.test_name);
console_log('  Zone: %s\n', lr_config.zone);
console_log('  Depth range: %.0f-%.0f ft\n', lr_config.depth_range_ft(1), lr_config.depth_range_ft(2));
console_log('  Timing correction: %d seconds\n', lr_config.timing_correction_sec);
console_log('  Recovery window: %s to %s\n', ...
    datestr(lr_config.recovery_window(1)), datestr(lr_config.recovery_window(2)));

%% Step 3: Run depth-range regression
console_log('\n=== RUNNING DEPTH-RANGE REGRESSION ===\n');

try
    results = linear_regression_depth_range(das_results, head_results, lr_config.test_name, lr_config);
    
    console_log('\n=== REGRESSION RESULTS ===\n');
    console_log('Slope: %.4e (1/s)/(m/s)\n', results.slope);
    console_log('Intercept: %.4e 1/s\n', results.intercept);
    console_log('R: %.4f\n', results.R);
    console_log('R²: %.4f\n', results.R_squared);
    console_log('RMSE: %.4e 1/s\n', results.RMSE);
    console_log('Points: %d\n', results.n_points);
    console_log('Channels: %d\n', results.n_channels);
    
    %% Step 4: Calculate storage from slope
    console_log('\n=== CALCULATING SPECIFIC STORAGE ===\n');
    
    % From Becker 2006: ε̇ = Ss × (∂h/∂t)
    % So: Ss = ε̇ / (∂h/∂t) = slope
    Ss = results.slope;  % Specific storage (1/m)
    
    console_log('Specific Storage (Ss): %.4e 1/m\n', Ss);
    
    % Calculate storativity if aquifer thickness is known
    aquifer_thickness_m = config_main.aquifer_thickness_m;  % From config
    S = Ss * aquifer_thickness_m;  % Storativity (dimensionless)
    
    console_log('Aquifer thickness: %.1f m\n', aquifer_thickness_m);
    console_log('Storativity (S): %.4e\n', S);
    
    % Compare with traditional values from config
    if isfield(config_main, 'traditional_S')
        console_log('\nComparison with traditional pump test:\n');
        console_log('  Traditional S: %.4e\n', config_main.traditional_S);
        console_log('  DAS-derived S: %.4e\n', S);
        console_log('  Ratio (DAS/Traditional): %.2f\n', S / config_main.traditional_S);
    end
    
catch ME
    console_log('\n✗ ERROR running regression:\n');
    console_log('  %s\n', ME.message);
    console_log('  File: %s\n', ME.stack(1).file);
    console_log('  Line: %d\n', ME.stack(1).line);
    rethrow(ME);
end

%% Step 5: Recommendations for adjustment
console_log('\n=== NEXT STEPS ===\n');
console_log('1. Check the time series plot (subplot b) - are peaks aligned?\n');
console_log('   - If DAS peak comes BEFORE head peak: DECREASE timing_correction_sec\n');
console_log('   - If DAS peak comes AFTER head peak: INCREASE timing_correction_sec\n');
console_log('2. Check R² value:\n');
console_log('   - R² > 0.5: Good correlation, results are reliable\n');
console_log('   - R² < 0.5: Poor correlation, adjust timing or try different zone\n');
console_log('3. Try different zones (z2, z3, z4, z5) to find best correlation\n');
console_log('4. Adjust depth_range_ft if needed to focus on most responsive region\n');

console_log('\nTo re-run with different settings, modify lr_config and run:\n');
console_log('  results = linear_regression_depth_range(das_results, head_results, ''%s'', lr_config);\n', lr_config.test_name);

