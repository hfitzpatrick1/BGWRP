%% Enhanced DAS Analysis: Strain vs Strain Rate Comparison
% Compares strain and strain rate analysis for all three tests
% Uses optimized parameters and explores which metric is better for pumping detection

clear; clc; close all

%% 1. Setup and Load Data
fprintf('=== ENHANCED DAS ANALYSIS: STRAIN vs STRAIN RATE ===\n');

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

%% 2. Define Test-Specific Parameters (from optimized analysis)
fprintf('\n=== TEST-SPECIFIC PARAMETERS ===\n');

% PT-01a parameters
pt01a_params = struct();
pt01a_params.C1 = 513;
pt01a_params.BOT = 1324;
pt01a_params.well_depth_ft = 665;
pt01a_params.depth_offset = 5;
pt01a_params.depth_stretch = 1.0;
pt01a_params.pump_zone_top = 450;
pt01a_params.pump_zone_bot = 510;
pt01a_params.start_time = datetime(2023,11,7,16,45,36,'TimeZone','UTC');
pt01a_params.baseline_period = 120;

% PT-01b parameters
pt01b_params = struct();
pt01b_params.C1 = 513;
pt01b_params.BOT = 1324;
pt01b_params.well_depth_ft = 665;
pt01b_params.depth_offset = 5;
pt01b_params.depth_stretch = 1.0;
pt01b_params.pump_zone_top = 350;
pt01b_params.pump_zone_bot = 400;
pt01b_params.start_time = datetime(2023,10,31,15,29,36,'TimeZone','UTC');
pt01b_params.baseline_period = 180;

% PT-01c parameters
pt01c_params = struct();
pt01c_params.C1 = 110;
pt01c_params.BOT = 920;
pt01c_params.well_depth_ft = 665;
pt01c_params.depth_offset = 5;
pt01c_params.depth_stretch = 1.0;
pt01c_params.pump_zone_top = 260;
pt01c_params.pump_zone_bot = 310;
pt01c_params.start_time = datetime(2023,10,24,15,17,36,'TimeZone','UTC');
pt01c_params.baseline_period = 60;

fprintf('✓ Loaded test-specific parameters\n');

%% 3. Enhanced Processing Function (Strain + Strain Rate)
function [Tdas, strain_processed, strain_rate_processed, final_depth_ft] = process_enhanced(data, params, test_name)
    fprintf('\n--- Processing %s (Strain + Strain Rate) ---\n', test_name);
    
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
    
    % Focus on well casing region
    if strcmp(test_name, 'PT-01c')
        roi = final_depth_ft >= 0 & final_depth_ft <= params.well_depth_ft;
    else
        roi = final_depth_ft >= 90 & final_depth_ft <= params.well_depth_ft;
    end
    depth_roi = final_depth_ft(roi);
    
    % Enhanced noise reduction for noisy datasets
    if strcmp(test_name, 'PT-01a')
        fprintf('  Applying low-pass filter (PT-01a noise reduction)\n');
        fs = 1;
        cutoff_freq = 0.05;
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
    
    % Extract pumping zone data
    pump_zone_mask = depth_roi >= params.pump_zone_top & depth_roi <= params.pump_zone_bot;
    if sum(pump_zone_mask) > 0
        zone_data = data_cleaned(:, pump_zone_mask);
        fprintf('  Pump zone channels: %d\n', sum(pump_zone_mask));
    else
        fprintf('  ⚠️  Pump zone not found, using broader range\n');
        broader_mask = depth_roi >= (params.pump_zone_top-50) & depth_roi <= (params.pump_zone_bot+50);
        zone_data = data_cleaned(:, broader_mask);
    end
    
    % Calculate mean signal for the zone
    zone_mean = mean(zone_data, 2, 'omitnan');
    
    % === STRAIN ANALYSIS ===
    fprintf('  Processing strain...\n');
    
    % Integration for strain
    strain_integrated = cumtrapz(zone_mean);
    
    % Baseline subtraction for strain
    baseline_period = params.baseline_period;
    if baseline_period <= length(strain_integrated)
        strain_baseline = mean(strain_integrated(1:baseline_period), 'omitnan');
        strain_processed = strain_integrated - strain_baseline;
    else
        strain_baseline = mean(strain_integrated(1:min(60,length(strain_integrated))), 'omitnan');
        strain_processed = strain_integrated - strain_baseline;
    end
    
    % === STRAIN RATE ANALYSIS ===
    fprintf('  Processing strain rate...\n');
    
    % Calculate strain rate (derivative of strain)
    strain_rate_raw = diff(zone_mean);
    
    % Apply smoothing to strain rate (reduce noise)
    window_size = 5; % 5-point moving average
    strain_rate_smoothed = movmean(strain_rate_raw, window_size, 'omitnan');
    
    % Baseline subtraction for strain rate
    if baseline_period <= length(strain_rate_smoothed)
        strain_rate_baseline = mean(strain_rate_smoothed(1:baseline_period), 'omitnan');
        strain_rate_processed = strain_rate_smoothed - strain_rate_baseline;
    else
        strain_rate_baseline = mean(strain_rate_smoothed(1:min(60,length(strain_rate_smoothed))), 'omitnan');
        strain_rate_processed = strain_rate_smoothed - strain_rate_baseline;
    end
    
    % Adjust time axis for strain rate (one point shorter due to diff)
    Tdas_strain_rate = Tdas(1:end-1);
    
    fprintf('  ✓ Strain and strain rate processing complete\n');
