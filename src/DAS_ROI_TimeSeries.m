%% DAS ROI Time Series Analysis
% Creates time series of average DAS strain for Region of Interest (ROI) only
% This reduces noise by excluding channels outside the C1-BOT range

clear; clc; close all

%% Load Original Time Series Data
fprintf('=== DAS ROI TIME SERIES ANALYSIS ===\n');

% Get paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load original 1Hz time series data
fprintf('Loading original 1Hz time series data...\n');
data_01a = load(fullfile(data_dir, 'PM07_01a_1Hz.mat'));
data_01b = load(fullfile(data_dir, 'PM07_01b_1Hz.mat'));
data_01c = load(fullfile(data_dir, 'PM07_01c_1Hz.mat'));

% Extract strain data
strain_full_01a = data_01a.decdata;  % Full channel data
strain_full_01b = data_01b.decdata;
strain_full_01c = data_01c.decdata;

[nt_01a, nc_01a] = size(strain_full_01a);
[nt_01b, nc_01b] = size(strain_full_01b);
[nt_01c, nc_01c] = size(strain_full_01c);

fprintf('Data loaded:\n');
fprintf('  PT-01a: %d time samples x %d channels\n', nt_01a, nc_01a);
fprintf('  PT-01b: %d time samples x %d channels\n', nt_01b, nc_01b);
fprintf('  PT-01c: %d time samples x %d channels\n', nt_01c, nc_01c);

%% Define ROI Channel Ranges
% Based on CC scripts - these are the channels from C1 to BOT
C1_01a = 513; BOT_01a = 1324;
C1_01b = 513; BOT_01b = 1324;
C1_01c = 110; BOT_01c = 920;

fprintf('\nROI Channel Ranges:\n');
fprintf('  PT-01a: Channels %d-%d (%d channels)\n', C1_01a, BOT_01a, BOT_01a-C1_01a+1);
fprintf('  PT-01b: Channels %d-%d (%d channels)\n', C1_01b, BOT_01b, BOT_01b-C1_01b+1);
fprintf('  PT-01c: Channels %d-%d (%d channels)\n', C1_01c, BOT_01c, BOT_01c-C1_01c+1);

%% Extract ROI Data and Calculate 3 Pumping Zone Averages
fprintf('\nExtracting ROI channels and calculating 3 pumping zone averages...\n');

% Extract ROI channels only
roi_strain_rate_01a = strain_full_01a(:, C1_01a:BOT_01a);
roi_strain_rate_01b = strain_full_01b(:, C1_01b:BOT_01b);
roi_strain_rate_01c = strain_full_01c(:, C1_01c:BOT_01c);

% Define pumping zones based on actual well intervals
n_channels_01a = size(roi_strain_rate_01a, 2);
n_channels_01b = size(roi_strain_rate_01b, 2);
n_channels_01c = size(roi_strain_rate_01c, 2);

% Pumping intervals (in feet)
% PT-01a: 260-310 ft
% PT-01b: 350-400 ft  
% PT-01c: 450-510 ft
well_depth_ft = 665;

% Convert depth intervals to channel indices for PT-01a and PT-01b (812 channels)
% PT-01a pumping zone: 260-310 ft
zonec_start_01a = round(260 * n_channels_01a / well_depth_ft);
zonec_end_01a = round(310 * n_channels_01a / well_depth_ft);
zonec_01a = zonec_start_01a:zonec_end_01a;

% PT-01b pumping zone: 350-400 ft
zoneb_start_01b = round(350 * n_channels_01b / well_depth_ft);
zoneb_end_01b = round(400 * n_channels_01b / well_depth_ft);
zoneb_01b = zoneb_start_01b:zoneb_end_01b;

% PT-01c pumping zone: 450-510 ft (811 channels)
zonea_start_01c = round(450 * n_channels_01c / well_depth_ft);
zonea_end_01c = round(510 * n_channels_01c / well_depth_ft);
zonea_01c = zonea_start_01c:zonea_end_01c;

% For comparison, also define the same pumping zones for all tests
% Zone c (260-310 ft) for all tests
zonec_start_all = round(260 * n_channels_01a / well_depth_ft);
zonec_end_all = round(310 * n_channels_01a / well_depth_ft);
zonec_01b = zonec_start_all:zonec_end_all;
zonec_01c_adj = round(260 * n_channels_01c / well_depth_ft):round(310 * n_channels_01c / well_depth_ft);

