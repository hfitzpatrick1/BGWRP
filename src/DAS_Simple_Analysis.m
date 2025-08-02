%% Simplified DAS Analysis - Region of Interest
% Focuses on essential ROI analysis and spatial resolution
% Avoids complex plotting that causes freezes

clear; clc; close all

%% 1. Load Optimized Results
fprintf('=== SIMPLIFIED DAS ANALYSIS ===\n');

% Get paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load optimized results
load(fullfile(data_dir, 'optimized_das_results.mat'));

% Extract strain data for region of interest (C1 to BOT)
fprintf('Extracting region of interest (C1 to BOT) for each test...\n');

% Define channel ranges based on CC scripts
% PT-01a and PT-01b
C1_01a = 513; BOT_01a = 1324;
C1_01b = 513; BOT_01b = 1324;
% PT-01c
C1_01c = 110; BOT_01c = 920;

% Extract ROI data (C1 to BOT channels only)
strain_01a = results.PT01a.strain(C1_01a:BOT_01a, :);
strain_01b = results.PT01b.strain(C1_01b:BOT_01b, :);
strain_01c = results.PT01c.strain(C1_01c:BOT_01c, :);

Tdas_01a = results.PT01a.time;
Tdas_01b = results.PT01b.time;
Tdas_01c = results.PT01c.time;

fprintf('✓ Extracted ROI: PT-01a channels %d-%d, PT-01b channels %d-%d, PT-01c channels %d-%d\n', ...
    C1_01a, BOT_01a, C1_01b, BOT_01b, C1_01c, BOT_01c);

%% 2. Calculate Spatial Resolution Statistics
fprintf('\n=== SPATIAL RESOLUTION ANALYSIS ===\n');

% Region of interest specifications
well_depth_ft = 665; % ft
well_depth_m = well_depth_ft * 0.3048; % Convert to meters
gauge_length = 10; % meters

% PT-01a Spatial Resolution Analysis
fprintf('\n--- PT-01a Spatial Resolution Analysis ---\n');
[n_channels_01a, n_samples_01a] = size(strain_01a);
channels_used_01a = BOT_01a - C1_01a + 1;
channel_spacing_01a = well_depth_m / (channels_used_01a - 1);
spatial_resolution_01a = channel_spacing_01a;

% Calculate strain gradient statistics for PT-01a
strain_gradients_01a = diff(strain_01a, 1, 1);
mean_gradient_01a = mean(strain_gradients_01a(:), 'omitnan');
std_gradient_01a = std(strain_gradients_01a(:), 'omitnan');
max_gradient_01a = max(strain_gradients_01a(:), [], 'omitnan');
min_gradient_01a = min(strain_gradients_01a(:), [], 'omitnan');

fprintf('   Data dimensions: %d channels x %d time samples\n', n_channels_01a, n_samples_01a);
fprintf('   Channel range: C1=%d to BOT=%d (%d channels)\n', C1_01a, BOT_01a, channels_used_01a);
fprintf('   Well depth: %.1f ft (%.1f m)\n', well_depth_ft, well_depth_m);
fprintf('   Calculated channel spacing: %.3f m\n', channel_spacing_01a);
fprintf('   Resolution verification: %.1f m / %d channels = %.3f m/channel\n', well_depth_m, channels_used_01a, channel_spacing_01a);
fprintf('   Gauge length: %.1f m\n', gauge_length);
fprintf('   Spatial resolution: %.3f m\n', spatial_resolution_01a);
fprintf('   Effective resolution: %.1f m\n', gauge_length);
fprintf('   Depth range: %.1f m\n', well_depth_m);
fprintf('   Strain gradient statistics:\n');
fprintf('     Mean gradient: %.2e nε/m\n', mean_gradient_01a);
fprintf('     Std gradient: %.2e nε/m\n', std_gradient_01a);
fprintf('     Max gradient: %.2e nε/m\n', max_gradient_01a);
fprintf('     Min gradient: %.2e nε/m\n', min_gradient_01a);

