function process_pm7_with_better_baseline(csv_file, zone_name, pump_start_time)
%PROCESS_PM7_WITH_BETTER_BASELINE Clean transducer data using baseline right before pumping
%
% Inputs:
%   csv_file - Path to CSV file
%   zone_name - Name for plots
%   pump_start_time - datetime when pump started (UTC)
%
% Example:
%   pump_start = datetime(2023,11,7,16,45,0,'TimeZone','UTC');
%   process_pm7_with_better_baseline('E:/...csv', 'PT-01a Z3', pump_start)

fprintf('=== PM7 TRANSDUCER - IMPROVED BASELINE METHOD ===\n');
fprintf('Zone: %s\n', zone_name);
fprintf('Pump start time: %s UTC\n\n', pump_start_time);

%% Load and parse data (same as before)
fid = fopen(csv_file, 'r');
line_count = 0;
while ~feof(fid)
    line = fgetl(fid);
    line_count = line_count + 1;
    if contains(line, 'Date Time') && contains(line, 'Depth')
        break;
    end
end
fclose(fid);

opts = detectImportOptions(csv_file);
opts.DataLines = [line_count+1, inf];
opts.VariableNames = {'DateTime', 'Pressure_psi', 'Temperature_C', 'Depth_ft'};
data_table = readtable(csv_file, opts);

% Parse timestamps
timestamps_local = datetime(data_table.DateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
timestamps_local.TimeZone = 'America/Los_Angeles';
timestamps = timestamps_local;
timestamps.TimeZone = 'UTC';

pressure_raw = data_table.Pressure_psi;
temperature = data_table.Temperature_C;
depth_ft_raw = data_table.Depth_ft;

fprintf('Data loaded: %d points\n', length(timestamps));
fprintf('Time range: %s to %s UTC\n\n', timestamps(1), timestamps(end));

%% Clean data (remove outliers)
window_size = 50;
moving_median = movmedian(pressure_raw, window_size, 'omitnan');
moving_mad = movmad(pressure_raw, window_size, 'omitnan');
outliers = abs(pressure_raw - moving_median) > 3 * moving_mad;

pressure_cleaned = pressure_raw;
depth_cleaned = depth_ft_raw;
pressure_cleaned(outliers) = NaN;
depth_cleaned(outliers) = NaN;

pressure_cleaned = fillmissing(pressure_cleaned, 'linear', 'MaxGap', 5);
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 5);

fprintf('Removed %d outliers\n', sum(outliers));

%% Smooth data
smooth_window = 21;
pressure_smoothed = movmean(pressure_cleaned, smooth_window, 'omitnan');
depth_smoothed = movmean(depth_cleaned, smooth_window, 'omitnan');

pressure_final = sgolayfilt(pressure_smoothed, 3, 21);
depth_final = sgolayfilt(depth_smoothed, 3, 21);

%% IMPROVED BASELINE: Use 10 minutes right before pump start
baseline_start = pump_start_time - minutes(10);
baseline_end = pump_start_time - minutes(0.5);  % 30 sec before pump on

baseline_mask = timestamps >= baseline_start & timestamps <= baseline_end;

if sum(baseline_mask) < 10
    warning('Not enough baseline points, using first 60 points instead');
    baseline_depth_ft = mean(depth_final(1:60), 'omitnan');
    baseline_pressure_psi = mean(pressure_final(1:60), 'omitnan');
else
    baseline_depth_ft = mean(depth_final(baseline_mask), 'omitnan');
    baseline_pressure_psi = mean(pressure_final(baseline_mask), 'omitnan');
    fprintf('Baseline period: %s to %s (%d points)\n', ...
        timestamps(find(baseline_mask,1)), timestamps(find(baseline_mask,1,'last')), sum(baseline_mask));
end

fprintf('Baseline depth: %.3f ft\n', baseline_depth_ft);
fprintf('Baseline pressure: %.3f psi\n\n', baseline_pressure_psi);

%% Calculate drawdown relative to improved baseline
drawdown_ft = depth_final - baseline_depth_ft;

