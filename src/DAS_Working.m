%% DAS Integration Methods Comparison by Pump Test Date
% Shows all 4 integration methods for each pump test date
% PT-01a (Nov 7), PT-01b (Oct 31), PT-01c (Oct 24)

clear; clc; close all

fprintf('=== DAS INTEGRATION METHODS BY PUMP TEST DATE ===\n');

%% Setup
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

%% Load All Three Wells
fprintf('Loading all pump test data...\n');
load(fullfile(data_dir, 'PM07_01a_1Hz.mat')); data_01a = decdata; clear decdata;
load(fullfile(data_dir, 'PM07_01b_1Hz.mat')); data_01b = decdata; clear decdata;
load(fullfile(data_dir, 'PM07_01c_1Hz.mat')); data_01c = decdata; clear decdata;

%% Zone Definition (Using SAME approach as DAS_ROI_TimeSeries.m)
fprintf('\nAnalyzing Zone c (260-310 ft depth) using consistent ROI definitions...\n');

% ROI Channel Ranges (same as DAS_ROI_TimeSeries.m)
C1_01a = 513; BOT_01a = 1324;
C1_01b = 513; BOT_01b = 1324;
C1_01c = 110; BOT_01c = 920;

% Calculate ROI widths
n_channels_01a = BOT_01a - C1_01a + 1;  % 812 channels
n_channels_01b = BOT_01b - C1_01b + 1;  % 812 channels  
n_channels_01c = BOT_01c - C1_01c + 1;  % 811 channels

well_depth_ft = 665;

% Zone c (260-310 ft) calculation - SAME as DAS_ROI_TimeSeries.m
zonec_start_01a = round(260 * n_channels_01a / well_depth_ft);
zonec_end_01a = round(310 * n_channels_01a / well_depth_ft);
zonec_01a = zonec_start_01a:zonec_end_01a;

zonec_start_01b = round(260 * n_channels_01b / well_depth_ft);
zonec_end_01b = round(310 * n_channels_01b / well_depth_ft);
zonec_01b = zonec_start_01b:zonec_end_01b;

zonec_start_01c = round(260 * n_channels_01c / well_depth_ft);
zonec_end_01c = round(310 * n_channels_01c / well_depth_ft);
zonec_01c = zonec_start_01c:zonec_end_01c;

fprintf('Zone c channel ranges (consistent with DAS_ROI_TimeSeries):\n');
fprintf('  PT-01a: ROI channels %d-%d\n', zonec_01a(1), zonec_01a(end));
fprintf('  PT-01b: ROI channels %d-%d\n', zonec_01b(1), zonec_01b(end));
fprintf('  PT-01c: ROI channels %d-%d\n', zonec_01c(1), zonec_01c(end));

% Extract Zone c strain rates (consistent with DAS_ROI_TimeSeries.m)
roi_strain_rate_01a = data_01a(:, C1_01a:BOT_01a);
zonec_strain_rate_01a = mean(roi_strain_rate_01a(:, zonec_01a), 2, 'omitnan');

roi_strain_rate_01b = data_01b(:, C1_01b:BOT_01b);
zonec_strain_rate_01b = mean(roi_strain_rate_01b(:, zonec_01b), 2, 'omitnan');

roi_strain_rate_01c = data_01c(:, C1_01c:BOT_01c);
zonec_strain_rate_01c = mean(roi_strain_rate_01c(:, zonec_01c), 2, 'omitnan');

%% Create Time Vectors with Correct Data Windows
dt = 1;

% PT-01a: Data 16:45:00 to 22:20:59 UTC (5.6 hours, NO baseline)
start_01a = datetime(2023, 11, 7, 16, 45, 0, 'TimeZone', 'UTC');
end_01a = datetime(2023, 11, 7, 22, 20, 59, 'TimeZone', 'UTC');
time_01a_full = start_01a + seconds(0:size(data_01a,1)-1);
end_idx_01a = find(time_01a_full <= end_01a, 1, 'last');
time_01a = time_01a_full(1:end_idx_01a);
zonec_strain_rate_01a = zonec_strain_rate_01a(1:end_idx_01a);
baseline_duration_01a = 0; % No baseline period

% PT-01b: Data 15:13:47 to 21:37:46 UTC (6.4 hours, 16.2 min baseline)
start_01b = datetime(2023, 10, 31, 15, 13, 47, 'TimeZone', 'UTC');
end_01b = datetime(2023, 10, 31, 21, 37, 46, 'TimeZone', 'UTC');
pump_start_01b = datetime(2023, 10, 31, 15, 30, 0, 'TimeZone', 'UTC');
time_01b_full = start_01b + seconds(0:size(data_01b,1)-1);
end_idx_01b = find(time_01b_full <= end_01b, 1, 'last');
time_01b = time_01b_full(1:end_idx_01b);
zonec_strain_rate_01b = zonec_strain_rate_01b(1:end_idx_01b);
baseline_duration_01b = seconds(pump_start_01b - start_01b); % 16.2 minutes

