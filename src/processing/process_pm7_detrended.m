function process_pm7_detrended(csv_file, zone_name, pump_start_time)
%PROCESS_PM7_DETRENDED Remove pre-test drift to get clean step response
%
% Removes linear drift observed before pumping to reveal true pump response

console_log('=== PM7 TRANSDUCER - DRIFT CORRECTED ===\n');
console_log('Zone: %s\n', zone_name);

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

timestamps_local = datetime(data_table.DateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
timestamps_local.TimeZone = 'America/Los_Angeles';
timestamps = timestamps_local;
timestamps.TimeZone = 'UTC';

pressure_raw = data_table.Pressure_psi;
depth_ft_raw = data_table.Depth_ft;

%% Clean outliers
window_size = 50;
moving_median = movmedian(pressure_raw, window_size, 'omitnan');
moving_mad = movmad(pressure_raw, window_size, 'omitnan');
outliers = abs(pressure_raw - moving_median) > 3 * moving_mad;

depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 5);

%% Smooth - LIGHTER smoothing to preserve steps
depth_smoothed = movmean(depth_cleaned, 5, 'omitnan');  % Reduced from 21 to 5
depth_final = depth_smoothed;  % Skip Savitzky-Golay to preserve steps

%% DRIFT CORRECTION: Remove pre-test trend
pre_test_mask = timestamps < pump_start_time;
pre_test_times = timestamps(pre_test_mask);
pre_test_depth = depth_final(pre_test_mask);

% Fit linear trend to pre-test period
time_numeric = datenum(timestamps);
pre_test_time_numeric = time_numeric(pre_test_mask);

% Remove NaN values for fitting
valid_pre = ~isnan(pre_test_depth);
if sum(valid_pre) > 10
    % Fit linear trend
    p = polyfit(pre_test_time_numeric(valid_pre), pre_test_depth(valid_pre), 1);
    drift_trend = polyval(p, time_numeric);
    
    console_log('Drift correction:\n');
    console_log('  Drift rate: %.6f ft/day\n', p(1) * 24 * 60);  % Convert to ft/day
    console_log('  Total pre-test drift: %.4f ft\n', drift_trend(find(pre_test_mask,1,'last')) - drift_trend(1));
else
    drift_trend = zeros(size(time_numeric));
    console_log('Not enough pre-test data for drift correction\n');
end

% Remove drift trend
depth_detrended = depth_final - (drift_trend - drift_trend(1));

%% Calculate drawdown with better baseline
baseline_start = pump_start_time - minutes(5);
baseline_end = pump_start_time - minutes(0.5);
baseline_mask = timestamps >= baseline_start & timestamps <= baseline_end;

if sum(baseline_mask) > 0
    baseline_depth = mean(depth_detrended(baseline_mask), 'omitnan');
else
    baseline_depth = depth_detrended(find(pre_test_mask,1,'last'));
end

drawdown_ft = depth_detrended - baseline_depth;

console_log('  Baseline depth (detrended): %.3f ft\n\n', baseline_depth);

%% Create comparison plots
valid_times = timestamps(~isnat(timestamps));
pump_times = [
    pump_start_time;
    pump_start_time + hours(1);
    pump_start_time + hours(2);
    pump_start_time + hours(3);
    pump_start_time + hours(4);
];
pump_labels = {'50 GPM', '80 GPM', '110 GPM', '150 GPM', 'Pump OFF'};

figure('Name', sprintf('%s - Drift Corrected', zone_name), 'Position', [100, 100, 1400, 800]);

% Plot 1: Before drift correction
subplot(2,1,1);
plot(timestamps, depth_final - baseline_depth, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1);
    if i < length(pump_times)
        text(pump_times(i), max(ylim)*0.9, pump_labels{i}, 'FontSize', 9, 'BackgroundColor', 'white');
    end
end
ylabel('Drawdown (ft)');
title('BEFORE Drift Correction (notice the ramp up before pump starts)');
grid on;
if ~isempty(valid_times)
    xlim([valid_times(1), valid_times(end)]);
end

% Plot 2: After drift correction  
subplot(2,1,2);
plot(timestamps, drawdown_ft, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1);
    if i < length(pump_times)
        text(pump_times(i), max(ylim)*0.9, pump_labels{i}, 'FontSize', 9, 'BackgroundColor', 'white');
    end
end
ylabel('Drawdown (ft)');
xlabel('Time (UTC)');
title('AFTER Drift Correction (clean step response like your reference)');
grid on;
if ~isempty(valid_times)
    xlim([valid_times(1), valid_times(end)]);
end

%% Export
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

Date = timestamps;
Drawdownft = drawdown_ft;
Depthft = baseline_depth;

[~, base_name, ~] = fileparts(csv_file);
mat_output = fullfile(output_dir, sprintf('%s_detrended.mat', base_name));
save(mat_output, 'Date', 'Drawdownft', 'Depthft', 'pump_start_time');

console_log('=== COMPLETE ===\n');
console_log('Saved: %s\n', mat_output);
console_log('\nNow you should see clear step responses at each pump rate change!\n');

end