% Calculate drawdown rate
dt_seconds = seconds(diff(timestamps));
drawdown_rate_ft_s = [0; diff(drawdown_ft) ./ dt_seconds];
drawdown_rate_smoothed = movmean(drawdown_rate_ft_s, smooth_window, 'omitnan');

%% Create diagnostic plots
figure('Name', sprintf('%s - Improved Baseline', zone_name), 'Position', [100, 100, 1600, 1000]);

% Plot 1: Raw vs cleaned pressure
subplot(5,1,1);
plot(timestamps, pressure_raw, 'b-', 'LineWidth', 0.5, 'DisplayName', 'Raw');
hold on;
plot(timestamps, pressure_final, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
xline(pump_start_time, 'k--', 'Pump ON', 'LineWidth', 2);
xline(baseline_start, 'g--', 'Baseline Start', 'LineWidth', 1);
ylabel('Pressure (psi)');
title(sprintf('%s: Pressure Data', zone_name));
legend('Location', 'best');
grid on;

% Plot 2: Temperature (drift indicator)
subplot(5,1,2);
plot(timestamps, temperature, 'r-', 'LineWidth', 1);
xline(pump_start_time, 'k--', 'Pump ON', 'LineWidth', 2);
ylabel('Temperature (°C)');
title('Temperature (indicates thermal drift)');
grid on;

% Plot 3: Drawdown with pump schedule
subplot(5,1,3);
plot(timestamps, drawdown_ft, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);

% Mark pump schedule for PT-01a
pump_times = [
    pump_start_time;                  % 16:45 - Pump ON (50 GPM)
    pump_start_time + hours(1);       % 17:45 - 80 GPM
    pump_start_time + hours(2);       % 18:45 - 110 GPM  
    pump_start_time + hours(3);       % 19:45 - 150 GPM
    pump_start_time + hours(4);       % 20:45 - Pump OFF
];

for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1.5);
end

ylabel('Drawdown (ft)');
title('Drawdown Time Series (positive = water level decline)');
grid on;
valid_times = timestamps(~isnat(timestamps));
if ~isempty(valid_times)
    xlim([valid_times(1), valid_times(end)]);
end

% Plot 4: Drawdown rate
subplot(5,1,4);
plot(timestamps, drawdown_rate_smoothed, 'g-', 'LineWidth', 1.5);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1.5);
end
ylabel('Drawdown Rate (ft/s)');
title('Drawdown Rate (for DAS correlation)');
grid on;
if ~isempty(valid_times)
    xlim([valid_times(1), valid_times(end)]);
end

% Plot 5: Pre-test drift analysis
subplot(5,1,5);
pre_test_mask = timestamps < pump_start_time;
plot(timestamps(pre_test_mask), depth_final(pre_test_mask) - baseline_depth_ft, 'r-', 'LineWidth', 1);
hold on;
yline(0, 'k--', 'Expected (static)', 'LineWidth', 1.5);
xline(baseline_start, 'g--', 'Baseline Window Start', 'LineWidth', 1);
ylabel('Pre-Test Drift (ft)');
xlabel('Time (UTC)');
title('Pre-Test Drift Analysis (should be flat/zero)');
grid on;

%% Export data
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

Date = timestamps;
Drawdownft = drawdown_ft;
Pressurepsi = pressure_final;
Depthft = baseline_depth_ft;
DrawdownRate_ft_s = drawdown_rate_smoothed;
Temperature_C = temperature;

[~, base_name, ~] = fileparts(csv_file);
mat_output = fullfile(output_dir, sprintf('%s_improved_baseline.mat', base_name));
save(mat_output, 'Date', 'Drawdownft', 'Pressurepsi', 'Depthft', ...
    'DrawdownRate_ft_s', 'Temperature_C', 'baseline_depth_ft', 'baseline_pressure_psi', ...
    'pump_start_time', 'baseline_start', 'baseline_end');

fprintf('\n=== COMPLETE ===\n');
fprintf('Saved to: %s\n', mat_output);

end