end

%% 4. Process All Tests
fprintf('\n=== PROCESSING ALL TESTS ===\n');

% Process each test for both strain and strain rate
[Tdas_01a, strain_01a, strain_rate_01a, depth_01a] = process_enhanced(data_01a, pt01a_params, 'PT-01a');
[Tdas_01b, strain_01b, strain_rate_01b, depth_01b] = process_enhanced(data_01b, pt01b_params, 'PT-01b');
[Tdas_01c, strain_01c, strain_rate_01c, depth_01c] = process_enhanced(data_01c, pt01c_params, 'PT-01c');

%% 5. Quality Assessment for Both Metrics
fprintf('\n=== QUALITY ASSESSMENT (Strain vs Strain Rate) ===\n');

% Function to assess quality for both metrics
function assess_dual_quality(strain, strain_rate, Tdas, test_name)
    fprintf('\n--- %s Quality Assessment ---\n', test_name);
    
    % Strain metrics
    strain_std = std(strain, 'omitnan');
    strain_range = max(strain, [], 'omitnan') - min(strain, [], 'omitnan');
    baseline_period = min(120, length(strain));
    strain_baseline_std = std(strain(1:baseline_period), 'omitnan');
    strain_snr = 10*log10(var(strain, 'omitnan')/strain_baseline_std^2);
    
    % Strain rate metrics
    strain_rate_std = std(strain_rate, 'omitnan');
    strain_rate_range = max(strain_rate, [], 'omitnan') - min(strain_rate, [], 'omitnan');
    baseline_period_rate = min(120, length(strain_rate));
    strain_rate_baseline_std = std(strain_rate(1:baseline_period_rate), 'omitnan');
    strain_rate_snr = 10*log10(var(strain_rate, 'omitnan')/strain_rate_baseline_std^2);
    
    fprintf('  STRAIN:\n');
    fprintf('    Signal std: %.2e\n', strain_std);
    fprintf('    Signal range: %.2e\n', strain_range);
    fprintf('    Baseline std: %.2e\n', strain_baseline_std);
    fprintf('    SNR (dB): %.1f\n', strain_snr);
    
    fprintf('  STRAIN RATE:\n');
    fprintf('    Signal std: %.2e\n', strain_rate_std);
    fprintf('    Signal range: %.2e\n', strain_rate_range);
    fprintf('    Baseline std: %.2e\n', strain_rate_baseline_std);
    fprintf('    SNR (dB): %.1f\n', strain_rate_snr);
    
    % Determine which metric is better
    if strain_snr > strain_rate_snr
        better_metric = 'Strain';
        improvement = strain_snr - strain_rate_snr;
    else
        better_metric = 'Strain Rate';
        improvement = strain_rate_snr - strain_snr;
    end
    fprintf('  BETTER METRIC: %s (%.1f dB improvement)\n', better_metric, improvement);
end

assess_dual_quality(strain_01a, strain_rate_01a, Tdas_01a, 'PT-01a');
assess_dual_quality(strain_01b, strain_rate_01b, Tdas_01b, 'PT-01b');
assess_dual_quality(strain_01c, strain_rate_01c, Tdas_01c, 'PT-01c');

%% 6. Create Comprehensive Comparison Dashboard
fprintf('\n=== CREATING COMPREHENSIVE DASHBOARD ===\n');

figure('Position', [100, 100, 1800, 1200]);

