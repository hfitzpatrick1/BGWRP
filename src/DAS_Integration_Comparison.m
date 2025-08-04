
%% DAS Integration Method Comparison
% Compares 4 different approaches to integrate strain rate to strain
% for pump test analysis

clear; clc; close all

%% Load Data
fprintf('=== DAS INTEGRATION METHOD COMPARISON ===\n');
fprintf('Loading 1Hz strain rate data...\n');

% Get paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load 1Hz strain rate data
load(fullfile(data_dir, 'PM07_01a_1Hz.mat')); strain_rate_01a = decdata; nt_01a = size(decdata,2);
load(fullfile(data_dir, 'PM07_01b_1Hz.mat')); strain_rate_01b = decdata; nt_01b = size(decdata,2);
load(fullfile(data_dir, 'PM07_01c_1Hz.mat')); strain_rate_01c = decdata; nt_01c = size(decdata,2);

% Define ROI ranges
C1_01a = 513; BOT_01a = 1324;
C1_01b = 513; BOT_01b = 1324;
C1_01c = 110; BOT_01c = 920;

% Extract ROI strain rates
roi_strain_rate_01a = strain_rate_01a(C1_01a:BOT_01a, :)';
roi_strain_rate_01b = strain_rate_01b(C1_01b:BOT_01b, :)';
roi_strain_rate_01c = strain_rate_01c(C1_01c:BOT_01c, :)';

% Define zones (Zone a, b, c)
% Zone c: 260-310 ft, Zone b: 350-400 ft, Zone a: 450-510 ft
depth_per_channel = 665/1407; % ft per channel for PT-01a/01b
zonec_01a = round(260/depth_per_channel):round(310/depth_per_channel); % 260-310 ft
zoneb_01a = round(350/depth_per_channel):round(400/depth_per_channel); % 350-400 ft  
zonea_01a = round(450/depth_per_channel):round(510/depth_per_channel); % 450-510 ft

% Adjust for ROI offset
zonec_01a = zonec_01a - C1_01a + 1;
zoneb_01a = zoneb_01a - C1_01a + 1;
zonea_01a = zonea_01a - C1_01a + 1;

% Average strain rates for each zone
zonec_strain_rate_01a = mean(roi_strain_rate_01a(:, zonec_01a), 2, 'omitnan');
zoneb_strain_rate_01a = mean(roi_strain_rate_01a(:, zoneb_01a), 2, 'omitnan');
zonea_strain_rate_01a = mean(roi_strain_rate_01a(:, zonea_01a), 2, 'omitnan');

% Time setup
dt = 1; % 1 second sampling
start_01a_utc = datetime(2023, 11, 7, 16, 45, 0, 'TimeZone', 'UTC');
time_01a = start_01a_utc + seconds(0:nt_01a-1);

fprintf('Data loaded. Testing 4 integration methods on PT-01a Zone c...\n\n');

%% Method 1: Remove baseline drift before integration
fprintf('Method 1: Remove baseline drift before integration\n');

% Fit linear trend to strain rate
t_numeric = (1:length(zonec_strain_rate_01a))';
p1 = polyfit(t_numeric, zonec_strain_rate_01a, 1);
baseline_trend = polyval(p1, t_numeric);

% Remove baseline drift
zonec_strain_rate_detrended = zonec_strain_rate_01a - baseline_trend;

% Integrate detrended strain rate
zonec_strain_method1 = cumsum(zonec_strain_rate_detrended) * dt;
zonec_strain_method1 = zonec_strain_method1 - zonec_strain_method1(1); % Start at zero

fprintf('  Baseline drift rate: %.2e nε/s\n', p1(1));
fprintf('  Final strain range: [%.1f to %.1f] nε\n', min(zonec_strain_method1), max(zonec_strain_method1));

%% Method 2: Apply high-pass filtering to remove DC components
fprintf('\nMethod 2: Apply high-pass filtering before integration\n');

