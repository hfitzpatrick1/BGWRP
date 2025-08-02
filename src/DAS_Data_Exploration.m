%% DAS Data Exploration Script
% This script explores DAS data characteristics to identify noise sources
% and optimize processing parameters before implementing in main analysis

clear; clc; close all

%% 1. Setup and Load Data
fprintf('=== DAS DATA EXPLORATION ===\n');

% Get paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load all DAS datasets for exploration
pt01a_file = fullfile(data_dir, 'PM07_01a_1Hz.mat');
pt01b_file = fullfile(data_dir, 'PM07_01b_1Hz.mat');
pt01c_file = fullfile(data_dir, 'PM07_01c_1Hz.mat');

load(pt01a_file); data_01a = decdata; clear decdata;
load(pt01b_file); data_01b = decdata; clear decdata;
load(pt01c_file); data_01c = decdata; clear decdata;

fprintf('✓ Loaded PT-01a DAS data: [%d x %d]\n', size(data_01a));
fprintf('✓ Loaded PT-01b DAS data: [%d x %d]\n', size(data_01b));
fprintf('✓ Loaded PT-01c DAS data: [%d x %d]\n', size(data_01c));

%% 2. Raw Data Characteristics - Individual Analysis
fprintf('\n=== RAW DATA CHARACTERISTICS ===\n');

% Function to analyze single dataset
function analyze_dataset(data, test_name)
    fprintf('\n--- %s ---\n', test_name);
    
    % Basic statistics
    fprintf('Raw data statistics:\n');
    fprintf('  Mean: %.2e\n', mean(data(:), 'omitnan'));
    fprintf('  Std: %.2e\n', std(data(:), 'omitnan'));
    fprintf('  Min: %.2e\n', min(data(:), [], 'omitnan'));
    fprintf('  Max: %.2e\n', max(data(:), [], 'omitnan'));
    fprintf('  NaN count: %d\n', sum(isnan(data(:))));
    
    % Time series characteristics
    time_series = mean(data, 2, 'omitnan');
    fprintf('\nTime series characteristics:\n');
    fprintf('  Mean: %.2e\n', mean(time_series, 'omitnan'));
    fprintf('  Std: %.2e\n', std(time_series, 'omitnan'));
    if length(time_series) >= 2000
        drift = mean(time_series(end-999:end)) - mean(time_series(1:1000));
        fprintf('  Drift (first 1000 vs last 1000): %.2e\n', drift);
    end
    
    % Depth profile characteristics
    depth_profile = mean(data, 1, 'omitnan');
    fprintf('\nDepth profile characteristics:\n');
    fprintf('  Mean: %.2e\n', mean(depth_profile, 'omitnan'));
    fprintf('  Std: %.2e\n', std(depth_profile, 'omitnan'));
end

% Analyze each dataset
analyze_dataset(data_01a, 'PT-01a');
analyze_dataset(data_01b, 'PT-01b');
analyze_dataset(data_01c, 'PT-01c');

%% 3. Depth Control Analysis - All Tests
fprintf('\n=== DEPTH CONTROL ANALYSIS ===\n');

% Current depth control parameters (generic - should be test-specific)
C1 = 110; BOT = 920; well_depth_ft = 665;
dx_m = 0.25; dx_ft = dx_m*3.28084;

% Function to analyze depth control for single dataset
function analyze_depth_control(data, test_name, C1, BOT, well_depth_ft)
    fprintf('\n--- %s Depth Control ---\n', test_name);
    
    % Calculate depths
    DAS_depth_ft = ((0:size(data,2)-1).*0.25)*3.28084;
    raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
    scale = well_depth_ft/raw_depth_ft(BOT);
    final_depth_ft = raw_depth_ft*scale;
    
    fprintf('Depth control parameters:\n');
    fprintf('  C1: %d (%.1f ft)\n', C1, DAS_depth_ft(C1));
    fprintf('  BOT: %d (%.1f ft)\n', BOT, DAS_depth_ft(BOT));
    fprintf('  Scale factor: %.3f\n', scale);
    fprintf('  Final depth range: %.1f to %.1f ft\n', ...
        min(final_depth_ft), max(final_depth_ft));
    
    % Check if C1 and BOT are within bounds
    if C1 > size(data,2) || BOT > size(data,2)
        fprintf('⚠️  WARNING: C1 or BOT exceeds data dimensions!\n');
        fprintf('  Data has %d channels, but C1=%d, BOT=%d\n', ...
            size(data,2), C1, BOT);
    end
