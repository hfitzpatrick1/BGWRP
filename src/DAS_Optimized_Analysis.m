%% Optimized DAS Analysis for All Three Tests
% Uses correct depth control parameters from CC scripts
% Implements noise reduction and optimized processing for thesis analysis

clear; clc; close all

%% 1. Setup and Load Data
fprintf('=== OPTIMIZED DAS ANALYSIS FOR THESIS ===\n');

% Get paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load all DAS datasets
pt01a_file = fullfile(data_dir, 'PM07_01a_1Hz.mat');
pt01b_file = fullfile(data_dir, 'PM07_01b_1Hz.mat');
pt01c_file = fullfile(data_dir, 'PM07_01c_1Hz.mat');

load(pt01a_file); data_01a = decdata; clear decdata;
load(pt01b_file); data_01b = decdata; clear decdata;
load(pt01c_file); data_01c = decdata; clear decdata;

fprintf('✓ Loaded all DAS datasets\n');
fprintf('  PT-01a: [%d x %d]\n', size(data_01a));
fprintf('  PT-01b: [%d x %d]\n', size(data_01b));
fprintf('  PT-01c: [%d x %d]\n', size(data_01c));

%% 2. Define Test-Specific Parameters (from CC scripts)
fprintf('\n=== TEST-SPECIFIC PARAMETERS ===\n');

% PT-01a parameters (from PT_01a_CC.m)
pt01a_params = struct();
pt01a_params.C1 = 513;
pt01a_params.BOT = 1324;
pt01a_params.well_depth_ft = 665;
pt01a_params.water_table_depth_ft = 89;
pt01a_params.depth_offset = 5;
pt01a_params.depth_stretch = 1.0;
pt01a_params.pump_zone_top = 450;
pt01a_params.pump_zone_bot = 510;
pt01a_params.start_time = datetime(2023,11,7,16,45,36,'TimeZone','UTC');
pt01a_params.baseline_period = 120; % 2 minutes (shorter due to drift)

% PT-01b parameters (from PT_01b_CC.m)
pt01b_params = struct();
pt01b_params.C1 = 513;
pt01b_params.BOT = 1324;
pt01b_params.well_depth_ft = 665;
pt01b_params.water_table_depth_ft = 89;
pt01b_params.depth_offset = 5;
pt01b_params.depth_stretch = 1.0;
pt01b_params.pump_zone_top = 350;  % Different from extraction well!
pt01b_params.pump_zone_bot = 400;  % Different from extraction well!
pt01b_params.start_time = datetime(2023,10,31,15,29,36,'TimeZone','UTC');
pt01b_params.baseline_period = 180; % 3 minutes (more stable)

% PT-01c parameters (from PT_01c_CC.m)
pt01c_params = struct();
pt01c_params.C1 = 110;
pt01c_params.BOT = 920;
pt01c_params.well_depth_ft = 665;
pt01c_params.water_table_depth_ft = 89;
pt01c_params.depth_offset = 5;
pt01c_params.depth_stretch = 1.0;
pt01c_params.pump_zone_top = 260;  % Different from extraction well!
pt01c_params.pump_zone_bot = 310;  % Different from extraction well!
pt01c_params.start_time = datetime(2023,10,24,15,17,36,'TimeZone','UTC');
pt01c_params.baseline_period = 60;  % 1 minute (very short due to drift)

fprintf('✓ Loaded test-specific parameters from CC scripts\n');