% Zone b (350-400 ft) for all tests  
zoneb_start_all = round(350 * n_channels_01a / well_depth_ft);
zoneb_end_all = round(400 * n_channels_01a / well_depth_ft);
zoneb_01a = zoneb_start_all:zoneb_end_all;
zoneb_01c_adj = round(350 * n_channels_01c / well_depth_ft):round(400 * n_channels_01c / well_depth_ft);

% Zone a (450-510 ft) for all tests
zonea_start_all = round(450 * n_channels_01a / well_depth_ft);
zonea_end_all = round(510 * n_channels_01a / well_depth_ft);
zonea_01a = zonea_start_all:zonea_end_all;
zonea_01b = zonea_start_all:zonea_end_all;

% Use adjusted zones for PT-01c
zonec_01c = zonec_01c_adj;
zoneb_01c = zoneb_01c_adj;

% Calculate average strain rate for each pumping zone
zonec_strain_rate_01a = mean(roi_strain_rate_01a(:, zonec_01a), 2, 'omitnan');
zoneb_strain_rate_01a = mean(roi_strain_rate_01a(:, zoneb_01a), 2, 'omitnan');
zonea_strain_rate_01a = mean(roi_strain_rate_01a(:, zonea_01a), 2, 'omitnan');

zonec_strain_rate_01b = mean(roi_strain_rate_01b(:, zonec_01b), 2, 'omitnan');
zoneb_strain_rate_01b = mean(roi_strain_rate_01b(:, zoneb_01b), 2, 'omitnan');
zonea_strain_rate_01b = mean(roi_strain_rate_01b(:, zonea_01b), 2, 'omitnan');

zonec_strain_rate_01c = mean(roi_strain_rate_01c(:, zonec_01c), 2, 'omitnan');
zoneb_strain_rate_01c = mean(roi_strain_rate_01c(:, zoneb_01c), 2, 'omitnan');
zonea_strain_rate_01c = mean(roi_strain_rate_01c(:, zonea_01c), 2, 'omitnan');

fprintf('✓ 3 pumping zone strain rates calculated\n');
fprintf('  Zone c (260-310 ft): PT-01a channels %d-%d, PT-01b channels %d-%d, PT-01c channels %d-%d\n', ...
    zonec_01a(1), zonec_01a(end), zonec_01b(1), zonec_01b(end), zonec_01c(1), zonec_01c(end));
fprintf('  Zone b (350-400 ft): PT-01a channels %d-%d, PT-01b channels %d-%d, PT-01c channels %d-%d\n', ...
    zoneb_01a(1), zoneb_01a(end), zoneb_01b(1), zoneb_01b(end), zoneb_01c(1), zoneb_01c(end));
fprintf('  Zone a (450-510 ft): PT-01a channels %d-%d, PT-01b channels %d-%d, PT-01c channels %d-%d\n', ...
    zonea_01a(1), zonea_01a(end), zonea_01b(1), zonea_01b(end), zonea_01c(1), zonea_01c(end));

% INTEGRATE strain rate to get strain for each zone
fprintf('Integrating strain rate to strain for each zone...\n');
dt = 1; % 1 second sampling interval for 1Hz data

% PT-01a zones
zonec_strain_01a = cumsum(zonec_strain_rate_01a) * dt - zonec_strain_rate_01a(1)*dt;
zoneb_strain_01a = cumsum(zoneb_strain_rate_01a) * dt - zoneb_strain_rate_01a(1)*dt;
zonea_strain_01a = cumsum(zonea_strain_rate_01a) * dt - zonea_strain_rate_01a(1)*dt;

% PT-01b zones
zonec_strain_01b = cumsum(zonec_strain_rate_01b) * dt - zonec_strain_rate_01b(1)*dt;
zoneb_strain_01b = cumsum(zoneb_strain_rate_01b) * dt - zoneb_strain_rate_01b(1)*dt;
zonea_strain_01b = cumsum(zonea_strain_rate_01b) * dt - zonea_strain_rate_01b(1)*dt;

% PT-01c zones
zonec_strain_01c = cumsum(zonec_strain_rate_01c) * dt - zonec_strain_rate_01c(1)*dt;
zoneb_strain_01c = cumsum(zoneb_strain_rate_01c) * dt - zoneb_strain_rate_01c(1)*dt;
zonea_strain_01c = cumsum(zonea_strain_rate_01c) * dt - zonea_strain_rate_01c(1)*dt;