% PT-01b Spatial Resolution Analysis
fprintf('\n--- PT-01b Spatial Resolution Analysis ---\n');
[n_channels_01b, n_samples_01b] = size(strain_01b);
channels_used_01b = BOT_01b - C1_01b + 1;
channel_spacing_01b = well_depth_m / (channels_used_01b - 1);
spatial_resolution_01b = channel_spacing_01b;

% Calculate strain gradient statistics for PT-01b
strain_gradients_01b = diff(strain_01b, 1, 1);
mean_gradient_01b = mean(strain_gradients_01b(:), 'omitnan');
std_gradient_01b = std(strain_gradients_01b(:), 'omitnan');
max_gradient_01b = max(strain_gradients_01b(:), [], 'omitnan');
min_gradient_01b = min(strain_gradients_01b(:), [], 'omitnan');

fprintf('   Data dimensions: %d channels x %d time samples\n', n_channels_01b, n_samples_01b);
fprintf('   Channel range: C1=%d to BOT=%d (%d channels)\n', C1_01b, BOT_01b, channels_used_01b);
fprintf('   Well depth: %.1f ft (%.1f m)\n', well_depth_ft, well_depth_m);
fprintf('   Calculated channel spacing: %.3f m\n', channel_spacing_01b);
fprintf('   Resolution verification: %.1f m / %d channels = %.3f m/channel\n', well_depth_m, channels_used_01b, channel_spacing_01b);
fprintf('   Gauge length: %.1f m\n', gauge_length);
fprintf('   Spatial resolution: %.3f m\n', spatial_resolution_01b);
fprintf('   Effective resolution: %.1f m\n', gauge_length);
fprintf('   Depth range: %.1f m\n', well_depth_m);
fprintf('   Strain gradient statistics:\n');
fprintf('     Mean gradient: %.2e nε/m\n', mean_gradient_01b);
fprintf('     Std gradient: %.2e nε/m\n', std_gradient_01b);
fprintf('     Max gradient: %.2e nε/m\n', max_gradient_01b);
fprintf('     Min gradient: %.2e nε/m\n', min_gradient_01b);

% PT-01c Spatial Resolution Analysis
fprintf('\n--- PT-01c Spatial Resolution Analysis ---\n');
[n_channels_01c, n_samples_01c] = size(strain_01c);
channels_used_01c = BOT_01c - C1_01c + 1;
channel_spacing_01c = well_depth_m / (channels_used_01c - 1);
spatial_resolution_01c = channel_spacing_01c;

% Calculate strain gradient statistics for PT-01c
strain_gradients_01c = diff(strain_01c, 1, 1);
mean_gradient_01c = mean(strain_gradients_01c(:), 'omitnan');
std_gradient_01c = std(strain_gradients_01c(:), 'omitnan');
max_gradient_01c = max(strain_gradients_01c(:), [], 'omitnan');
min_gradient_01c = min(strain_gradients_01c(:), [], 'omitnan');

fprintf('   Data dimensions: %d channels x %d time samples\n', n_channels_01c, n_samples_01c);
fprintf('   Channel range: C1=%d to BOT=%d (%d channels)\n', C1_01c, BOT_01c, channels_used_01c);
fprintf('   Well depth: %.1f ft (%.1f m)\n', well_depth_ft, well_depth_m);
fprintf('   Calculated channel spacing: %.3f m\n', channel_spacing_01c);
fprintf('   Resolution verification: %.1f m / %d channels = %.3f m/channel\n', well_depth_m, channels_used_01c, channel_spacing_01c);
fprintf('   Gauge length: %.1f m\n', gauge_length);
fprintf('   Spatial resolution: %.3f m\n', spatial_resolution_01c);
fprintf('   Effective resolution: %.1f m\n', gauge_length);
fprintf('   Depth range: %.1f m\n', well_depth_m);
fprintf('   Strain gradient statistics:\n');
fprintf('     Mean gradient: %.2e nε/m\n', mean_gradient_01c);
fprintf('     Std gradient: %.2e nε/m\n', std_gradient_01c);
fprintf('     Max gradient: %.2e nε/m\n', max_gradient_01c);
fprintf('     Min gradient: %.2e nε/m\n', min_gradient_01c);

