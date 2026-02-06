function process_pm7_minimal_processing(csv_file, zone_name, pump_start_time)
%PROCESS_PM7_MINIMAL_PROCESSING Minimal smoothing to preserve ALL steps
%
% Uses VERY light processing to keep steps visible

fprintf('=== MINIMAL PROCESSING - PRESERVE STEPS ===\n');

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

depth_ft_raw = data_table.Depth_ft;

%% MINIMAL cleaning - only remove extreme outliers
outliers = isoutlier(depth_ft_raw, 'median');
depth_cleaned = depth_ft_raw;
depth_cleaned(outliers) = NaN;
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', 3);

%% VERY light 3-point smoothing only
depth_smoothed = movmean(depth_cleaned, 3, 'omitnan');

%% Baseline from just before pump start
baseline_start = pump_start_time - minutes(5);
baseline_end = pump_start_time - seconds(30);
baseline_mask = timestamps >= baseline_start & timestamps <= baseline_end;

baseline_depth = mean(depth_smoothed(baseline_mask), 'omitnan');
drawdown_ft = depth_smoothed - baseline_depth;

fprintf('Baseline: %.3f ft\n', baseline_depth);
fprintf('Max drawdown: %.3f ft\n', max(drawdown_ft));

%% Plot with step annotations
pump_times = [
    pump_start_time;                    % 16:45 - 50 GPM
    pump_start_time + hours(1) + minutes(2);        % 17:47 - 80 GPM  
    pump_start_time + hours(2);         % 18:45 - 110 GPM
    pump_start_time + hours(3);         % 19:45 - 150 GPM
    pump_start_time + hours(4);         % 20:45 - OFF
];

rates = [50, 80, 110, 150, 0];

figure('Position', [100, 100, 1600, 900]);

% Full time series
subplot(2,1,1);
plot(timestamps, drawdown_ft, 'b-', 'LineWidth', 1.2);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 1.5);
    if i <= length(rates)
        if rates(i) > 0
            text(pump_times(i), max(ylim)*0.95, sprintf('%d GPM', rates(i)), ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');
        else
            text(pump_times(i), max(ylim)*0.95, 'OFF', ...
                'FontSize', 10, 'FontWeight', 'bold', 'BackgroundColor', 'white');
        end
    end
end
ylabel('Drawdown (ft)');
title(sprintf('%s - MINIMAL Processing (3-point smooth only)', zone_name));
grid on;
valid_times = timestamps(~isnat(timestamps));
if ~isempty(valid_times)
    xlim([valid_times(1), valid_times(end)]);
end

% Zoom on pumping period
subplot(2,1,2);
pump_mask = timestamps >= pump_start_time & timestamps <= pump_start_time + hours(4.5);
plot(timestamps(pump_mask), drawdown_ft(pump_mask), 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'LineWidth', 1);
for i = 1:length(pump_times)
    xline(pump_times(i), 'k--', 'LineWidth', 2);
    if i <= length(rates)
        if rates(i) > 0
            text(pump_times(i), max(ylim)*0.9, sprintf('%d GPM', rates(i)), ...
                'FontSize', 11, 'FontWeight', 'bold', 'BackgroundColor', 'yellow');
        end
    end
end
ylabel('Drawdown (ft)');
xlabel('Time (UTC)');
title('ZOOMED: Pumping Period - Look for steps after vertical lines');
grid on;
try
    xlim([pump_start_time - minutes(10), pump_start_time + hours(4.5)]);
catch
    % Skip if xlim fails
end

%% Print step check
fprintf('\nChecking for steps at pump rate changes:\n');
for i = 2:length(pump_times)-1
    % Get data 10 min before and after rate change
    before_mask = timestamps >= (pump_times(i) - minutes(10)) & timestamps < pump_times(i);
    after_mask = timestamps >= pump_times(i) & timestamps <= (pump_times(i) + minutes(10));
    
    before_avg = mean(drawdown_ft(before_mask), 'omitnan');
    after_avg = mean(drawdown_ft(after_mask), 'omitnan');
    step_size = after_avg - before_avg;
    
    fprintf('  %d->%d GPM: Before=%.4f ft, After=%.4f ft, Step=%.4f ft\n', ...
        rates(i-1), rates(i), before_avg, after_avg, step_size);
end

%% Save
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

Date = timestamps;
Drawdownft = drawdown_ft;
Depthft = baseline_depth;

[~, base_name, ~] = fileparts(csv_file);
save(fullfile(output_dir, sprintf('%s_minimal.mat', base_name)), ...
    'Date', 'Drawdownft', 'Depthft', 'pump_start_time');

fprintf('\nIf you still don''t see steps, they genuinely aren''t in your data.\n');

end