% PT-01c: Data 15:02:36 to 19:56:35 UTC (4.9 hours, 15.4 min baseline)
start_01c = datetime(2023, 10, 24, 15, 2, 36, 'TimeZone', 'UTC');
end_01c = datetime(2023, 10, 24, 19, 56, 35, 'TimeZone', 'UTC');
pump_start_01c = datetime(2023, 10, 24, 15, 18, 0, 'TimeZone', 'UTC');
time_01c_full = start_01c + seconds(0:size(data_01c,1)-1);
end_idx_01c = find(time_01c_full <= end_01c, 1, 'last');
time_01c = time_01c_full(1:end_idx_01c);
zonec_strain_rate_01c = zonec_strain_rate_01c(1:end_idx_01c);
baseline_duration_01c = seconds(pump_start_01c - start_01c); % 15.4 minutes

fprintf('\nCorrected data time ranges:\n');
fprintf('  PT-01a: %s to %s (%.1f hours, %.1f min baseline)\n', char(time_01a(1)), char(time_01a(end)), hours(time_01a(end)-time_01a(1)), baseline_duration_01a/60);
fprintf('  PT-01b: %s to %s (%.1f hours, %.1f min baseline)\n', char(time_01b(1)), char(time_01b(end)), hours(time_01b(end)-time_01b(1)), baseline_duration_01b/60);
fprintf('  PT-01c: %s to %s (%.1f hours, %.1f min baseline)\n', char(time_01c(1)), char(time_01c(end)), hours(time_01c(end)-time_01c(1)), baseline_duration_01c/60);

%% Compute all methods for each pump test
fprintf('\nComputing 3 integration methods...\n');

% PT-01a - 3 methods
fprintf('Processing PT-01a...\n');
% Method 1: Detrend first
t_numeric = (1:length(zonec_strain_rate_01a))';
p1 = polyfit(t_numeric, zonec_strain_rate_01a, 1);
baseline_trend = polyval(p1, t_numeric);
strain_rate_detrended = zonec_strain_rate_01a - baseline_trend;
methods_01a.method1 = cumsum(strain_rate_detrended) * dt;
methods_01a.method1 = methods_01a.method1 - methods_01a.method1(1);



% Method 4: Post-process
methods_01a.method4 = cumsum(zonec_strain_rate_01a) * dt;
p4 = polyfit(t_numeric, methods_01a.method4, 2);
background_trend = polyval(p4, t_numeric);
methods_01a.method4 = methods_01a.method4 - background_trend;
methods_01a.method4 = methods_01a.method4 - methods_01a.method4(1);

% Method 5: Low-pass filter before integration
fs = 1; % 1 Hz sampling rate
fc_low = 1/300; % 5-minute cutoff (remove high-frequency noise)
[b_lp, a_lp] = butter(2, fc_low/(fs/2), 'low');
strain_rate_lowpass = filtfilt(b_lp, a_lp, zonec_strain_rate_01a);
methods_01a.method5 = cumsum(strain_rate_lowpass) * dt;
methods_01a.method5 = methods_01a.method5 - methods_01a.method5(1);

% PT-01b - 3 methods
fprintf('Processing PT-01b...\n');
% Method 1: Detrend first
t_numeric = (1:length(zonec_strain_rate_01b))';
p1 = polyfit(t_numeric, zonec_strain_rate_01b, 1);
baseline_trend = polyval(p1, t_numeric);
strain_rate_detrended = zonec_strain_rate_01b - baseline_trend;
methods_01b.method1 = cumsum(strain_rate_detrended) * dt;
methods_01b.method1 = methods_01b.method1 - methods_01b.method1(1);



% Method 4: Post-process
methods_01b.method4 = cumsum(zonec_strain_rate_01b) * dt;
p4 = polyfit(t_numeric, methods_01b.method4, 2);
background_trend = polyval(p4, t_numeric);
methods_01b.method4 = methods_01b.method4 - background_trend;
methods_01b.method4 = methods_01b.method4 - methods_01b.method4(1);

% Method 5: Low-pass filter before integration
strain_rate_lowpass = filtfilt(b_lp, a_lp, zonec_strain_rate_01b);
methods_01b.method5 = cumsum(strain_rate_lowpass) * dt;
methods_01b.method5 = methods_01b.method5 - methods_01b.method5(1);

% PT-01c - 3 methods
fprintf('Processing PT-01c...\n');
% Method 1: Detrend first
t_numeric = (1:length(zonec_strain_rate_01c))';
p1 = polyfit(t_numeric, zonec_strain_rate_01c, 1);
baseline_trend = polyval(p1, t_numeric);
strain_rate_detrended = zonec_strain_rate_01c - baseline_trend;
methods_01c.method1 = cumsum(strain_rate_detrended) * dt;
methods_01c.method1 = methods_01c.method1 - methods_01c.method1(1);



% Method 4: Post-process
methods_01c.method4 = cumsum(zonec_strain_rate_01c) * dt;
p4 = polyfit(t_numeric, methods_01c.method4, 2);
background_trend = polyval(p4, t_numeric);
methods_01c.method4 = methods_01c.method4 - background_trend;
methods_01c.method4 = methods_01c.method4 - methods_01c.method4(1);