% Plot 1: Strain comparison (all tests)
subplot(4,4,1)
plot(Tdas_01a, strain_01a, 'b-', 'LineWidth', 1)
hold on
plot(Tdas_01b, strain_01b, 'r-', 'LineWidth', 1)
plot(Tdas_01c, strain_01c, 'g-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('Strain Comparison (All Tests)')
legend('PT-01a', 'PT-01b', 'PT-01c', 'Location', 'best')
grid on

% Plot 2: Strain rate comparison (all tests)
subplot(4,4,2)
plot(Tdas_01a(1:end-1), strain_rate_01a, 'b-', 'LineWidth', 1)
hold on
plot(Tdas_01b(1:end-1), strain_rate_01b, 'r-', 'LineWidth', 1)
plot(Tdas_01c(1:end-1), strain_rate_01c, 'g-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain Rate (nε/s)')
title('Strain Rate Comparison (All Tests)')
legend('PT-01a', 'PT-01b', 'PT-01c', 'Location', 'best')
grid on

% Plot 3: PT-01a strain vs strain rate
subplot(4,4,3)
yyaxis left
plot(Tdas_01a, strain_01a, 'b-', 'LineWidth', 1)
ylabel('Strain (nε)')
yyaxis right
plot(Tdas_01a(1:end-1), strain_rate_01a, 'r-', 'LineWidth', 1)
ylabel('Strain Rate (nε/s)')
xlabel('Time')
title('PT-01a: Strain vs Strain Rate')
grid on

% Plot 4: PT-01b strain vs strain rate
subplot(4,4,4)
yyaxis left
plot(Tdas_01b, strain_01b, 'b-', 'LineWidth', 1)
ylabel('Strain (nε)')
yyaxis right
plot(Tdas_01b(1:end-1), strain_rate_01b, 'r-', 'LineWidth', 1)
ylabel('Strain Rate (nε/s)')
xlabel('Time')
title('PT-01b: Strain vs Strain Rate')
grid on

% Plot 5: PT-01c strain vs strain rate
subplot(4,4,5)
yyaxis left
plot(Tdas_01c, strain_01c, 'b-', 'LineWidth', 1)
ylabel('Strain (nε)')
yyaxis right
plot(Tdas_01c(1:end-1), strain_rate_01c, 'r-', 'LineWidth', 1)
ylabel('Strain Rate (nε/s)')
xlabel('Time')
title('PT-01c: Strain vs Strain Rate')
grid on

% Plot 6: Signal quality comparison
subplot(4,4,6)
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};
strain_stds = [std(strain_01a, 'omitnan'), std(strain_01b, 'omitnan'), std(strain_01c, 'omitnan')];
strain_rate_stds = [std(strain_rate_01a, 'omitnan'), std(strain_rate_01b, 'omitnan'), std(strain_rate_01c, 'omitnan')];