end

% Analyze depth control for each dataset
analyze_depth_control(data_01a, 'PT-01a', C1, BOT, well_depth_ft);
analyze_depth_control(data_01b, 'PT-01b', C1, BOT, well_depth_ft);
analyze_depth_control(data_01c, 'PT-01c', C1, BOT, well_depth_ft);

%% 4. Noise Analysis - All Tests
fprintf('\n=== NOISE ANALYSIS ===\n');

% Function to analyze noise for single dataset
function analyze_noise(data, test_name, C1, BOT, well_depth_ft)
    fprintf('\n--- %s Noise Analysis ---\n', test_name);
    
    % Calculate depths for this dataset
    DAS_depth_ft = ((0:size(data,2)-1).*0.25)*3.28084;
    raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
    scale = well_depth_ft/raw_depth_ft(BOT);
    final_depth_ft = raw_depth_ft*scale;
    
    % 4.1 Temporal noise characteristics
    fprintf('Temporal noise analysis:\n');
    
    % Calculate temporal variance for each channel
    temporal_variance = var(data, 0, 1, 'omitnan');
    fprintf('  Temporal variance range: %.2e to %.2e\n', ...
        min(temporal_variance), max(temporal_variance));
    
    % Find channels with highest/lowest temporal variance
    [~, max_var_idx] = max(temporal_variance);
    [~, min_var_idx] = min(temporal_variance);
    fprintf('  Highest variance channel: %d (depth: %.1f ft)\n', ...
        max_var_idx, final_depth_ft(max_var_idx));
    fprintf('  Lowest variance channel: %d (depth: %.1f ft)\n', ...
        min_var_idx, final_depth_ft(min_var_idx));
    
    % 4.2 Spatial noise characteristics
    fprintf('\nSpatial noise analysis:\n');
    
    % Calculate spatial variance for each time point
    spatial_variance = var(data, 0, 2, 'omitnan');
    fprintf('  Spatial variance range: %.2e to %.2e\n', ...
        min(spatial_variance), max(spatial_variance));
    
    % Check for systematic spatial patterns
    spatial_mean = mean(data, 2, 'omitnan');
    spatial_trend = polyfit((1:length(spatial_mean))', spatial_mean, 1);
    fprintf('  Spatial trend slope: %.2e\n', spatial_trend(1));
end

% Analyze noise for each dataset
analyze_noise(data_01a, 'PT-01a', C1, BOT, well_depth_ft);
analyze_noise(data_01b, 'PT-01b', C1, BOT, well_depth_ft);
analyze_noise(data_01c, 'PT-01c', C1, BOT, well_depth_ft);

%% 5. Baseline Analysis - All Tests
fprintf('\n=== BASELINE ANALYSIS ===\n');

% Function to analyze baseline for single dataset
function analyze_baseline(data, test_name)
    fprintf('\n--- %s Baseline Analysis ---\n', test_name);
    
    % Test different baseline periods
    baseline_periods = [60, 180, 300, 600]; % 1, 3, 5, 10 minutes
    fprintf('Baseline period comparison:\n');
    
    for i = 1:length(baseline_periods)
        period = baseline_periods(i);
        if period <= size(data,1)
            baseline = mean(data(1:period,:), 1, 'omitnan');
            baseline_std = std(baseline, 'omitnan');
            fprintf('  %d min baseline: std = %.2e\n', period/60, baseline_std);
        end
    end
    
    % Check for baseline drift
    if size(data,1) >= 600
        early_baseline = mean(data(1:300,:), 1, 'omitnan');
        late_baseline = mean(data(301:600,:), 1, 'omitnan');
        baseline_drift = mean(late_baseline - early_baseline, 'omitnan');
        fprintf('  Baseline drift (first 5 vs next 5 min): %.2e\n', baseline_drift);
    end
end

% Analyze baseline for each dataset
analyze_baseline(data_01a, 'PT-01a');
analyze_baseline(data_01b, 'PT-01b');
analyze_baseline(data_01c, 'PT-01c');

%% 6. Pumping Zone Analysis - All Tests
fprintf('\n=== PUMPING ZONE ANALYSIS ===\n');

% Define different depth ranges to test
depth_ranges = {
    [450, 510],    % Current range (extraction well screened interval)
    [90, 665],     % Full well casing
    [400, 560],    % Wider range around extraction zone
    [480, 520],    % Narrower range
    [300, 400],    % Upper monitoring zone
    [500, 600]     % Lower monitoring zone
};

% Function to analyze pumping zones for single dataset
function analyze_pumping_zones(data, test_name, C1, BOT, well_depth_ft, depth_ranges)
    fprintf('\n--- %s Pumping Zone Analysis ---\n', test_name);
    
    % Calculate depths for this dataset
    DAS_depth_ft = ((0:size(data,2)-1).*0.25)*3.28084;
    raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1);
    scale = well_depth_ft/raw_depth_ft(BOT);
    final_depth_ft = raw_depth_ft*scale;
    
    fprintf('Depth range analysis:\n');
    for i = 1:length(depth_ranges)
        range = depth_ranges{i};
        zone_mask = final_depth_ft >= range(1) & final_depth_ft <= range(2);
        
        if sum(zone_mask) > 0
            zone_data = data(:, zone_mask);
            zone_mean = mean(zone_data, 2, 'omitnan');
            zone_std = std(zone_mean, 'omitnan');
            
            fprintf('  %.0f-%.0f ft (%d channels): std = %.2e\n', ...
                range(1), range(2), sum(zone_mask), zone_std);
        end
    end
