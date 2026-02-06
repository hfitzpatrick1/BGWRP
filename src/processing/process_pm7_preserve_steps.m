function process_pm7_preserve_steps(csv_file, zone_name, pump_start_time)
%PROCESS_PM7_PRESERVE_STEPS Absolutely minimal processing to preserve steps
%
% NO SMOOTHING - only detrend and remove extreme outliers

fprintf('=== PRESERVING STEPS - NO SMOOTHING ===\n');

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

%% Only remove EXTREME outliers (>5 std)
outliers = isoutlier(depth_ft_raw, 'median', 'ThresholdFactor', 5);
depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 2);

fprintf('Removed %d extreme outliers\n', sum(outliers));

%% Detrend pre-test period
pre_test_mask = timestamps < pump_start_time;
pre_test_times = timestamps(pre_test_mask);
pre_test_depth = depth_cleaned(pre_test_mask);

time_numeric = datenum(pre_test_times);
valid_idx = ~isnan(pre_test_depth);
p = polyfit(time_numeric(valid_idx), pre_test_depth(valid_idx), 1);

all_time_numeric = datenum(timestamps);
drift = polyval(p, all_time_numeric);
depth_detrended = depth_cleaned - drift + mean(pre_test_depth, 'omitnan');

fprintf('Drift removed: %.6f ft/hour\n', p(1)*24*60);

%% NO SMOOTHING - use raw detrended data
depth_final = depth_detrended;

%% Baseline from stable pre-test
baseline_mask = timestamps >= timestamps(1) + minutes(30) & timestamps < timestamps(1) + hours(1.5);
baseline_depth = mean(depth_final(baseline_mask), 'omitnan');

%% Calculate drawdown
drawdown_ft = baseline_depth - depth_final;

% Calculate elapsed time from file start
elapsed_time_sec = seconds(timestamps - timestamps(1));

% Calculate pump start in elapsed time
pump_start_elapsed = seconds(pump_start_time - timestamps(1));

fprintf('Baseline: %.4f ft\n', baseline_depth);
fprintf('Max drawdown: %.4f ft\n', max(drawdown_ft));
fprintf('Pump starts at: %.1f seconds elapsed\n', pump_start_elapsed);

%% Plot with CORRECT pump timing
pump_times_elapsed = pump_start_elapsed + [0, 3600, 7200, 10800, 14400];
rates = [50, 80, 110, 150, 0];

figure('Position', [50, 50, 1600, 800]);

% Full time series
subplot(2,1,1);
plot(elapsed_time_sec, drawdown_ft, 'b-', 'LineWidth', 1);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);

for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= 0 && pump_times_elapsed(i) <= max(elapsed_time_sec)
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 2);
        if rates(i) > 0
            text(pump_times_elapsed(i), max(ylim)*0.95, sprintf('%d GPM', rates(i)), ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        else
            text(pump_times_elapsed(i), max(ylim)*0.95, 'OFF', ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end

xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title(sprintf('%s - NO SMOOTHING (steps preserved)', zone_name));
grid on;

% Zoomed pumping period
subplot(2,1,2);
zoom_start = max(0, pump_start_elapsed - 600);
zoom_end = min(max(elapsed_time_sec), pump_start_elapsed + 15000);
zoom_mask = elapsed_time_sec >= zoom_start & elapsed_time_sec <= zoom_end;

plot(elapsed_time_sec(zoom_mask), drawdown_ft(zoom_mask), 'b-', 'LineWidth', 1.2);
hold on;
yline(0, 'r--', 'LineWidth', 1);

for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= zoom_start && pump_times_elapsed(i) <= zoom_end
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 2);
        if rates(i) > 0
            text(pump_times_elapsed(i), max(ylim)*0.9, sprintf('%d GPM', rates(i)), ...
                'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end

xlabel('Time (seconds)');
ylabel('Drawdown (ft)');
title('ZOOMED: Pumping period - Look for steps at vertical lines');
grid on;

%% Step analysis
fprintf('\nStep sizes at pump rate changes:\n');
for i = 2:length(pump_times_elapsed)-1
    if pump_times_elapsed(i) >= 0 && pump_times_elapsed(i) <= max(elapsed_time_sec)
        before_mask = elapsed_time_sec >= (pump_times_elapsed(i) - 300) & elapsed_time_sec < pump_times_elapsed(i);
        after_mask = elapsed_time_sec >= pump_times_elapsed(i) & elapsed_time_sec <= (pump_times_elapsed(i) + 300);
        
        before_avg = mean(drawdown_ft(before_mask), 'omitnan');
        after_avg = mean(drawdown_ft(after_mask), 'omitnan');
        step = after_avg - before_avg;
        
        fprintf('  %d->%d GPM: Step = %.4f ft (%.3f in)\n', ...
            rates(i-1), rates(i), step, step*12);
    end
end

%% Save
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

Date = timestamps;
Drawdownft = drawdown_ft;
Depthft = baseline_depth;
Time_sec = elapsed_time_sec;

[~, base_name, ~] = fileparts(csv_file);
save(fullfile(output_dir, sprintf('%s_no_smooth.mat', base_name)), ...
    'Date', 'Drawdownft', 'Depthft', 'Time_sec', 'pump_start_time', 'baseline_depth');

fprintf('\nSaved to: %s\n', fullfile(output_dir, sprintf('%s_no_smooth.mat', base_name)));

end