x = 1:3;
bar(x, [strain_stds; strain_rate_stds]')
set(gca, 'XTickLabel', test_names)
ylabel('Signal Standard Deviation')
title('Signal Quality Comparison')
legend('Strain', 'Strain Rate', 'Location', 'best')
grid on

% Plot 7: SNR comparison
subplot(4,4,7)
% Calculate SNRs
strain_snrs = [10*log10(var(strain_01a, 'omitnan')/std(strain_01a(1:min(120,length(strain_01a))), 'omitnan')^2), ...
               10*log10(var(strain_01b, 'omitnan')/std(strain_01b(1:min(120,length(strain_01b))), 'omitnan')^2), ...
               10*log10(var(strain_01c, 'omitnan')/std(strain_01c(1:min(120,length(strain_01c))), 'omitnan')^2)];

strain_rate_snrs = [10*log10(var(strain_rate_01a, 'omitnan')/std(strain_rate_01a(1:min(120,length(strain_rate_01a))), 'omitnan')^2), ...
                    10*log10(var(strain_rate_01b, 'omitnan')/std(strain_rate_01b(1:min(120,length(strain_rate_01b))), 'omitnan')^2), ...
                    10*log10(var(strain_rate_01c, 'omitnan')/std(strain_rate_01c(1:min(120,length(strain_rate_01c))), 'omitnan')^2)];

bar(x, [strain_snrs; strain_rate_snrs]')
set(gca, 'XTickLabel', test_names)
ylabel('SNR (dB)')
title('Signal-to-Noise Ratio Comparison')
legend('Strain', 'Strain Rate', 'Location', 'best')
grid on

% Plot 8: Baseline stability comparison
subplot(4,4,8)
strain_baseline_stds = [std(strain_01a(1:min(120,length(strain_01a))), 'omitnan'), ...
                       std(strain_01b(1:min(120,length(strain_01b))), 'omitnan'), ...
                       std(strain_01c(1:min(120,length(strain_01c))), 'omitnan')];

strain_rate_baseline_stds = [std(strain_rate_01a(1:min(120,length(strain_rate_01a))), 'omitnan'), ...
                            std(strain_rate_01b(1:min(120,length(strain_rate_01b))), 'omitnan'), ...
                            std(strain_rate_01c(1:min(120,length(strain_rate_01c))), 'omitnan')];

bar(x, [strain_baseline_stds; strain_rate_baseline_stds]')
set(gca, 'XTickLabel', test_names)
ylabel('Baseline Standard Deviation')
title('Baseline Stability Comparison')
legend('Strain', 'Strain Rate', 'Location', 'best')
grid on

% Plot 9: Detailed PT-01a strain
subplot(4,4,9)
plot(Tdas_01a, strain_01a, 'b-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01a Strain (Detailed)')
grid on

% Plot 10: Detailed PT-01a strain rate
subplot(4,4,10)
plot(Tdas_01a(1:end-1), strain_rate_01a, 'r-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain Rate (nε/s)')
title('PT-01a Strain Rate (Detailed)')
grid on

% Plot 11: Detailed PT-01b strain
subplot(4,4,11)
plot(Tdas_01b, strain_01b, 'b-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01b Strain (Detailed)')
grid on

% Plot 12: Detailed PT-01b strain rate
subplot(4,4,12)
plot(Tdas_01b(1:end-1), strain_rate_01b, 'r-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain Rate (nε/s)')
title('PT-01b Strain Rate (Detailed)')
grid on

% Plot 13: Detailed PT-01c strain
subplot(4,4,13)
plot(Tdas_01c, strain_01c, 'b-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain (nε)')
title('PT-01c Strain (Detailed)')
grid on

% Plot 14: Detailed PT-01c strain rate
subplot(4,4,14)
plot(Tdas_01c(1:end-1), strain_rate_01c, 'r-', 'LineWidth', 1)
xlabel('Time')
ylabel('Strain Rate (nε/s)')
title('PT-01c Strain Rate (Detailed)')
grid on

% Plot 15: Metric comparison summary
subplot(4,4,15)
% Create comparison matrix
comparison_data = [strain_snrs; strain_rate_snrs];
imagesc(comparison_data)
colorbar
set(gca, 'XTickLabel', test_names, 'YTickLabel', {'Strain', 'Strain Rate'})
xlabel('Test')
ylabel('Metric')
title('SNR Comparison Matrix')
colorbar

% Plot 16: Summary statistics
subplot(4,4,16)
% Display summary
text(0.1, 0.9, 'Analysis Summary:', 'FontSize', 12, 'FontWeight', 'bold');
text(0.1, 0.7, 'Strain Rate Advantages:', 'FontSize', 10, 'FontWeight', 'bold');
text(0.1, 0.6, '• Less baseline drift', 'FontSize', 9);
text(0.1, 0.5, '• More sensitive to changes', 'FontSize', 9);
text(0.1, 0.4, '• Better for event detection', 'FontSize', 9);
text(0.1, 0.3, 'Strain Advantages:', 'FontSize', 10, 'FontWeight', 'bold');
text(0.1, 0.2, '• Cumulative effect visible', 'FontSize', 9);
text(0.1, 0.1, '• Better for long-term trends', 'FontSize', 9);
axis off

sgtitle('Enhanced DAS Analysis: Strain vs Strain Rate Comparison', 'FontSize', 16, 'FontWeight', 'bold');

fprintf('✓ Created comprehensive strain vs strain rate dashboard\n');

%% 7. Save Enhanced Results
fprintf('\n=== SAVING ENHANCED RESULTS ===\n');

% Create enhanced results structure
enhanced_results = struct();
enhanced_results.PT01a = struct('strain', strain_01a, 'strain_rate', strain_rate_01a, ...
    'time_strain', Tdas_01a, 'time_strain_rate', Tdas_01a(1:end-1), 'depth', depth_01a, 'params', pt01a_params);
enhanced_results.PT01b = struct('strain', strain_01b, 'strain_rate', strain_rate_01b, ...
    'time_strain', Tdas_01b, 'time_strain_rate', Tdas_01b(1:end-1), 'depth', depth_01b, 'params', pt01b_params);
enhanced_results.PT01c = struct('strain', strain_01c, 'strain_rate', strain_rate_01c, ...
    'time_strain', Tdas_01c, 'time_strain_rate', Tdas_01c(1:end-1), 'depth', depth_01c, 'params', pt01c_params);

% Save to file
save(fullfile(data_dir, 'enhanced_das_results.mat'), 'enhanced_results');
fprintf('✓ Saved enhanced results to: enhanced_das_results.mat\n');

fprintf('\n=== ENHANCED ANALYSIS COMPLETE ===\n');
fprintf('Both strain and strain rate analysis completed!\n');
fprintf('Compare the results to determine which metric is better for:\n');
fprintf('  • Pumping event detection\n');
fprintf('  • Signal-to-noise ratio\n');
fprintf('  • Baseline stability\n');
fprintf('  • Correlation with transducer data\n');
fprintf('\nResults ready for thesis analysis! 🎓\n'); 