%% 3. Optimized Processing Function
function [Tdas, strain_processed, final_depth_ft] = process_das_optimized(data, params, test_name)
    fprintf('\n--- Processing %s ---\n', test_name);
    
    % Depth control with test-specific parameters
    dx_m = 0.25; dx_ft = dx_m*3.28084;
    
    DAS_depth_ft = ((0:size(data,2)-1).*dx_m)*3.28084;
    raw_depth_ft = DAS_depth_ft - DAS_depth_ft(params.C1);
    scale = params.well_depth_ft/raw_depth_ft(params.BOT);
    final_depth_ft = raw_depth_ft*scale;
    
    % Apply depth calibration correction
    final_depth_ft = (final_depth_ft + params.depth_offset) * params.depth_stretch;
    
    fprintf('  Depth range: %.1f to %.1f ft\n', min(final_depth_ft), max(final_depth_ft));
    fprintf('  Pump zone: %.0f-%.0f ft\n', params.pump_zone_top, params.pump_zone_bot);
    
    % Time axis
    Tdas = params.start_time + seconds((0:size(data,1)-1));
    
    % Focus on well casing region (adjust ROI based on test)
    if strcmp(test_name, 'PT-01c')
        roi = final_depth_ft >= 0 & final_depth_ft <= params.well_depth_ft;
    else
        roi = final_depth_ft >= 90 & final_depth_ft <= params.well_depth_ft;
    end
    depth_roi = final_depth_ft(roi);
    
    % Enhanced noise reduction for noisy datasets
    if strcmp(test_name, 'PT-01a')
        % Apply low-pass filtering for PT-01a (noisiest dataset)
        fprintf('  Applying low-pass filter (PT-01a noise reduction)\n');
        fs = 1;
        cutoff_freq = 0.05; % Very low cutoff for aggressive noise reduction
        [b, a] = butter(4, cutoff_freq/(fs/2), 'low');
        
        data_filtered = data;
        for ch = 1:size(data, 2)
            data_filtered(:, ch) = filtfilt(b, a, data(:, ch));
        end
        data = data_filtered;
    end
    
    % Temporal common mode removal
    data_cleaned = zeros(size(data));
    for ch = 1:size(data, 2)
        channel_data = data(:, ch);
        temporal_mean = mean(channel_data, 'omitnan');
        data_cleaned(:, ch) = channel_data - temporal_mean;
    end
    
    % Integration
    intdata = cumtrapz(data_cleaned, 1);
    idata_roi = intdata(:, roi);
    
    % Optimized baseline selection based on test characteristics
    baseline_period = params.baseline_period;
    if baseline_period <= size(idata_roi, 1)
        baseline = mean(idata_roi(1:baseline_period,:), 1, 'omitnan');
        fprintf('  Baseline period: %d seconds\n', baseline_period);
    else
        baseline = mean(idata_roi(1:min(60,size(idata_roi,1)),:), 1, 'omitnan');
        fprintf('  Baseline period: %d seconds (adjusted)\n', min(60,size(idata_roi,1)));
    end
    
    % Strain calculation
    dstrain = idata_roi - baseline;
    
    % Extract pumping zone data (monitoring well zones, not extraction well zones)
    pump_zone_mask = depth_roi >= params.pump_zone_top & depth_roi <= params.pump_zone_bot;
    if sum(pump_zone_mask) > 0
        strain_processed = mean(dstrain(:, pump_zone_mask), 2, 'omitnan');
        fprintf('  Pump zone channels: %d\n', sum(pump_zone_mask));
    else
        % Fallback to broader zone if specific zone not found
        fprintf('  ⚠️  Pump zone not found, using broader range\n');
        broader_mask = depth_roi >= (params.pump_zone_top-50) & depth_roi <= (params.pump_zone_bot+50);
        strain_processed = mean(dstrain(:, broader_mask), 2, 'omitnan');
    end
    
    fprintf('  ✓ Processing complete\n');
end

%% 4. Process All Tests with Optimized Parameters
fprintf('\n=== PROCESSING ALL TESTS ===\n');

% Process each test with its specific parameters
[Tdas_01a, strain_01a, depth_01a] = process_das_optimized(data_01a, pt01a_params, 'PT-01a');
[Tdas_01b, strain_01b, depth_01b] = process_das_optimized(data_01b, pt01b_params, 'PT-01b');
[Tdas_01c, strain_01c, depth_01c] = process_das_optimized(data_01c, pt01c_params, 'PT-01c');

%% 5. Quality Assessment
fprintf('\n=== QUALITY ASSESSMENT ===\n');