% Apply high-pass filter to remove DC drift
fs = 1; % 1 Hz
fc_high = 1/3600; % 1-hour cutoff (remove very slow drifts)
[b_hp, a_hp] = butter(2, fc_high/(fs/2), 'high');
zonec_strain_rate_filtered = filtfilt(b_hp, a_hp, zonec_strain_rate_01a);

% Integrate filtered strain rate
zonec_strain_method2 = cumsum(zonec_strain_rate_filtered) * dt;
zonec_strain_method2 = zonec_strain_method2 - zonec_strain_method2(1); % Start at zero

fprintf('  High-pass cutoff: %.1e Hz (%.1f hour period)\n', fc_high, 1/fc_high/3600);
fprintf('  Final strain range: [%.1f to %.1f] nε\n', min(zonec_strain_method2), max(zonec_strain_method2));

%% Method 3: Use baseline-corrected integration (reference periods)
fprintf('\nMethod 3: Baseline-corrected integration using reference periods\n');

% Define baseline and recovery periods
baseline_end = min(600, length(zonec_strain_rate_01a)); % First 10 minutes or all data
recovery_duration = min(1800, length(zonec_strain_rate_01a)); % Last 30 minutes or all data  
recovery_start = max(1, length(zonec_strain_rate_01a) - recovery_duration + 1);

% Calculate baseline and recovery strain rates
baseline_rate = mean(zonec_strain_rate_01a(1:baseline_end), 'omitnan');
recovery_rate = mean(zonec_strain_rate_01a(recovery_start:end), 'omitnan');

fprintf('  Baseline strain rate: %.2e nε/s\n', baseline_rate);
fprintf('  Recovery strain rate: %.2e nε/s\n', recovery_rate);

% Subtract baseline from strain rate, then integrate
zonec_strain_rate_corrected = zonec_strain_rate_01a - baseline_rate;
zonec_strain_method3 = cumsum(zonec_strain_rate_corrected) * dt;

% Apply final baseline correction to start at zero
zonec_strain_method3 = zonec_strain_method3 - zonec_strain_method3(1);

fprintf('  Final strain range: [%.1f to %.1f] nε\n', min(zonec_strain_method3), max(zonec_strain_method3));

%% Method 4: Standard integration with post-processing baseline subtraction
fprintf('\nMethod 4: Standard integration + post-processing baseline correction\n');

% Standard integration
zonec_strain_method4 = cumsum(zonec_strain_rate_01a) * dt;

% Post-processing: fit polynomial to entire signal and subtract
t_numeric = (1:length(zonec_strain_method4))';
p4 = polyfit(t_numeric, zonec_strain_method4, 2); % Quadratic fit
background_trend = polyval(p4, t_numeric);

% Remove background trend
zonec_strain_method4 = zonec_strain_method4 - background_trend;

% Center around zero at start
zonec_strain_method4 = zonec_strain_method4 - zonec_strain_method4(1);

fprintf('  Applied quadratic detrending\n');
fprintf('  Final strain range: [%.1f to %.1f] nε\n', min(zonec_strain_method4), max(zonec_strain_method4));

%% Create Comparison Plots
fprintf('\nCreating comparison plots...\n');

figure('Position', [50, 50, 1400, 1000]);