% Apply low-pass filter to smooth the integrated strain
fprintf('Applying low-pass filter to smooth strain for each zone...\n');
fc = 1/15; % Cutoff frequency (1/15 Hz = 15 second period) - light noise removal
fs = 1;    % Sampling frequency (1 Hz)

% Design Butterworth low-pass filter
[b, a] = butter(2, fc/(fs/2), 'low');

% Apply filter to all zones
zonec_strain_01a = filtfilt(b, a, zonec_strain_01a);
zoneb_strain_01a = filtfilt(b, a, zoneb_strain_01a);
zonea_strain_01a = filtfilt(b, a, zonea_strain_01a);

zonec_strain_01b = filtfilt(b, a, zonec_strain_01b);
zoneb_strain_01b = filtfilt(b, a, zoneb_strain_01b);
zonea_strain_01b = filtfilt(b, a, zonea_strain_01b);

zonec_strain_01c = filtfilt(b, a, zonec_strain_01c);
zoneb_strain_01c = filtfilt(b, a, zoneb_strain_01c);
zonea_strain_01c = filtfilt(b, a, zonea_strain_01c);

fprintf('✓ 3-zone strain calculated\n');
fprintf('  PT-01a: %d time points\n', length(zonec_strain_01a));
fprintf('    Zone c (Top): [%.1f to %.1f] nε\n', min(zonec_strain_01a), max(zonec_strain_01a));
fprintf('    Zone b (Mid): [%.1f to %.1f] nε\n', min(zoneb_strain_01a), max(zoneb_strain_01a));
fprintf('    Zone a (Bot): [%.1f to %.1f] nε\n', min(zonea_strain_01a), max(zonea_strain_01a));
fprintf('  PT-01b: %d time points\n', length(zonec_strain_01b));
fprintf('    Zone c (Top): [%.1f to %.1f] nε\n', min(zonec_strain_01b), max(zonec_strain_01b));
fprintf('    Zone b (Mid): [%.1f to %.1f] nε\n', min(zoneb_strain_01b), max(zoneb_strain_01b));
fprintf('    Zone a (Bot): [%.1f to %.1f] nε\n', min(zonea_strain_01b), max(zonea_strain_01b));
fprintf('  PT-01c: %d time points\n', length(zonec_strain_01c));
fprintf('    Zone c (Top): [%.1f to %.1f] nε\n', min(zonec_strain_01c), max(zonec_strain_01c));
fprintf('    Zone b (Mid): [%.1f to %.1f] nε\n', min(zoneb_strain_01c), max(zoneb_strain_01c));
fprintf('    Zone a (Bot): [%.1f to %.1f] nε\n', min(zonea_strain_01c), max(zonea_strain_01c));

%% Create Time Vectors  
% All DAS data recorded in UTC - use MAT file StartTime values directly
fprintf('\nCreating UTC time vectors from DAS timestamps...\n');

% Actual start times (data-driven analysis for PT-01a)
% PT-01a: Data starts at pump start (16:45 UTC), ends at 22:21 UTC
% This gives 5.6 hours total: 4h pumping + 1.6h recovery, no baseline
start_01a_utc = datetime(2023, 11, 7, 16, 45, 0, 'TimeZone', 'UTC');

% PT-01b: From MAT file StartTime = 20231031_151347.754 (UTC)
start_01b_utc = datetime(2023, 10, 31, 15, 13, 47.754, 'TimeZone', 'UTC');

% PT-01c: From MAT file StartTime = 20231024_150236.338 (UTC)  
start_01c_utc = datetime(2023, 10, 24, 15, 2, 36.338, 'TimeZone', 'UTC');

% Create time vectors in UTC (1Hz = 1 second intervals)
time_01a = start_01a_utc + seconds(0:nt_01a-1);
time_01b = start_01b_utc + seconds(0:nt_01b-1);
time_01c = start_01c_utc + seconds(0:nt_01c-1);

fprintf('Actual time ranges (UTC):\n');
fprintf('  PT-01a: %s to %s\n', char(time_01a(1)), char(time_01a(end)));
fprintf('  PT-01b: %s to %s\n', char(time_01b(1)), char(time_01b(end)));
fprintf('  PT-01c: %s to %s\n', char(time_01c(1)), char(time_01c(end)));

