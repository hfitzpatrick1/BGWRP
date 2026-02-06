function process_raw_preserve_steps(csv_file, zone_name, pump_start_time)
%PROCESS_RAW_PRESERVE_STEPS Minimal processing to preserve step plateaus
%
% NO smoothing - only extreme outlier removal and pre-test detrend

fprintf('=== ABSOLUTE MINIMAL PROCESSING - PRESERVE STEP PLATEAUS ===\n');

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

fprintf('Loaded %d raw data points\n', length(depth_ft_raw));

%% Only remove EXTREME outliers (>10 std)
outliers = isoutlier(depth_ft_raw, 'median', 'ThresholdFactor', 10);
depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 1);

fprintf('Removed %d extreme outliers\n', sum(outliers));

%% Calculate pre-test baseline (NO detrending of pumping period!)
pre_test_mask = timestamps < pump_start_time;
pre_test_depth = depth_cleaned(pre_test_mask);

% Just use mean of pre-test for baseline - DON'T extrapolate trend!
baseline_mean = mean(pre_test_depth, 'omitnan');

fprintf('Pre-test mean depth: %.4f ft\n', baseline_mean);

%% NO SMOOTHING - use raw cleaned data directly
depth_final = depth_cleaned;

%% Use pre-test mean as baseline
baseline_depth = baseline_mean;

fprintf('Using baseline: %.4f ft\n', baseline_depth);

%% Calculate displacement (positive = water drops - like drawdown)
% For steps to show, we want baseline = 0
displacement_ft = baseline_depth - depth_final;  % Flipped: positive when water level drops

%% Elapsed time
elapsed_time_sec = seconds(timestamps - timestamps(1));
pump_start_elapsed = seconds(pump_start_time - timestamps(1));

fprintf('Pump starts at: %.1f seconds elapsed\n', pump_start_elapsed);
fprintf('Max displacement: %.4f ft\n', max(displacement_ft));

%% Plot with pump schedule
pump_times_elapsed = pump_start_elapsed + [0, 3600, 7200, 10800, 14400];
rates = [50, 80, 110, 150, 0];

figure('Position', [50, 50, 1600, 900]);

% Full time series
subplot(2,1,1);
plot(elapsed_time_sec, displacement_ft, 'b.', 'MarkerSize', 4);  % Plot as points to see steps
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 2);

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
ylabel('Displacement (ft)');
title(sprintf('%s - RAW with NO smoothing (steps preserved)', zone_name));
grid on;

% Zoomed on pumping
subplot(2,1,2);
zoom_start = max(0, pump_start_elapsed - 600);
zoom_end = min(max(elapsed_time_sec), pump_start_elapsed + 15000);
zoom_mask = elapsed_time_sec >= zoom_start & elapsed_time_sec <= zoom_end;

plot(elapsed_time_sec(zoom_mask), displacement_ft(zoom_mask), 'b.', 'MarkerSize', 6);
hold on;
yline(0, 'r--', 'LineWidth', 1.5);

for i = 1:length(pump_times_elapsed)
    if pump_times_elapsed(i) >= zoom_start && pump_times_elapsed(i) <= zoom_end
        xline(pump_times_elapsed(i), 'k--', 'LineWidth', 2.5);
        if rates(i) > 0
            text(pump_times_elapsed(i), max(ylim)*0.9, sprintf('%d GPM', rates(i)), ...
                'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end

xlabel('Time (seconds)');
ylabel('Displacement (ft)');
title('ZOOMED: Steps should be visible as plateaus');
grid on;

%% Export
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

Time_sec = elapsed_time_sec;
Displacement_ft = displacement_ft;

export_table = table(Time_sec, Displacement_ft, ...
    'VariableNames', {'Time_sec', 'Displacement_ft'});

[~, base_name, ~] = fileparts(csv_file);
output_csv = fullfile(output_dir, sprintf('%s_RAW_STEPS_PRESERVED.csv', base_name));
writetable(export_table, output_csv);

fprintf('\nExported to: %s\n', output_csv);
fprintf('NO SMOOTHING - raw step plateaus preserved!\n');

end