% Calculate signal quality metrics
function assess_quality(strain, Tdas, test_name)
    fprintf('\n--- %s Quality Assessment ---\n', test_name);
    
    % Signal statistics
    signal_std = std(strain, 'omitnan');
    signal_range = max(strain, [], 'omitnan') - min(strain, [], 'omitnan');
    
    % Baseline stability (first 2 minutes)
    baseline_period = min(120, length(strain));
    baseline_std = std(strain(1:baseline_period), 'omitnan');
    
    % Signal-to-noise ratio (approximate)
    signal_power = var(strain, 'omitnan');
    noise_power = baseline_std^2;
    snr = 10*log10(signal_power/noise_power);
    
    fprintf('  Signal std: %.2e\n', signal_std);
    fprintf('  Signal range: %.2e\n', signal_range);
    fprintf('  Baseline std: %.2e\n', baseline_std);
    fprintf('  SNR (dB): %.1f\n', snr);
    
    % Quality rating
    if snr > 10
        quality = 'Excellent';
    elseif snr > 5
        quality = 'Good';
    elseif snr > 0
        quality = 'Fair';
    else
        quality = 'Poor';
    end
    fprintf('  Quality rating: %s\n', quality);
end

assess_quality(strain_01a, Tdas_01a, 'PT-01a');
assess_quality(strain_01b, Tdas_01b, 'PT-01b');
assess_quality(strain_01c, Tdas_01c, 'PT-01c');

%% 6. Create Optimized Comparison Dashboard
fprintf('\n=== CREATING OPTIMIZED DASHBOARD ===\n');

figure('Position', [100, 100, 1600, 1000]);

% Plot 1: Optimized strain comparison
subplot(3,3,1)
plot(Tdas_01a, strain_01a, 'b-', 'LineWidth', 1)
hold on
plot(Tdas_01b, strain_01b, 'r-', 'LineWidth', 1)
plot(Tdas_01c, strain_01c, 'g-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('Optimized Strain Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c', 'Location', 'best')
grid on

% Plot 2: Individual strain plots
subplot(3,3,2)
plot(Tdas_01a, strain_01a, 'b-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01a Optimized Strain')
grid on

subplot(3,3,3)
plot(Tdas_01b, strain_01b, 'r-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01b Optimized Strain')
grid on

subplot(3,3,4)
plot(Tdas_01c, strain_01c, 'g-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01c Optimized Strain')
grid on

% Plot 5: Depth profiles comparison
subplot(3,3,5)
plot(depth_01a, mean(data_01a, 1, 'omitnan'), 'b-', 'LineWidth', 1)
hold on
plot(depth_01b, mean(data_01b, 1, 'omitnan'), 'r-', 'LineWidth', 1)
plot(depth_01c, mean(data_01c, 1, 'omitnan'), 'g-', 'LineWidth', 1)
xlabel('Depth (ft)')
ylabel('Mean Signal')
title('Depth Profile Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c', 'Location', 'best')
grid on

% Plot 6: Pump zone comparison (monitoring well zones)
subplot(3,3,6)
% PT-01a pump zone
zone_mask_01a = depth_01a >= pt01a_params.pump_zone_top & depth_01a <= pt01a_params.pump_zone_bot;
if sum(zone_mask_01a) > 0
    zone_data_01a = data_01a(:, zone_mask_01a);
    zone_mean_01a = mean(zone_data_01a, 2, 'omitnan');
    plot(zone_mean_01a(1:min(500,length(zone_mean_01a))), 'b-', 'LineWidth', 1)
    hold on
end

% PT-01b pump zone
zone_mask_01b = depth_01b >= pt01b_params.pump_zone_top & depth_01b <= pt01b_params.pump_zone_bot;
if sum(zone_mask_01b) > 0
    zone_data_01b = data_01b(:, zone_mask_01b);
    zone_mean_01b = mean(zone_data_01b, 2, 'omitnan');
    plot(zone_mean_01b(1:min(500,length(zone_mean_01b))), 'r-', 'LineWidth', 1)
end

% PT-01c pump zone
zone_mask_01c = depth_01c >= pt01c_params.pump_zone_top & depth_01c <= pt01c_params.pump_zone_bot;
if sum(zone_mask_01c) > 0
    zone_data_01c = data_01c(:, zone_mask_01c);
    zone_mean_01c = mean(zone_data_01c, 2, 'omitnan');
    plot(zone_mean_01c(1:min(500,length(zone_mean_01c))), 'g-', 'LineWidth', 1)
end

xlabel('Time Point')
ylabel('Zone Mean Signal')
title('Monitoring Well Zone Comparison')
legend('PT-01a', 'PT-01b', 'PT-01c', 'Location', 'best')
grid on

% Plot 7: Signal quality comparison
subplot(3,3,7)
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};
signal_stds = [std(strain_01a, 'omitnan'), std(strain_01b, 'omitnan'), std(strain_01c, 'omitnan')];
bar(signal_stds)
set(gca, 'XTickLabel', test_names)
ylabel('Signal Standard Deviation')
title('Signal Quality Comparison')
grid on