% Plot 1: All 4 methods overlaid
subplot(2,2,1)
plot(time_01a, zonec_strain_method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01a, zonec_strain_method2, 'r-', 'LineWidth', 2, 'DisplayName', 'Method 2: High-pass filter');
plot(time_01a, zonec_strain_method3, 'g-', 'LineWidth', 2, 'DisplayName', 'Method 3: Baseline correct');
plot(time_01a, zonec_strain_method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');

% Add pump schedule annotations
pump_times_01a = [
    datetime(2023,11,7,16,45,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,11,7,17,47,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,11,7,18,45,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,11,7,19,45,0,'TimeZone','UTC');  % 150 GPM
    datetime(2023,11,7,20,45,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01a = [50, 80, 110, 150, 0];

for i = 1:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01a)
        if pump_rates_01a(i) == 0
            text(pump_times_01a(i), min(zonec_strain_method1)*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
        else
            text(pump_times_01a(i), max(zonec_strain_method1)*0.9, sprintf('%d GPM', pump_rates_01a(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
        end
    end
end

xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('PT-01a Zone c: All 4 Integration Methods');
legend('Location', 'best');
grid on;

% Plot 2: Method 1 - Detrend first
subplot(2,2,2)
plot(time_01a, zonec_strain_method1, 'b-', 'LineWidth', 2);
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('Method 1: Remove baseline drift before integration');
grid on;

% Plot 3: Method 2 - High-pass filter
subplot(2,2,3)
plot(time_01a, zonec_strain_method2, 'r-', 'LineWidth', 2);
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('Method 2: High-pass filter before integration');
grid on;

% Plot 4: Method 3 - Baseline correct
subplot(2,2,4)
plot(time_01a, zonec_strain_method3, 'g-', 'LineWidth', 2);
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('Method 3: Baseline-corrected integration');
grid on;

sgtitle('DAS Strain Integration Method Comparison - PT-01a Zone c (260-310 ft)', 'FontSize', 16, 'FontWeight', 'bold');

% Second figure showing Method 4
figure('Position', [100, 100, 800, 600]);
plot(time_01a, zonec_strain_method4, 'm-', 'LineWidth', 2);

% Add pump annotations
for i = 1:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01a)
        if pump_rates_01a(i) == 0
            text(pump_times_01a(i), min(zonec_strain_method4)*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        else
            text(pump_times_01a(i), max(zonec_strain_method4)*0.9, sprintf('%d GPM', pump_rates_01a(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end
end

xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('Method 4: Standard integration + post-processing baseline correction');
grid on;

%% Summary Report
fprintf('\n=== INTEGRATION METHOD COMPARISON SUMMARY ===\n');
fprintf('Method 1 (Detrend first):\n');
fprintf('  Range: [%.1f to %.1f] nε\n', min(zonec_strain_method1), max(zonec_strain_method1));
fprintf('  Recovery: %.1f nε (final - minimum)\n', zonec_strain_method1(end) - min(zonec_strain_method1));

fprintf('\nMethod 2 (High-pass filter):\n');
fprintf('  Range: [%.1f to %.1f] nε\n', min(zonec_strain_method2), max(zonec_strain_method2));
fprintf('  Recovery: %.1f nε (final - minimum)\n', zonec_strain_method2(end) - min(zonec_strain_method2));

fprintf('\nMethod 3 (Baseline correct):\n');
fprintf('  Range: [%.1f to %.1f] nε\n', min(zonec_strain_method3), max(zonec_strain_method3));
fprintf('  Recovery: %.1f nε (final - minimum)\n', zonec_strain_method3(end) - min(zonec_strain_method3));

fprintf('\nMethod 4 (Post-process):\n');
fprintf('  Range: [%.1f to %.1f] nε\n', min(zonec_strain_method4), max(zonec_strain_method4));
fprintf('  Recovery: %.1f nε (final - minimum)\n', zonec_strain_method4(end) - min(zonec_strain_method4));

fprintf('\n=== COMPARISON COMPLETE ===\n');
fprintf('Review the plots to choose the best integration method!\n');
fprintf('Look for:\n');
fprintf('  ✓ Starts near zero baseline\n');
fprintf('  ✓ Goes negative during pumping\n');
fprintf('  ✓ Recovers toward baseline when pumps shut off\n');
fprintf('  ✓ Reasonable strain magnitudes (hundreds to thousands of nε)\n');

%% Save results for easy access
integration_comparison = struct();
integration_comparison.time = time_01a;
integration_comparison.method1 = zonec_strain_method1;
integration_comparison.method2 = zonec_strain_method2;
integration_comparison.method3 = zonec_strain_method3;
integration_comparison.method4 = zonec_strain_method4;
integration_comparison.pump_times = pump_times_01a;
integration_comparison.pump_rates = pump_rates_01a;

save(fullfile(data_dir, 'integration_comparison.mat'), 'integration_comparison');
fprintf('\n✓ Saved comparison results to: integration_comparison.mat\n');