end

% Analyze pumping zones for each dataset
analyze_pumping_zones(data_01a, 'PT-01a', C1, BOT, well_depth_ft, depth_ranges);
analyze_pumping_zones(data_01b, 'PT-01b', C1, BOT, well_depth_ft, depth_ranges);
analyze_pumping_zones(data_01c, 'PT-01c', C1, BOT, well_depth_ft, depth_ranges);

%% 7. Create Comprehensive Exploration Plots
fprintf('\n=== CREATING EXPLORATION PLOTS ===\n');

% Calculate depths for all datasets
DAS_depth_ft_01a = ((0:size(data_01a,2)-1).*0.25)*3.28084;
raw_depth_ft_01a = DAS_depth_ft_01a - DAS_depth_ft_01a(C1);
scale_01a = well_depth_ft/raw_depth_ft_01a(BOT);
final_depth_ft_01a = raw_depth_ft_01a*scale_01a;

DAS_depth_ft_01b = ((0:size(data_01b,2)-1).*0.25)*3.28084;
raw_depth_ft_01b = DAS_depth_ft_01b - DAS_depth_ft_01b(C1);
scale_01b = well_depth_ft/raw_depth_ft_01b(BOT);
final_depth_ft_01b = raw_depth_ft_01b*scale_01b;

DAS_depth_ft_01c = ((0:size(data_01c,2)-1).*0.25)*3.28084;
raw_depth_ft_01c = DAS_depth_ft_01c - DAS_depth_ft_01c(C1);
scale_01c = well_depth_ft/raw_depth_ft_01c(BOT);
final_depth_ft_01c = raw_depth_ft_01c*scale_01c;

% Create comprehensive dashboard
figure('Position', [100, 100, 1600, 1200]);

% Plot 1: Raw data overview comparison
subplot(4,4,1)
imagesc(data_01a(1:min(500,size(data_01a,1)), 1:min(100,size(data_01a,2))))
colorbar
title('PT-01a Raw Data')
xlabel('Channel')
ylabel('Time')

subplot(4,4,2)
imagesc(data_01b(1:min(500,size(data_01b,1)), 1:min(100,size(data_01b,2))))
colorbar
title('PT-01b Raw Data')
xlabel('Channel')
ylabel('Time')

subplot(4,4,3)
imagesc(data_01c(1:min(500,size(data_01c,1)), 1:min(100,size(data_01c,2))))
colorbar
title('PT-01c Raw Data')
xlabel('Channel')
ylabel('Time')