% Calculate and display recording durations
duration_01a = time_01a(end) - time_01a(1);
duration_01b = time_01b(end) - time_01b(1);
duration_01c = time_01c(end) - time_01c(1);

fprintf('\nDAS recording durations:\n');
fprintf('  PT-01a: %s (%.1f hours)\n', char(duration_01a), hours(duration_01a));
fprintf('  PT-01b: %s (%.1f hours)\n', char(duration_01b), hours(duration_01b));
fprintf('  PT-01c: %s (%.1f hours)\n', char(duration_01c), hours(duration_01c));

% Calculate baseline periods
pump_start_01a = datetime(2023,11,7,16,45,0,'TimeZone','UTC');
pump_start_01b = datetime(2023,10,31,15,30,0,'TimeZone','UTC');
pump_start_01c = datetime(2023,10,24,15,18,0,'TimeZone','UTC');

baseline_01a = pump_start_01a - time_01a(1);
baseline_01b = pump_start_01b - time_01b(1);
baseline_01c = pump_start_01c - time_01c(1);

fprintf('\nBaseline periods before pumping:\n');
if minutes(baseline_01a) >= 0
    fprintf('  PT-01a: %s (%.1f minutes) baseline\n', char(baseline_01a), minutes(baseline_01a));
else
    fprintf('  PT-01a: NO BASELINE - data starts at pump start\n');
end
fprintf('  PT-01b: %s (%.1f minutes) baseline ✓\n', char(baseline_01b), minutes(baseline_01b));
fprintf('  PT-01c: %s (%.1f minutes) baseline ✓\n', char(baseline_01c), minutes(baseline_01c));

% Calculate total data points and sampling info
total_samples_01a = length(time_01a);
total_samples_01b = length(time_01b);
total_samples_01c = length(time_01c);

fprintf('\nData acquisition summary:\n');
fprintf('  PT-01a: %d samples at 1 Hz = %.1f hours\n', total_samples_01a, total_samples_01a/3600);
fprintf('  PT-01b: %d samples at 1 Hz = %.1f hours\n', total_samples_01b, total_samples_01b/3600);
fprintf('  PT-01c: %d samples at 1 Hz = %.1f hours\n', total_samples_01c, total_samples_01c/3600);

%% Create Time Series Plots (matching your previous style)
fprintf('Creating ROI time series plots...\n');

figure('Name', 'DAS Pumping Zone Time Series Analysis (UTC)', 'Position', [100, 100, 1400, 1000]);