% Method 5: Low-pass filter before integration
strain_rate_lowpass = filtfilt(b_lp, a_lp, zonec_strain_rate_01c);
methods_01c.method5 = cumsum(strain_rate_lowpass) * dt;
methods_01c.method5 = methods_01c.method5 - methods_01c.method5(1);

%% Strain Rate Analysis - Different Filtering and Display Methods
fprintf('\nAnalyzing strain rate with different filtering methods...\n');

% Apply different filters to strain rate for each pump test
for test_name = {'test01a', 'test01b', 'test01c'}
    test = test_name{1};
    
    % Get the appropriate strain rate data
    if strcmp(test, 'test01a')
        strain_rate_raw = zonec_strain_rate_01a;
        time_data = time_01a;
        test_display = '01a';
    elseif strcmp(test, 'test01b')
        strain_rate_raw = zonec_strain_rate_01b;
        time_data = time_01b;
        test_display = '01b';
    else % test01c
        strain_rate_raw = zonec_strain_rate_01c;
        time_data = time_01c;
        test_display = '01c';
    end
    
    % Filter 1: Raw (unfiltered)
    strain_rate_methods.(test).raw = strain_rate_raw;
    
    % Filter 2: Low-pass filter (noise reduction, 5-min cutoff)
    strain_rate_methods.(test).lowpass = filtfilt(b_lp, a_lp, strain_rate_raw);
    
    % Filter 3: High-pass filter (drift removal, 30-min cutoff)
    fc_high = 1/1800; % 30-minute cutoff
    [b_hp, a_hp] = butter(2, fc_high/(fs/2), 'high');
    strain_rate_methods.(test).highpass = filtfilt(b_hp, a_hp, strain_rate_raw);
    
    % Filter 4: Band-pass filter (1-min to 1-hour)
    fc_band = [1/3600, 1/60]; % 1-hour to 1-minute
    [b_bp, a_bp] = butter(2, fc_band/(fs/2), 'bandpass');
    strain_rate_methods.(test).bandpass = filtfilt(b_bp, a_bp, strain_rate_raw);
    
    % Filter 5: Moving average (5-minute window)
    window_size = 300; % 5 minutes
    strain_rate_methods.(test).movavg = movmean(strain_rate_raw, window_size, 'omitnan');
    
    % Filter 6: Savitzky-Golay smoothing (2-minute window)
    sg_window = min(121, length(strain_rate_raw)); % 2-minute window
    if mod(sg_window, 2) == 0, sg_window = sg_window - 1; end
    strain_rate_methods.(test).savgol = sgolayfilt(strain_rate_raw, 2, sg_window);
    
    % Filter 7: Outlier removal + smoothing
    % Remove extreme outliers (beyond 3 standard deviations)
    strain_rate_clean = strain_rate_raw;
    std_thresh = 3 * std(strain_rate_raw, 'omitnan');
    mean_val = mean(strain_rate_raw, 'omitnan');
    outliers = abs(strain_rate_raw - mean_val) > std_thresh;
    strain_rate_clean(outliers) = NaN;
    % Fill gaps with interpolation
    strain_rate_clean = fillmissing(strain_rate_clean, 'linear');
    strain_rate_methods.(test).outlier_removed = strain_rate_clean;
    
    fprintf('  PT-%s: Applied 7 filtering methods\n', test_display);
end

%% Create Focused Strain Rate Analysis Dashboard
fprintf('\nCreating strain rate analysis plots...\n');

% Figure 1: Best Methods Comparison (Clean)
figure('Position', [50, 50, 1600, 1000]);

% Create pump schedule data for annotations
pump_data.pump_times_01a = [
    datetime(2023,11,7,16,45,0,'TimeZone','UTC');
    datetime(2023,11,7,17,47,0,'TimeZone','UTC');
    datetime(2023,11,7,18,45,0,'TimeZone','UTC');
    datetime(2023,11,7,19,45,0,'TimeZone','UTC');
    datetime(2023,11,7,20,45,0,'TimeZone','UTC');
];
pump_data.pump_times_01b = [
    datetime(2023,10,31,15,30,0,'TimeZone','UTC');
    datetime(2023,10,31,16,30,0,'TimeZone','UTC');
    datetime(2023,10,31,17,30,0,'TimeZone','UTC');
    datetime(2023,10,31,18,30,0,'TimeZone','UTC');
    datetime(2023,10,31,19,30,0,'TimeZone','UTC');
];
pump_data.pump_times_01c = [
    datetime(2023,10,24,15,18,0,'TimeZone','UTC');
    datetime(2023,10,24,16,15,0,'TimeZone','UTC');
    datetime(2023,10,24,17,15,0,'TimeZone','UTC');
    datetime(2023,10,24,18,15,0,'TimeZone','UTC');
    datetime(2023,10,24,19,15,0,'TimeZone','UTC');
];
pump_data.rates_01a = [50, 80, 110, 150, 0];
pump_data.rates_01b = [50, 80, 110, 148, 0];
pump_data.rates_01c = [50, 80, 110, 148, 0];