% Plot 8: Baseline stability comparison
subplot(3,3,8)
baseline_stds = [std(strain_01a(1:min(120,length(strain_01a))), 'omitnan'), ...
                 std(strain_01b(1:min(120,length(strain_01b))), 'omitnan'), ...
                 std(strain_01c(1:min(120,length(strain_01c))), 'omitnan')];
bar(baseline_stds)
set(gca, 'XTickLabel', test_names)
ylabel('Baseline Standard Deviation')
title('Baseline Stability Comparison')
grid on

% Plot 9: Summary statistics
subplot(3,3,9)
% Create summary table
test_data = {
    'PT-01a', pt01a_params.pump_zone_top, pt01a_params.pump_zone_bot, pt01a_params.baseline_period, std(strain_01a, 'omitnan');
    'PT-01b', pt01b_params.pump_zone_top, pt01b_params.pump_zone_bot, pt01b_params.baseline_period, std(strain_01b, 'omitnan');
    'PT-01c', pt01c_params.pump_zone_top, pt01c_params.pump_zone_bot, pt01c_params.baseline_period, std(strain_01c, 'omitnan')
};

% Display summary
text(0.1, 0.8, 'Test Summary:', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.6, sprintf('PT-01a: Zone %.0f-%.0f ft, Baseline %d s, Std %.2e', ...
    pt01a_params.pump_zone_top, pt01a_params.pump_zone_bot, pt01a_params.baseline_period, std(strain_01a, 'omitnan')), 'FontSize', 10);
text(0.1, 0.4, sprintf('PT-01b: Zone %.0f-%.0f ft, Baseline %d s, Std %.2e', ...
    pt01b_params.pump_zone_top, pt01b_params.pump_zone_bot, pt01b_params.baseline_period, std(strain_01b, 'omitnan')), 'FontSize', 10);
text(0.1, 0.2, sprintf('PT-01c: Zone %.0f-%.0f ft, Baseline %d s, Std %.2e', ...
    pt01c_params.pump_zone_top, pt01c_params.pump_zone_bot, pt01c_params.baseline_period, std(strain_01c, 'omitnan')), 'FontSize', 10);
axis off

sgtitle('Optimized DAS Analysis - All Tests (Thesis Ready)', 'FontSize', 16, 'FontWeight', 'bold');

fprintf('✓ Created optimized comparison dashboard\n');

%% 7. Save Results for Thesis
fprintf('\n=== SAVING RESULTS ===\n');

% Create results structure
results = struct();
results.PT01a = struct('strain', strain_01a, 'time', Tdas_01a, 'depth', depth_01a, 'params', pt01a_params);
results.PT01b = struct('strain', strain_01b, 'time', Tdas_01b, 'depth', depth_01b, 'params', pt01b_params);
results.PT01c = struct('strain', strain_01c, 'time', Tdas_01c, 'depth', depth_01c, 'params', pt01c_params);

% Save to file
save(fullfile(data_dir, 'optimized_das_results.mat'), 'results');
fprintf('✓ Saved optimized results to: optimized_das_results.mat\n');

fprintf('\n=== OPTIMIZATION COMPLETE ===\n');
fprintf('All three tests processed with:\n');
fprintf('  ✓ Correct depth control parameters from CC scripts\n');
fprintf('  ✓ Test-specific noise reduction techniques\n');
fprintf('  ✓ Optimized baseline periods\n');
fprintf('  ✓ Monitoring well zone analysis\n');
fprintf('  ✓ Quality assessment metrics\n');
fprintf('\nResults ready for thesis analysis! 🎓\n'); 