% PT-01a subplot - 3 pumping zones
subplot(3, 1, 1);
plot(time_01a, zonec_strain_01a, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01a, zoneb_strain_01a, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01a, zonea_strain_01a, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01a
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
            text(pump_times_01a(i), max(zonec_strain_01a)*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01a(i), max(zonec_strain_01a)*0.9, sprintf('%d GPM', pump_rates_01a(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('PT-01a: DAS Pumping Zone Strain vs Time (UTC)');
legend('Location', 'best');
xlim([time_01a(1), time_01a(end)]);

% PT-01b subplot - 3 pumping zones  
subplot(3, 1, 2);
plot(time_01b, zonec_strain_01b, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01b, zoneb_strain_01b, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01b, zonea_strain_01b, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01b
pump_times_01b = [
    datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,31,16,30,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,31,17,30,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,31,18,30,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,31,19,30,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01b = [50, 80, 110, 148, 0];

for i = 1:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01b)
        if pump_rates_01b(i) == 0
            text(pump_times_01b(i), max(zonec_strain_01b)*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01b(i), max(zonec_strain_01b)*0.9, sprintf('%d GPM', pump_rates_01b(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('PT-01b: DAS Pumping Zone Strain vs Time (UTC)');
legend('Location', 'best');
xlim([time_01b(1), time_01b(end)]);

% PT-01c subplot - 3 pumping zones
subplot(3, 1, 3);
plot(time_01c, zonec_strain_01c, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01c, zoneb_strain_01c, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01c, zonea_strain_01c, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01c
pump_times_01c = [
    datetime(2023,10,24,15,18,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,24,16,15,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,24,17,15,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,24,18,15,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,24,19,15,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01c = [50, 80, 110, 148, 0];

for i = 1:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01c)
        if pump_rates_01c(i) == 0
            text(pump_times_01c(i), max(zonec_strain_01c)*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01c(i), max(zonec_strain_01c)*0.9, sprintf('%d GPM', pump_rates_01c(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain (nε)');
title('PT-01c: DAS Pumping Zone Strain vs Time (UTC)');
legend('Location', 'best');
xlim([time_01c(1), time_01c(end)]);

fprintf('✓ Strain time series plots created!\n');

%% Create Filtered Strain Rate Plots
fprintf('Creating filtered strain rate plots...\n');

% Apply filtering to strain rate data for plotting
fprintf('Applying filter to strain rate data for visualization...\n');
fc_rate = 1/10; % Cutoff frequency for strain rate (1/10 Hz = 10 second period) - light noise removal
fs = 1;         % Sampling frequency (1 Hz)

% Design Butterworth low-pass filter for strain rate
[b_rate, a_rate] = butter(2, fc_rate/(fs/2), 'low');

% Apply filter to strain rate data
% PT-01a
zonec_strain_rate_01a_filt = filtfilt(b_rate, a_rate, zonec_strain_rate_01a);
zoneb_strain_rate_01a_filt = filtfilt(b_rate, a_rate, zoneb_strain_rate_01a);
zonea_strain_rate_01a_filt = filtfilt(b_rate, a_rate, zonea_strain_rate_01a);

% PT-01b
zonec_strain_rate_01b_filt = filtfilt(b_rate, a_rate, zonec_strain_rate_01b);
zoneb_strain_rate_01b_filt = filtfilt(b_rate, a_rate, zoneb_strain_rate_01b);
zonea_strain_rate_01b_filt = filtfilt(b_rate, a_rate, zonea_strain_rate_01b);

% PT-01c
zonec_strain_rate_01c_filt = filtfilt(b_rate, a_rate, zonec_strain_rate_01c);
zoneb_strain_rate_01c_filt = filtfilt(b_rate, a_rate, zoneb_strain_rate_01c);
zonea_strain_rate_01c_filt = filtfilt(b_rate, a_rate, zonea_strain_rate_01c);

% Create strain rate plots
figure('Name', 'DAS Filtered Strain Rate Analysis (UTC)', 'Position', [200, 200, 1400, 1000]);

% PT-01a subplot - 3 pumping zones strain rate
subplot(3, 1, 1);
plot(time_01a, zonec_strain_rate_01a_filt, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01a, zoneb_strain_rate_01a_filt, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01a, zonea_strain_rate_01a_filt, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01a strain rate
for i = 1:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01a)
        strain_rate_max = max([max(zonec_strain_rate_01a_filt), max(zoneb_strain_rate_01a_filt), max(zonea_strain_rate_01a_filt)]);
        if pump_rates_01a(i) == 0
            text(pump_times_01a(i), strain_rate_max*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01a(i), strain_rate_max*0.9, sprintf('%d GPM', pump_rates_01a(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain Rate (nε/s)');
title('PT-01a: DAS Filtered Strain Rate vs Time (UTC)');
legend('Location', 'best');
xlim([time_01a(1), time_01a(end)]);

% PT-01b subplot - 3 pumping zones strain rate  
subplot(3, 1, 2);
plot(time_01b, zonec_strain_rate_01b_filt, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01b, zoneb_strain_rate_01b_filt, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01b, zonea_strain_rate_01b_filt, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01b strain rate
for i = 1:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01b)
        strain_rate_max = max([max(zonec_strain_rate_01b_filt), max(zoneb_strain_rate_01b_filt), max(zonea_strain_rate_01b_filt)]);
        if pump_rates_01b(i) == 0
            text(pump_times_01b(i), strain_rate_max*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01b(i), strain_rate_max*0.9, sprintf('%d GPM', pump_rates_01b(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain Rate (nε/s)');
title('PT-01b: DAS Filtered Strain Rate vs Time (UTC)');
legend('Location', 'best');
xlim([time_01b(1), time_01b(end)]);

% PT-01c subplot - 3 pumping zones strain rate
subplot(3, 1, 3);
plot(time_01c, zonec_strain_rate_01c_filt, 'b-', 'LineWidth', 2, 'DisplayName', 'Zone c (260-310 ft)');
hold on;
plot(time_01c, zoneb_strain_rate_01c_filt, 'r-', 'LineWidth', 2, 'DisplayName', 'Zone b (350-400 ft)');
plot(time_01c, zonea_strain_rate_01c_filt, 'g-', 'LineWidth', 2, 'DisplayName', 'Zone a (450-510 ft)');

% Add pump schedule annotations for PT-01c strain rate
for i = 1:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01c)
        strain_rate_max = max([max(zonec_strain_rate_01c_filt), max(zoneb_strain_rate_01c_filt), max(zonea_strain_rate_01c_filt)]);
        if pump_rates_01c(i) == 0
            text(pump_times_01c(i), strain_rate_max*0.9, '0 GPM', ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        else
            text(pump_times_01c(i), strain_rate_max*0.9, sprintf('%d GPM', pump_rates_01c(i)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
                'BackgroundColor', 'white', 'EdgeColor', 'black');
        end
    end
end

grid on;
xlabel('Time (UTC)');
ylabel('DAS Strain Rate (nε/s)');
title('PT-01c: DAS Filtered Strain Rate vs Time (UTC)');
legend('Location', 'best');
xlim([time_01c(1), time_01c(end)]);

fprintf('✓ Filtered strain rate plots created!\n');

%% Save Results
fprintf('\nSaving ROI time series results...\n');

% Create results structure with 3-zone data (strain and filtered strain rate)
roi_timeseries = struct();
roi_timeseries.PT01a = struct('time', time_01a, ...
    'zonec_strain', zonec_strain_01a, 'zoneb_strain', zoneb_strain_01a, 'zonea_strain', zonea_strain_01a, ...
    'zonec_strain_rate_filt', zonec_strain_rate_01a_filt, 'zoneb_strain_rate_filt', zoneb_strain_rate_01a_filt, 'zonea_strain_rate_filt', zonea_strain_rate_01a_filt, ...
    'zonec_channels', zonec_01a, 'zoneb_channels', zoneb_01a, 'zonea_channels', zonea_01a, ...
    'roi_channels', C1_01a:BOT_01a, 'C1', C1_01a, 'BOT', BOT_01a);
roi_timeseries.PT01b = struct('time', time_01b, ...
    'zonec_strain', zonec_strain_01b, 'zoneb_strain', zoneb_strain_01b, 'zonea_strain', zonea_strain_01b, ...
    'zonec_strain_rate_filt', zonec_strain_rate_01b_filt, 'zoneb_strain_rate_filt', zoneb_strain_rate_01b_filt, 'zonea_strain_rate_filt', zonea_strain_rate_01b_filt, ...
    'zonec_channels', zonec_01b, 'zoneb_channels', zoneb_01b, 'zonea_channels', zonea_01b, ...
    'roi_channels', C1_01b:BOT_01b, 'C1', C1_01b, 'BOT', BOT_01b);
roi_timeseries.PT01c = struct('time', time_01c, ...
    'zonec_strain', zonec_strain_01c, 'zoneb_strain', zoneb_strain_01c, 'zonea_strain', zonea_strain_01c, ...
    'zonec_strain_rate_filt', zonec_strain_rate_01c_filt, 'zoneb_strain_rate_filt', zoneb_strain_rate_01c_filt, 'zonea_strain_rate_filt', zonea_strain_rate_01c_filt, ...
    'zonec_channels', zonec_01c, 'zoneb_channels', zoneb_01c, 'zonea_channels', zonea_01c, ...
    'roi_channels', C1_01c:BOT_01c, 'C1', C1_01c, 'BOT', BOT_01c);

% Save to file
save(fullfile(data_dir, 'roi_timeseries_results.mat'), 'roi_timeseries');
fprintf('✓ Saved ROI time series results to: roi_timeseries_results.mat\n');

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('DAS pumping zone time series analysis completed!\n');
fprintf('Key improvements:\n');
fprintf('  • Used only ROI channels (C1 to BOT) to reduce noise\n');
fprintf('  • Defined zones based on actual pumping intervals:\n');
fprintf('    - Zone c: 260-310 ft (PT-01a pumping depth)\n');
fprintf('    - Zone b: 350-400 ft (PT-01b pumping depth)\n');
fprintf('    - Zone a: 450-510 ft (PT-01c pumping depth)\n');
fprintf('  • Created two complementary plots:\n');
fprintf('    - Integrated strain time series (cumulative effect)\n');
fprintf('    - Filtered strain rate time series (instantaneous response)\n');
fprintf('  • Applied light noise filtering: 15s for strain, 10s for strain rate\n');
fprintf('  • Shows both cumulative and real-time strain responses\n');
fprintf('\nResults ready for thesis analysis! 🚀\n');