% Plot 4: Temporal variance comparison
subplot(4,4,4)
temporal_variance_01a = var(data_01a, 0, 1, 'omitnan');
temporal_variance_01b = var(data_01b, 0, 1, 'omitnan');
temporal_variance_01c = var(data_01c, 0, 1, 'omitnan');

plot(final_depth_ft_01a, temporal_variance_01a, 'b-', 'LineWidth', 1)
hold on
plot(final_depth_ft_01b, temporal_variance_01b, 'r-', 'LineWidth', 1)
plot(final_depth_ft_01c, temporal_variance_01c, 'g-', 'LineWidth', 1)
xlabel('Depth (ft)')
ylabel('Temporal Variance')
title('Temporal Noise Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c')
grid on

% Plot 5-7: Time series comparison
subplot(4,4,5)
time_series_01a = mean(data_01a, 2, 'omitnan');
plot(time_series_01a(1:min(1000,length(time_series_01a))), 'b-', 'LineWidth', 1)
xlabel('Time Point')
ylabel('Mean Signal')
title('PT-01a Time Series')
grid on

subplot(4,4,6)
time_series_01b = mean(data_01b, 2, 'omitnan');
plot(time_series_01b(1:min(1000,length(time_series_01b))), 'r-', 'LineWidth', 1)
xlabel('Time Point')
ylabel('Mean Signal')
title('PT-01b Time Series')
grid on

subplot(4,4,7)
time_series_01c = mean(data_01c, 2, 'omitnan');
plot(time_series_01c(1:min(1000,length(time_series_01c))), 'g-', 'LineWidth', 1)
xlabel('Time Point')
ylabel('Mean Signal')
title('PT-01c Time Series')
grid on

% Plot 8: Depth profile comparison
subplot(4,4,8)
depth_profile_01a = mean(data_01a, 1, 'omitnan');
depth_profile_01b = mean(data_01b, 1, 'omitnan');
depth_profile_01c = mean(data_01c, 1, 'omitnan');

plot(final_depth_ft_01a, depth_profile_01a, 'b-', 'LineWidth', 1)
hold on
plot(final_depth_ft_01b, depth_profile_01b, 'r-', 'LineWidth', 1)
plot(final_depth_ft_01c, depth_profile_01c, 'g-', 'LineWidth', 1)
xlabel('Depth (ft)')
ylabel('Mean Signal')
title('Depth Profile Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c')
grid on

% Plot 9-11: Baseline comparison
subplot(4,4,9)
if size(data_01a,1) >= 600
    early_baseline_01a = mean(data_01a(1:300,:), 1, 'omitnan');
    late_baseline_01a = mean(data_01a(301:600,:), 1, 'omitnan');
    plot(final_depth_ft_01a, early_baseline_01a, 'b-', 'LineWidth', 1)
    hold on
    plot(final_depth_ft_01a, late_baseline_01a, 'b--', 'LineWidth', 1)
    xlabel('Depth (ft)')
    ylabel('Baseline Signal')
    title('PT-01a Baseline')
    legend('First 5 min', 'Next 5 min')
    grid on
end

subplot(4,4,10)
if size(data_01b,1) >= 600
    early_baseline_01b = mean(data_01b(1:300,:), 1, 'omitnan');
    late_baseline_01b = mean(data_01b(301:600,:), 1, 'omitnan');
    plot(final_depth_ft_01b, early_baseline_01b, 'r-', 'LineWidth', 1)
    hold on
    plot(final_depth_ft_01b, late_baseline_01b, 'r--', 'LineWidth', 1)
    xlabel('Depth (ft)')
    ylabel('Baseline Signal')
    title('PT-01b Baseline')
    legend('First 5 min', 'Next 5 min')
    grid on
end

subplot(4,4,11)
if size(data_01c,1) >= 600
    early_baseline_01c = mean(data_01c(1:300,:), 1, 'omitnan');
    late_baseline_01c = mean(data_01c(301:600,:), 1, 'omitnan');
    plot(final_depth_ft_01c, early_baseline_01c, 'g-', 'LineWidth', 1)
    hold on
    plot(final_depth_ft_01c, late_baseline_01c, 'g--', 'LineWidth', 1)
    xlabel('Depth (ft)')
    ylabel('Baseline Signal')
    title('PT-01c Baseline')
    legend('First 5 min', 'Next 5 min')
    grid on