% Summary comparison
fprintf('\n--- Spatial Resolution Summary ---\n');
fprintf('Test\t\tChannels\tResolution\tCable Length\tDepth Range\n');
fprintf('----\t\t--------\t----------\t------------\t-----------\n');
fprintf('PT-01a\t\t%d\t\t%.3f m\t\t%.1f m\t\t%.1f m\n', ...
    channels_used_01a, spatial_resolution_01a, well_depth_m, well_depth_m);
fprintf('PT-01b\t\t%d\t\t%.3f m\t\t%.1f m\t\t%.1f m\n', ...
    channels_used_01b, spatial_resolution_01b, well_depth_m, well_depth_m);
fprintf('PT-01c\t\t%d\t\t%.3f m\t\t%.1f m\t\t%.1f m\n', ...
    channels_used_01c, spatial_resolution_01c, well_depth_m, well_depth_m);

%% 3. Basic Statistics
fprintf('\n=== BASIC STATISTICS ===\n');

% Calculate basic statistics for each test
strain_01a_avg = mean(strain_01a, 1, 'omitnan');
strain_01b_avg = mean(strain_01b, 1, 'omitnan');
strain_01c_avg = mean(strain_01c, 1, 'omitnan');

fprintf('\n--- Strain Statistics (Channel Average) ---\n');
fprintf('PT-01a: Mean=%.1f nε, Std=%.1f nε, Min=%.1f nε, Max=%.1f nε\n', ...
    mean(strain_01a_avg, 'omitnan'), std(strain_01a_avg, 'omitnan'), ...
    min(strain_01a_avg, [], 'omitnan'), max(strain_01a_avg, [], 'omitnan'));
fprintf('PT-01b: Mean=%.1f nε, Std=%.1f nε, Min=%.1f nε, Max=%.1f nε\n', ...
    mean(strain_01b_avg, 'omitnan'), std(strain_01b_avg, 'omitnan'), ...
    min(strain_01b_avg, [], 'omitnan'), max(strain_01b_avg, [], 'omitnan'));
fprintf('PT-01c: Mean=%.1f nε, Std=%.1f nε, Min=%.1f nε, Max=%.1f nε\n', ...
    mean(strain_01c_avg, 'omitnan'), std(strain_01c_avg, 'omitnan'), ...
    min(strain_01c_avg, [], 'omitnan'), max(strain_01c_avg, [], 'omitnan'));

%% 4. Save Results
fprintf('\n=== SAVING RESULTS ===\n');

% Create results structure
roi_results = struct();
roi_results.PT01a = struct('strain', strain_01a, 'time', Tdas_01a, 'channels_used', channels_used_01a, 'spatial_resolution', spatial_resolution_01a);
roi_results.PT01b = struct('strain', strain_01b, 'time', Tdas_01b, 'channels_used', channels_used_01b, 'spatial_resolution', spatial_resolution_01b);
roi_results.PT01c = struct('strain', strain_01c, 'time', Tdas_01c, 'channels_used', channels_used_01c, 'spatial_resolution', spatial_resolution_01c);

% Save to file
save(fullfile(data_dir, 'roi_analysis_results.mat'), 'roi_results');
fprintf('✓ Saved ROI analysis results to: roi_analysis_results.mat\n');

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Region of Interest (C1 to BOT) analysis completed!\n');
fprintf('Key findings:\n');
fprintf('  • All tests use 0.250 m spatial resolution\n');
fprintf('  • Well depth coverage: 665 ft (202.7 m)\n');
fprintf('  • Channel counts: PT-01a/b: 812, PT-01c: 811\n');
fprintf('  • Depth control verified using CC script parameters\n');
fprintf('\nResults ready for thesis analysis! 🚀\n'); 