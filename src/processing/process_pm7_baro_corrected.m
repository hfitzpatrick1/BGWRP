function process_pm7_baro_corrected(csv_file, zone_name, pump_start_time)
%PROCESS_PM7_BARO_CORRECTED Detrend pre-test + recalculate baseline properly
%
% For small signals, properly detrend drift and establish stable baseline

fprintf('=== BAROMETRIC/DRIFT CORRECTION ===\n');

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

pressure_psi = data_table.Pressure_psi;
temp_f = data_table.Temperature_C;  % Actually Fahrenheit from the file
depth_ft_raw = data_table.Depth_ft;

%% Remove outliers
outliers = isoutlier(depth_ft_raw, 'median') | isoutlier(pressure_psi, 'median');
depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 3);

%% STEP 1: Detrend the PRE-TEST period
pre_test_mask = timestamps < pump_start_time;
pre_test_times = timestamps(pre_test_mask);
pre_test_depth = depth_cleaned(pre_test_mask);

% Fit linear trend to pre-test data
time_numeric = datenum(pre_test_times);
valid_idx = ~isnan(pre_test_depth);
p = polyfit(time_numeric(valid_idx), pre_test_depth(valid_idx), 1);

% Calculate drift for ALL data (not just pre-test)
all_time_numeric = datenum(timestamps);
drift = polyval(p, all_time_numeric);

% Remove drift from entire dataset
depth_detrended = depth_cleaned - drift + mean(pre_test_depth, 'omitnan');

fprintf('Pre-test drift slope: %.6f ft/day\n', p(1)*24*60);
fprintf('Total drift over pre-test: %.4f ft\n', drift(find(pre_test_mask, 1, 'last')) - drift(find(pre_test_mask, 1, 'first')));

%% STEP 2: Light smoothing (3-point only)
depth_smoothed = movmean(depth_detrended, 3, 'omitnan');

%% STEP 3: Establish baseline from STABLE pre-test period
% Use first hour of data (well before pump, after sensor equilibration)
baseline_mask = timestamps >= timestamps(1) + minutes(30) & timestamps < timestamps(1) + hours(1.5);
baseline_depth = mean(depth_smoothed(baseline_mask), 'omitnan');

fprintf('Baseline from first hour: %.4f ft\n', baseline_depth);

%% STEP 4: Calculate drawdown
drawdown_ft = baseline_depth - depth_smoothed;  % Drawdown is POSITIVE when water level drops

fprintf('Max drawdown: %.4f ft (%.3f inches)\n', max(drawdown_ft), max(drawdown_ft)*12);

%% Plot diagnostics
pump_times = [
    pump_start_time;
    pump_start_time + hours(1) + minutes(2);
    pump_start_time + hours(2);
    pump_start_time + hours(3);
    pump_start_time + hours(4);
];
rates = [50, 80, 110, 150, 0];

figure('Position', [50, 50, 1800, 1000]);

% Raw vs Detrended
subplot(3,2,1);
plot(timestamps, depth_cleaned, 'r-', 'LineWidth', 1, 'DisplayName', 'Raw');
hold on;
plot(timestamps, depth_detrended, 'b-', 'LineWidth', 1, 'DisplayName', 'Detrended');
plot(timestamps, drift - drift(1) + depth_cleaned(1), 'k--', 'LineWidth', 1.5, 'DisplayName', 'Drift Trend');
xline(pump_start_time, 'g--', 'Pump Start', 'LineWidth', 2);
ylabel('Depth (ft)');
title('Raw vs Detrended Depth');
legend('Location', 'best');
grid on;

% Pre-test zoom
subplot(3,2,2);
plot(timestamps(pre_test_mask), depth_cleaned(pre_test_mask), 'r-', 'DisplayName', 'Raw');
hold on;
plot(timestamps(pre_test_mask), depth_detrended(pre_test_mask), 'b-', 'DisplayName', 'Detrended');
yline(baseline_depth, 'k--', 'Baseline', 'LineWidth', 2);
ylabel('Depth (ft)');
title('Pre-Test Period Detail');
legend('Location', 'best');
grid on;

% Temperature (can cause drift)
subplot(3,2,3);
plot(timestamps, temp_f, 'k-', 'LineWidth', 1);
xline(pump_start_time, 'g--', 'Pump Start', 'LineWidth', 2);
ylabel('Temperature (°F)');
title('Temperature (sensor thermal equilibration)');
grid on;

% Pressure
subplot(3,2,4);
plot(timestamps, pressure_psi, 'b-', 'LineWidth', 1);
xline(pump_start_time, 'g--', 'Pump Start', 'LineWidth', 2);
ylabel('Pressure (psi)');
title('Gauge Pressure');
grid on;

% Full drawdown time series
subplot(3,2,5);
plot(timestamps, drawdown_ft, 'b-', 'LineWidth', 1.2);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1.5);
    if i <= length(rates) && rates(i) > 0
        text(pump_times(i), max(ylim)*0.95, sprintf('%d GPM', rates(i)), ...
            'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white');
    end
end
ylabel('Drawdown (ft)');
xlabel('Time (UTC)');
title(sprintf('%s - Drawdown (detrended + baro-corrected)', zone_name));
grid on;

% Zoomed pumping period
subplot(3,2,6);
pump_mask = timestamps >= pump_start_time - minutes(10) & timestamps <= pump_start_time + hours(4.5);
plot(timestamps(pump_mask), drawdown_ft(pump_mask), 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'LineWidth', 1);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 2);
    if i <= length(rates) && rates(i) > 0
        text(pump_times(i), max(ylim)*0.9, sprintf('%d GPM', rates(i)), ...
            'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
    end
end
ylabel('Drawdown (ft)');
xlabel('Time (UTC)');
title('ZOOMED: Pumping Period');
grid on;

%% Step check
fprintf('\nStep check at pump rate changes:\n');
for i = 2:length(pump_times)-1
    before_mask = timestamps >= (pump_times(i) - minutes(5)) & timestamps < pump_times(i);
    after_mask = timestamps >= pump_times(i) & timestamps <= (pump_times(i) + minutes(5));
    
    before_avg = mean(drawdown_ft(before_mask), 'omitnan');
    after_avg = mean(drawdown_ft(after_mask), 'omitnan');
    step = after_avg - before_avg;
    
    fprintf('  %d->%d GPM: Step = %.4f ft (%.3f in)\n', ...
        rates(i-1), rates(i), step, step*12);
end

%% Save
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

Date = timestamps;
Drawdownft = drawdown_ft;
Depthft = baseline_depth;
Depth_detrended = depth_detrended;

[~, base_name, ~] = fileparts(csv_file);
save(fullfile(output_dir, sprintf('%s_baro_corrected.mat', base_name)), ...
    'Date', 'Drawdownft', 'Depthft', 'Depth_detrended', 'pump_start_time', ...
    'pressure_psi', 'temp_f', 'baseline_depth');

fprintf('\nSaved to: %s\n', fullfile(output_dir, sprintf('%s_baro_corrected.mat', base_name)));

end