end

% Plot 12: Zone comparison (450-510 ft range)
subplot(4,4,12)
colors = lines(3);
hold on

% PT-01a zone
zone_mask_01a = final_depth_ft_01a >= 450 & final_depth_ft_01a <= 510;
if sum(zone_mask_01a) > 0
    zone_data_01a = data_01a(:, zone_mask_01a);
    zone_mean_01a = mean(zone_data_01a, 2, 'omitnan');
    plot(zone_mean_01a(1:min(500,length(zone_mean_01a))), 'Color', colors(1,:), 'LineWidth', 1)
end

% PT-01b zone
zone_mask_01b = final_depth_ft_01b >= 450 & final_depth_ft_01b <= 510;
if sum(zone_mask_01b) > 0
    zone_data_01b = data_01b(:, zone_mask_01b);
    zone_mean_01b = mean(zone_data_01b, 2, 'omitnan');
    plot(zone_mean_01b(1:min(500,length(zone_mean_01b))), 'Color', colors(2,:), 'LineWidth', 1)
end

% PT-01c zone
zone_mask_01c = final_depth_ft_01c >= 450 & final_depth_ft_01c <= 510;
if sum(zone_mask_01c) > 0
    zone_data_01c = data_01c(:, zone_mask_01c);
    zone_mean_01c = mean(zone_data_01c, 2, 'omitnan');
    plot(zone_mean_01c(1:min(500,length(zone_mean_01c))), 'Color', colors(3,:), 'LineWidth', 1)
end

xlabel('Time Point')
ylabel('Zone Mean Signal')
title('450-510 ft Zone Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c')
grid on

% Plot 13-15: Noise spectrum comparison
subplot(4,4,13)
if length(time_series_01a) > 100
    [pxx_01a, f_01a] = periodogram(time_series_01a(1:min(1000,length(time_series_01a))), [], [], 1);
    plot(f_01a, 10*log10(pxx_01a), 'b-', 'LineWidth', 1)
    xlabel('Frequency (Hz)')
    ylabel('Power Spectral Density (dB/Hz)')
    title('PT-01a Noise Spectrum')
    grid on
end

subplot(4,4,14)
if length(time_series_01b) > 100
    [pxx_01b, f_01b] = periodogram(time_series_01b(1:min(1000,length(time_series_01b))), [], [], 1);
    plot(f_01b, 10*log10(pxx_01b), 'r-', 'LineWidth', 1)
    xlabel('Frequency (Hz)')
    ylabel('Power Spectral Density (dB/Hz)')
    title('PT-01b Noise Spectrum')
    grid on
end

subplot(4,4,15)
if length(time_series_01c) > 100
    [pxx_01c, f_01c] = periodogram(time_series_01c(1:min(1000,length(time_series_01c))), [], [], 1);
    plot(f_01c, 10*log10(pxx_01c), 'g-', 'LineWidth', 1)
    xlabel('Frequency (Hz)')
    ylabel('Power Spectral Density (dB/Hz)')
    title('PT-01c Noise Spectrum')
    grid on
end

% Plot 16: Summary statistics
subplot(4,4,16)
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};
overall_std = [std(data_01a(:), 'omitnan'), std(data_01b(:), 'omitnan'), std(data_01c(:), 'omitnan')];
bar(overall_std)
set(gca, 'XTickLabel', test_names)
ylabel('Overall Standard Deviation')
title('Data Quality Comparison')
grid on

sgtitle('DAS Data Exploration - All Tests Comparison', 'FontSize', 16, 'FontWeight', 'bold');

fprintf('✓ Created exploration plots\n');
fprintf('\n=== EXPLORATION COMPLETE ===\n');
fprintf('Review the plots to identify:\n');
fprintf('  1. Optimal depth ranges for monitoring\n');
fprintf('  2. Baseline stability issues\n');
fprintf('  3. Noise characteristics and sources\n');
fprintf('  4. Channel correlation patterns\n');
fprintf('  5. Temporal and spatial noise patterns\n'); 