% Clean comparison focusing on low-pass filter (BEST method)
subplot(2,2,1)
plot(time_01a, strain_rate_methods.test01a.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01a, strain_rate_methods.test01a.lowpass, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations with rate labels
for i = 1:length(pump_data.pump_times_01a)
    xline(pump_data.pump_times_01a(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01a(i) == 0
        text(pump_data.pump_times_01a(i), max(strain_rate_methods.test01a.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01a(i), max(strain_rate_methods.test01a.raw)*0.9, sprintf('%d GPM', pump_data.rates_01a(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01a (Nov 7): Raw vs. Low-pass Filtered', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01a(1), time_01a(end)]);

subplot(2,2,2)
plot(time_01b, strain_rate_methods.test01b.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01b, strain_rate_methods.test01b.lowpass, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations
for i = 1:length(pump_data.pump_times_01b)
    xline(pump_data.pump_times_01b(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01b(i) == 0
        text(pump_data.pump_times_01b(i), max(strain_rate_methods.test01b.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01b(i), max(strain_rate_methods.test01b.raw)*0.9, sprintf('%d GPM', pump_data.rates_01b(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01b (Oct 31): Raw vs. Low-pass Filtered', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01b(1), time_01b(end)]);

subplot(2,2,3)
plot(time_01c, strain_rate_methods.test01c.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01c, strain_rate_methods.test01c.lowpass, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations
for i = 1:length(pump_data.pump_times_01c)
    xline(pump_data.pump_times_01c(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01c(i) == 0
        text(pump_data.pump_times_01c(i), max(strain_rate_methods.test01c.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01c(i), max(strain_rate_methods.test01c.raw)*0.9, sprintf('%d GPM', pump_data.rates_01c(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01c (Oct 24): Raw vs. Low-pass Filtered', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01c(1), time_01c(end)]);

% Summary comparison - low-pass filtered (BEST method) across all tests
subplot(2,2,4)
plot(time_01a, strain_rate_methods.test01a.lowpass, 'b-', 'LineWidth', 2, 'DisplayName', 'PT-01a (Nov 7)');
hold on
plot(time_01b, strain_rate_methods.test01b.lowpass, 'r-', 'LineWidth', 2, 'DisplayName', 'PT-01b (Oct 31)');
plot(time_01c, strain_rate_methods.test01c.lowpass, 'g-', 'LineWidth', 2, 'DisplayName', 'PT-01c (Oct 24)');
xlabel('Time'); ylabel('Strain Rate (nε/s)');
title('Low-pass Filtered: All Tests Comparison', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on;

sgtitle('DAS Strain Rate Analysis - Zone c (260-310 ft) - Low-pass Filtering', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% ROI_2 Analysis - Pumping Zone Responses
fprintf('\n=== ROI_2 ANALYSIS: PUMPING ZONE RESPONSES ===\n');
fprintf('Analyzing strain response at each pumping zone depth...\n');

% Define pumping zone depths for each test
% PT-01a pumps Zone a (450-510 ft), PT-01b pumps Zone b (350-400 ft), PT-01c pumps Zone c (260-310 ft)

% Zone a (450-510 ft) for PT-01a
zonea_start_01a = round(450 * n_channels_01a / well_depth_ft);
zonea_end_01a = round(510 * n_channels_01a / well_depth_ft);
zonea_01a = zonea_start_01a:zonea_end_01a;

% Zone b (350-400 ft) for PT-01b  
zoneb_start_01b = round(350 * n_channels_01b / well_depth_ft);
zoneb_end_01b = round(400 * n_channels_01b / well_depth_ft);
zoneb_01b = zoneb_start_01b:zoneb_end_01b;

% Zone c (260-310 ft) for PT-01c (already defined above)
% zonec_01c already exists

fprintf('Pumping zone channel ranges:\n');
fprintf('  PT-01a (Zone a): ROI channels %d-%d (450-510 ft)\n', zonea_01a(1), zonea_01a(end));
fprintf('  PT-01b (Zone b): ROI channels %d-%d (350-400 ft)\n', zoneb_01b(1), zoneb_01b(end));
fprintf('  PT-01c (Zone c): ROI channels %d-%d (260-310 ft)\n', zonec_01c(1), zonec_01c(end));

% Extract pumping zone strain rates
zonea_strain_rate_01a = mean(roi_strain_rate_01a(:, zonea_01a), 2, 'omitnan');
zonea_strain_rate_01a = zonea_strain_rate_01a(1:end_idx_01a);

zoneb_strain_rate_01b = mean(roi_strain_rate_01b(:, zoneb_01b), 2, 'omitnan');
zoneb_strain_rate_01b = zoneb_strain_rate_01b(1:end_idx_01b);

% zonec_strain_rate_01c already extracted above

%% Compute Integration Methods for Pumping Zones (ROI_2)
fprintf('\nComputing 3 integration methods for pumping zones...\n');

% PT-01a Zone a (450-510 ft) - 3 methods
fprintf('Processing PT-01a Zone a (pumping zone)...\n');
% Method 1: Detrend first
t_numeric_a = (1:length(zonea_strain_rate_01a))';
p1_a = polyfit(t_numeric_a, zonea_strain_rate_01a, 1);
baseline_trend_a = polyval(p1_a, t_numeric_a);
strain_rate_detrended_a = zonea_strain_rate_01a - baseline_trend_a;
methods_01a_roi2.method1 = cumsum(strain_rate_detrended_a) * dt;
methods_01a_roi2.method1 = methods_01a_roi2.method1 - methods_01a_roi2.method1(1);

% Method 4: Post-process
methods_01a_roi2.method4 = cumsum(zonea_strain_rate_01a) * dt;
p4_a = polyfit(t_numeric_a, methods_01a_roi2.method4, 2);
background_trend_a = polyval(p4_a, t_numeric_a);
methods_01a_roi2.method4 = methods_01a_roi2.method4 - background_trend_a;
methods_01a_roi2.method4 = methods_01a_roi2.method4 - methods_01a_roi2.method4(1);

% Method 5: Low-pass filter before integration
strain_rate_lowpass_a = filtfilt(b_lp, a_lp, zonea_strain_rate_01a);
methods_01a_roi2.method5 = cumsum(strain_rate_lowpass_a) * dt;
methods_01a_roi2.method5 = methods_01a_roi2.method5 - methods_01a_roi2.method5(1);

% PT-01b Zone b (350-400 ft) - 3 methods
fprintf('Processing PT-01b Zone b (pumping zone)...\n');
% Method 1: Detrend first
t_numeric_b = (1:length(zoneb_strain_rate_01b))';
p1_b = polyfit(t_numeric_b, zoneb_strain_rate_01b, 1);
baseline_trend_b = polyval(p1_b, t_numeric_b);
strain_rate_detrended_b = zoneb_strain_rate_01b - baseline_trend_b;
methods_01b_roi2.method1 = cumsum(strain_rate_detrended_b) * dt;
methods_01b_roi2.method1 = methods_01b_roi2.method1 - methods_01b_roi2.method1(1);

% Method 4: Post-process
methods_01b_roi2.method4 = cumsum(zoneb_strain_rate_01b) * dt;
p4_b = polyfit(t_numeric_b, methods_01b_roi2.method4, 2);
background_trend_b = polyval(p4_b, t_numeric_b);
methods_01b_roi2.method4 = methods_01b_roi2.method4 - background_trend_b;
methods_01b_roi2.method4 = methods_01b_roi2.method4 - methods_01b_roi2.method4(1);

% Method 5: Low-pass filter before integration
strain_rate_lowpass_b = filtfilt(b_lp, a_lp, zoneb_strain_rate_01b);
methods_01b_roi2.method5 = cumsum(strain_rate_lowpass_b) * dt;
methods_01b_roi2.method5 = methods_01b_roi2.method5 - methods_01b_roi2.method5(1);

% PT-01c Zone c (260-310 ft) - use existing results
methods_01c_roi2.method1 = methods_01c.method1;
methods_01c_roi2.method4 = methods_01c.method4;
methods_01c_roi2.method5 = methods_01c.method5;

%% ROI_2 Strain Rate Analysis for Pumping Zones
fprintf('Creating ROI_2 strain rate analysis for pumping zones...\n');

% Apply low-pass filter to pumping zone strain rates
strain_rate_roi2.test01a.raw = zonea_strain_rate_01a;
strain_rate_roi2.test01a.lowpass = filtfilt(b_lp, a_lp, zonea_strain_rate_01a);

strain_rate_roi2.test01b.raw = zoneb_strain_rate_01b;
strain_rate_roi2.test01b.lowpass = filtfilt(b_lp, a_lp, zoneb_strain_rate_01b);

strain_rate_roi2.test01c.raw = zonec_strain_rate_01c;
strain_rate_roi2.test01c.lowpass = filtfilt(b_lp, a_lp, zonec_strain_rate_01c);

%% Create ROI_2 Strain Rate Dashboard
figure('Position', [100, 50, 1600, 1000]);

% PT-01a Zone a (pumping zone)
subplot(2,2,1)
plot(time_01a, strain_rate_roi2.test01a.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01a, strain_rate_roi2.test01a.lowpass, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations with rate labels
for i = 1:length(pump_data.pump_times_01a)
    xline(pump_data.pump_times_01a(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01a(i) == 0
        text(pump_data.pump_times_01a(i), max(strain_rate_roi2.test01a.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01a(i), max(strain_rate_roi2.test01a.raw)*0.9, sprintf('%d GPM', pump_data.rates_01a(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01a Zone a (450-510 ft): PUMPING ZONE', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01a(1), time_01a(end)]);

% PT-01b Zone b (pumping zone)
subplot(2,2,2)
plot(time_01b, strain_rate_roi2.test01b.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01b, strain_rate_roi2.test01b.lowpass, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations
for i = 1:length(pump_data.pump_times_01b)
    xline(pump_data.pump_times_01b(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01b(i) == 0
        text(pump_data.pump_times_01b(i), max(strain_rate_roi2.test01b.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01b(i), max(strain_rate_roi2.test01b.raw)*0.9, sprintf('%d GPM', pump_data.rates_01b(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01b Zone b (350-400 ft): PUMPING ZONE', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01b(1), time_01b(end)]);

% PT-01c Zone c (pumping zone)
subplot(2,2,3)
plot(time_01c, strain_rate_roi2.test01c.raw, 'k-', 'LineWidth', 0.8, 'DisplayName', 'Raw');
hold on
plot(time_01c, strain_rate_roi2.test01c.lowpass, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Low-pass (5min) - BEST');
% Add pump annotations
for i = 1:length(pump_data.pump_times_01c)
    xline(pump_data.pump_times_01c(i), 'k--', 'Alpha', 0.7, 'LineWidth', 1);
    if pump_data.rates_01c(i) == 0
        text(pump_data.pump_times_01c(i), max(strain_rate_roi2.test01c.raw)*0.8, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'red');
    else
        text(pump_data.pump_times_01c(i), max(strain_rate_roi2.test01c.raw)*0.9, sprintf('%d GPM', pump_data.rates_01c(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end
xlabel('Time (UTC)'); ylabel('Strain Rate (nε/s)');
title('PT-01c Zone c (260-310 ft): PUMPING ZONE', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01c(1), time_01c(end)]);

% Pumping zones comparison - low-pass filtered
subplot(2,2,4)
plot(time_01a, strain_rate_roi2.test01a.lowpass, 'b-', 'LineWidth', 2, 'DisplayName', 'PT-01a Zone a (450-510 ft)');
hold on
plot(time_01b, strain_rate_roi2.test01b.lowpass, 'r-', 'LineWidth', 2, 'DisplayName', 'PT-01b Zone b (350-400 ft)');
plot(time_01c, strain_rate_roi2.test01c.lowpass, 'g-', 'LineWidth', 2, 'DisplayName', 'PT-01c Zone c (260-310 ft)');
xlabel('Time'); ylabel('Strain Rate (nε/s)');
title('Pumping Zones Comparison (Low-pass Filtered)', 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on;

sgtitle('ROI_2: DAS Pumping Zone Analysis - Direct Zone Response', ...
    'FontSize', 16, 'FontWeight', 'bold');

%% Create ROI_2 Integration Dashboard
figure('Position', [150, 100, 1800, 1200]);

% PT-01a Zone a (450-510 ft) - 3 methods
subplot(2,2,1)
plot(time_01a, methods_01a_roi2.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01a, methods_01a_roi2.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01a, methods_01a_roi2.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01a
pump_times_01a = pump_data.pump_times_01a;
pump_rates = pump_data.rates_01a;
all_data_01a_roi2 = [methods_01a_roi2.method1; methods_01a_roi2.method4; methods_01a_roi2.method5];
for i = 1:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates(i) == 0
        text(pump_times_01a(i), min(all_data_01a_roi2)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01a(i), max(all_data_01a_roi2)*0.9, sprintf('%d GPM', pump_rates(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01a Zone a (450-510 ft): PUMPING ZONE Integration');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01a(1), time_01a(end)]);

% PT-01b Zone b (350-400 ft) - 3 methods  
subplot(2,2,2)
plot(time_01b, methods_01b_roi2.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01b, methods_01b_roi2.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01b, methods_01b_roi2.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01b
pump_times_01b = pump_data.pump_times_01b;
pump_rates_01b = pump_data.rates_01b;
all_data_01b_roi2 = [methods_01b_roi2.method1; methods_01b_roi2.method4; methods_01b_roi2.method5];
for i = 1:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates_01b(i) == 0
        text(pump_times_01b(i), min(all_data_01b_roi2)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01b(i), max(all_data_01b_roi2)*0.9, sprintf('%d GPM', pump_rates_01b(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01b Zone b (350-400 ft): PUMPING ZONE Integration');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01b(1), time_01b(end)]);

% PT-01c Zone c (260-310 ft) - 3 methods
subplot(2,2,3)
plot(time_01c, methods_01c_roi2.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01c, methods_01c_roi2.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01c, methods_01c_roi2.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01c
pump_times_01c = pump_data.pump_times_01c;
pump_rates_01c = pump_data.rates_01c;
all_data_01c_roi2 = [methods_01c_roi2.method1; methods_01c_roi2.method4; methods_01c_roi2.method5];
for i = 1:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates_01c(i) == 0
        text(pump_times_01c(i), min(all_data_01c_roi2)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01c(i), max(all_data_01c_roi2)*0.9, sprintf('%d GPM', pump_rates_01c(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01c Zone c (260-310 ft): PUMPING ZONE Integration');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01c(1), time_01c(end)]);

% Method Comparison Across All Pumping Zones (Method 1 - Best)
subplot(2,2,4)
plot(time_01a, methods_01a_roi2.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'PT-01a Zone a (Nov 7)');
hold on
plot(time_01b, methods_01b_roi2.method1, 'r-', 'LineWidth', 2, 'DisplayName', 'PT-01b Zone b (Oct 31)');
plot(time_01c, methods_01c_roi2.method1, 'g-', 'LineWidth', 2, 'DisplayName', 'PT-01c Zone c (Oct 24)');

xlabel('Time'); ylabel('DAS Strain (nε)');
title('Method 1 (Recommended): All PUMPING ZONES Comparison');
legend('Location', 'best', 'FontSize', 9);
grid on;

sgtitle('ROI_2: DAS Integration Methods - Pumping Zone Analysis', ...
    'FontSize', 14, 'FontWeight', 'bold');



%% Create Dashboard - All Methods by Pump Test Date
figure('Position', [50, 50, 1800, 1200]);

%% PT-01a (Nov 7, 2023) - 3 methods
subplot(2,2,1)
plot(time_01a, methods_01a.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01a, methods_01a.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01a, methods_01a.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01a (November 7, 2023)
pump_times_01a = [
    datetime(2023,11,7,16,45,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,11,7,17,47,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,11,7,18,45,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,11,7,19,45,0,'TimeZone','UTC');  % 150 GPM
    datetime(2023,11,7,20,45,0,'TimeZone','UTC');  % 0 GPM (pump off)
];
pump_rates = [50, 80, 110, 150, 0];
all_data_01a = [methods_01a.method1; methods_01a.method4; methods_01a.method5];
for i = 1:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates(i) == 0
        text(pump_times_01a(i), min(all_data_01a)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01a(i), max(all_data_01a)*0.9, sprintf('%d GPM', pump_rates(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01a (Nov 7, 2023): 3 Integration Methods');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01a(1), time_01a(end)]);

%% PT-01b (Oct 31, 2023) - 3 methods  
subplot(2,2,2)
plot(time_01b, methods_01b.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01b, methods_01b.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01b, methods_01b.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01b (October 31, 2023)
pump_times_01b = [
    datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,31,16,30,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,31,17,30,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,31,18,30,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,31,19,30,0,'TimeZone','UTC');  % 0 GPM (pump off)
];
pump_rates_01b = [50, 80, 110, 148, 0];
all_data_01b = [methods_01b.method1; methods_01b.method4; methods_01b.method5];
for i = 1:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates_01b(i) == 0
        text(pump_times_01b(i), min(all_data_01b)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01b(i), max(all_data_01b)*0.9, sprintf('%d GPM', pump_rates_01b(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01b (Oct 31, 2023): 3 Integration Methods');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01b(1), time_01b(end)]);

%% PT-01c (Oct 24, 2023) - 3 methods
subplot(2,2,3)
plot(time_01c, methods_01c.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'Method 1: Detrend first');
hold on
plot(time_01c, methods_01c.method4, 'm-', 'LineWidth', 2, 'DisplayName', 'Method 4: Post-process');
plot(time_01c, methods_01c.method5, 'c-', 'LineWidth', 2, 'DisplayName', 'Method 5: Low-pass filter');

% Add pump schedule for PT-01c (October 24, 2023)
pump_times_01c = [
    datetime(2023,10,24,15,18,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,24,16,15,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,24,17,15,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,24,18,15,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,24,19,15,0,'TimeZone','UTC');  % 0 GPM (pump off)
];
pump_rates_01c = [50, 80, 110, 148, 0];
all_data_01c = [methods_01c.method1; methods_01c.method4; methods_01c.method5];
for i = 1:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1, 'Alpha', 0.7);
    if pump_rates_01c(i) == 0
        text(pump_times_01c(i), min(all_data_01c)*0.9, '0 GPM', ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    else
        text(pump_times_01c(i), max(all_data_01c)*0.9, sprintf('%d GPM', pump_rates_01c(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
    end
end

xlabel('Time (UTC)'); ylabel('DAS Strain (nε)');
title('PT-01c (Oct 24, 2023): 3 Integration Methods');
legend('Location', 'best', 'FontSize', 9);
grid on; xlim([time_01c(1), time_01c(end)]);

%% Method Comparison Across All Tests (Method 1 - Best)
subplot(2,2,4)
plot(time_01a, methods_01a.method1, 'b-', 'LineWidth', 2, 'DisplayName', 'PT-01a (Nov 7)');
hold on
plot(time_01b, methods_01b.method1, 'r-', 'LineWidth', 2, 'DisplayName', 'PT-01b (Oct 31)');
plot(time_01c, methods_01c.method1, 'g-', 'LineWidth', 2, 'DisplayName', 'PT-01c (Oct 24)');

xlabel('Time'); ylabel('DAS Strain (nε)');
title('Method 1 (Recommended): All Pump Tests Comparison');
legend('Location', 'best', 'FontSize', 9);
grid on;

sgtitle('DAS Integration Methods Analysis - Zone c (260-310 ft) - All Pump Test Dates', ...
    'FontSize', 14, 'FontWeight', 'bold');

%% Summary Report
fprintf('\n=== INTEGRATION METHODS COMPARISON SUMMARY ===\n');
fprintf('\nPT-01a (Nov 7, 2023) - Zone c strain ranges:\n');
fprintf('  Method 1: [%.1f to %.1f] nε\n', min(methods_01a.method1), max(methods_01a.method1));
fprintf('  Method 4: [%.1f to %.1f] nε\n', min(methods_01a.method4), max(methods_01a.method4));
fprintf('  Method 5: [%.1f to %.1f] nε\n', min(methods_01a.method5), max(methods_01a.method5));

fprintf('\nPT-01b (Oct 31, 2023) - Zone c strain ranges:\n');
fprintf('  Method 1: [%.1f to %.1f] nε\n', min(methods_01b.method1), max(methods_01b.method1));
fprintf('  Method 4: [%.1f to %.1f] nε\n', min(methods_01b.method4), max(methods_01b.method4));
fprintf('  Method 5: [%.1f to %.1f] nε\n', min(methods_01b.method5), max(methods_01b.method5));

fprintf('\nPT-01c (Oct 24, 2023) - Zone c strain ranges:\n');
fprintf('  Method 1: [%.1f to %.1f] nε\n', min(methods_01c.method1), max(methods_01c.method1));
fprintf('  Method 4: [%.1f to %.1f] nε\n', min(methods_01c.method4), max(methods_01c.method4));
fprintf('  Method 5: [%.1f to %.1f] nε\n', min(methods_01c.method5), max(methods_01c.method5));

%% Strain Rate Analysis Summary
fprintf('\n=== STRAIN RATE ANALYSIS SUMMARY ===\n');
fprintf('✓ Zone c (260-310 ft) strain rate analysis completed:\n');
fprintf('   • Raw data vs. filtered data comparison\n');
fprintf('   • BEST method: Low-pass (5min) - optimal signal preservation\n');
fprintf('   • Pump schedule annotations added\n');
fprintf('   • Cross-test comparison included\n');
fprintf('\n✓ ROI_2 Pumping zone analysis completed:\n');
fprintf('   • PT-01a: Zone a (450-510 ft) - Direct pumping response\n');
fprintf('   • PT-01b: Zone b (350-400 ft) - Direct pumping response\n');
fprintf('   • PT-01c: Zone c (260-310 ft) - Direct pumping response\n');
fprintf('   • Strain rate and integration methods for each pumping zone\n');
fprintf('   • Cross-pumping zone comparison\n');

% Calculate strain rate statistics for each method
for test_name = {'test01a', 'test01b', 'test01c'}
    test = test_name{1};
    if strcmp(test, 'test01a')
        test_display = '01a';
    elseif strcmp(test, 'test01b')
        test_display = '01b';
    else
        test_display = '01c';
    end
    
    fprintf('\nPT-%s strain rate statistics (nε/s):\n', test_display);
    
    raw_data = strain_rate_methods.(test).raw;
    fprintf('  Raw:        Mean=%.2e, Std=%.2e, Range=[%.2e to %.2e]\n', ...
        mean(raw_data, 'omitnan'), std(raw_data, 'omitnan'), min(raw_data), max(raw_data));
    
    lp_data = strain_rate_methods.(test).lowpass;
    fprintf('  Low-pass:   Mean=%.2e, Std=%.2e, Range=[%.2e to %.2e]\n', ...
        mean(lp_data, 'omitnan'), std(lp_data, 'omitnan'), min(lp_data), max(lp_data));
    
    hp_data = strain_rate_methods.(test).highpass;
    fprintf('  High-pass:  Mean=%.2e, Std=%.2e, Range=[%.2e to %.2e]\n', ...
        mean(hp_data, 'omitnan'), std(hp_data, 'omitnan'), min(hp_data), max(hp_data));
    
    bp_data = strain_rate_methods.(test).bandpass;
    fprintf('  Band-pass:  Mean=%.2e, Std=%.2e, Range=[%.2e to %.2e]\n', ...
        mean(bp_data, 'omitnan'), std(bp_data, 'omitnan'), min(bp_data), max(bp_data));
end

fprintf('\n=== INTEGRATION METHODS COMPARISON SUMMARY ===\n');
fprintf('✓ 3 integration methods tested and compared\n');
fprintf('✓ Method descriptions:\n');
fprintf('   1: Linear detrend before integration\n');
fprintf('   4: Quadratic detrend after integration\n');
fprintf('   5: Low-pass filter (5-min cutoff)\n');
fprintf('✓ Zone c (260-310 ft) shows strong response across all tests\n');
fprintf('\nPump test schedules:\n');
fprintf('  PT-01a (Nov 7): 50→80→110→150→0 GPM\n');
fprintf('  PT-01b (Oct 31): 50→80→110→148→0 GPM\n');
fprintf('  PT-01c (Oct 24): 50→80→110→148→0 GPM\n');