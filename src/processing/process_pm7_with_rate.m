function process_pm7_with_rate(csv_file, zone_name, pump_start_time, smooth_window)
%PROCESS_PM7_WITH_RATE Process and calculate displacement rate for DAS correlation
%
% Usage:
%   process_pm7_with_rate(csv_file, zone_name, pump_start_time, smooth_window)
%
% smooth_window: smoothing window in points (default: 10 = 50 seconds at 5s sampling)

if nargin < 4
    smooth_window = 10;  % 50 seconds at 5s sampling
end

console_log('=== DISPLACEMENT RATE CALCULATION ===\n');
console_log('Smoothing window: %d points\n', smooth_window);

%% Load data
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

timestamps_local = datetime(data_table.DateTime, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
timestamps_local.TimeZone = 'America/Los_Angeles';
timestamps = timestamps_local;
timestamps.TimeZone = 'UTC';

depth_ft_raw = data_table.Depth_ft;

%% Remove outliers
outliers = isoutlier(depth_ft_raw, 'median', 'ThresholdFactor', 5);
depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 2);

%% Detrend pre-test
pre_test_mask = timestamps < pump_start_time;
pre_test_times = timestamps(pre_test_mask);
pre_test_depth = depth_cleaned(pre_test_mask);

time_numeric = datenum(pre_test_times);
valid_idx = ~isnan(pre_test_depth);
p = polyfit(time_numeric(valid_idx), pre_test_depth(valid_idx), 1);

all_time_numeric = datenum(timestamps);
drift = polyval(p, all_time_numeric);
depth_detrended = depth_cleaned - drift + mean(pre_test_depth, 'omitnan');

%% Smooth for rate calculation
depth_smoothed = movmean(depth_detrended, smooth_window, 'omitnan');

%% Baseline
baseline_mask = timestamps >= timestamps(1) + minutes(30) & timestamps < timestamps(1) + hours(1.5);
baseline_depth = mean(depth_smoothed(baseline_mask), 'omitnan');

%% Calculate displacement (positive = water drops)
displacement_ft = depth_smoothed - baseline_depth;

%% Calculate displacement RATE (ft/sec)
elapsed_time_sec = seconds(timestamps - timestamps(1));
dt = median(diff(elapsed_time_sec));  % Sampling interval

% Central difference for derivative
displacement_rate = gradient(displacement_ft, elapsed_time_sec);

console_log('Sampling interval: %.1f seconds\n', dt);
console_log('Max displacement: %.4f ft\n', max(displacement_ft));
console_log('Max displacement rate: %.6f ft/sec\n', max(abs(displacement_rate)));

%% Calculate pump timing
pump_start_elapsed = seconds(pump_start_time - timestamps(1));
pump_times_elapsed = pump_start_elapsed + [0, 3600, 7200, 10800, 14400];
rates = [50, 80, 110, 150, 0];

%% Plot
figure('Position', [50, 50, 1600, 900]);

% Displacement
subplot(3,1,1);
plot(elapsed_time_sec, displacement_ft, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);
for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= 0 && pump_times_elapsed(i) <= max(elapsed_time_sec)
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 1.5);
    end
end
ylabel('Displacement (ft)');
title(sprintf('%s - Displacement (smoothed %d pts)', zone_name, smooth_window));
grid on;

% Displacement Rate
subplot(3,1,2);
plot(elapsed_time_sec, displacement_rate*1000, 'r-', 'LineWidth', 1);  % Convert to millifoot/sec
hold on;
yline(0, 'k--', 'LineWidth', 1);
for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= 0 && pump_times_elapsed(i) <= max(elapsed_time_sec)
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 1.5);
        if rates(i) > 0
            text(pump_times_elapsed(i), max(ylim)*0.9, sprintf('%d GPM', rates(i)), ...
                'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end
ylabel('Displacement Rate (millifoot/sec)');
title('Displacement Rate - for DAS correlation');
grid on;

% Zoom on pumping
subplot(3,1,3);
zoom_mask = elapsed_time_sec >= (pump_start_elapsed - 600) & elapsed_time_sec <= (pump_start_elapsed + 15000);
plot(elapsed_time_sec(zoom_mask), displacement_rate(zoom_mask)*1000, 'r-', 'LineWidth', 1.2);
hold on;
yline(0, 'k--', 'LineWidth', 1);
for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= (pump_start_elapsed - 600) && pump_times_elapsed(i) <= (pump_start_elapsed + 15000)
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 2);
    end
end
xlabel('Time (seconds)');
ylabel('Displacement Rate (millifoot/sec)');
title('ZOOMED: Displacement Rate - steps should be visible here');
grid on;

%% Save
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

Date = timestamps;
Time_sec = elapsed_time_sec;
Displacement_ft = displacement_ft;
Displacement_rate_ft_per_sec = displacement_rate;

[~, base_name, ~] = fileparts(csv_file);
save(fullfile(output_dir, sprintf('%s_with_rate.mat', base_name)), ...
    'Date', 'Time_sec', 'Displacement_ft', 'Displacement_rate_ft_per_sec', ...
    'pump_start_time', 'baseline_depth', 'smooth_window');

% Export to CSV
export_table = table(Time_sec, Displacement_ft, Displacement_rate_ft_per_sec, ...
    'VariableNames', {'Time_sec', 'Displacement_ft', 'DisplacementRate_ft_per_sec'});
writetable(export_table, fullfile(output_dir, sprintf('%s_DISPLACEMENT_with_RATE.csv', base_name)));

console_log('\nSaved MAT and CSV to: %s\n', output_dir);
console_log('CSV columns: Time_sec, Displacement_ft, DisplacementRate_ft_per_sec\n');

end
