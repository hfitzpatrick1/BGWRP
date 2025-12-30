% Export PT-01b Mean DAS Response to LAS format
% This calculates the mean absolute response during the recovery window
% to highlight which depths are most responsive (should spike at screen interval)

clear; clc;

%% Load raw DAS data
das_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das\Dataset_PT01b_Recovery_short_1Hz.mat';
fprintf('Loading DAS data from: %s\n', das_file);
load(das_file);

%% PT-01b calibration parameters
C1 = 513;  
MperChan = 0.250;  
gauge_length = 10.18;  % meters
n_avg_GL = round(gauge_length / MperChan);

fprintf('\n=== PT-01b CALIBRATION ===\n');
fprintf('C1 = %d, MperChan = %.3f m, Gauge Length = %.2f m\n', C1, MperChan, gauge_length);
fprintf('n_avg_GL = %d channels\n', n_avg_GL);

%% Calculate depth
n_channels = size(decdata, 2);
channels = 1:n_channels;
depth_m = (channels - C1 - 1) * MperChan;
depth_ft = depth_m / 0.3048;

fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));

%% Apply calibration and smoothing
das_data = decdata;

% Gauge length averaging
if n_avg_GL > 1
    fprintf('\n=== GAUGE LENGTH AVERAGING ===\n');
    fprintf('Averaging over %d channels\n', n_avg_GL);
    das_data = movmean(das_data, n_avg_GL, 2, 'Endpoints', 'shrink');
end

% 30-second temporal smoothing
smoothing_window = 30;  % seconds
fprintf('\n=== TEMPORAL SMOOTHING ===\n');
fprintf('Applying %d-second moving mean\n', smoothing_window);
das_data = movmean(das_data, smoothing_window, 1, 'Endpoints', 'shrink');

%% Load timing to define recovery window
timing_config_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das_timing\get_timing_PT01b_Recovery_short.m';
addpath(fileparts(timing_config_path));
timing_config = feval('get_timing_PT01b_Recovery_short');
rmpath(fileparts(timing_config_path));

data_start_time = timing_config.start;
if isfield(timing_config, 'das_timing_adjustment') && timing_config.das_timing_adjustment ~= 0
    data_start_time = data_start_time + seconds(timing_config.das_timing_adjustment);
end

time_array = data_start_time + seconds(0:size(das_data, 1)-1);

% Define recovery window (from config: 19:29:00 - 19:32:00 UTC)
recovery_start = datetime(2023, 10, 31, 19, 29, 00, 'TimeZone', 'UTC');
recovery_end = datetime(2023, 10, 31, 19, 32, 00, 'TimeZone', 'UTC');

recovery_mask = (time_array >= recovery_start) & (time_array <= recovery_end);
das_recovery = das_data(recovery_mask, :);

fprintf('\n=== RECOVERY WINDOW ===\n');
fprintf('Start: %s\n', datestr(recovery_start));
fprintf('End: %s\n', datestr(recovery_end));
fprintf('Data points in window: %d\n', sum(recovery_mask));

%% Calculate mean absolute response during recovery
% This highlights which depths are most active during recovery
das_mean_response = mean(abs(das_recovery), 1, 'omitnan')';  % [channels x 1]

fprintf('\n=== MEAN RESPONSE STATISTICS ===\n');
fprintf('Mean response range: %.5f to %.5f nm/s\n', min(das_mean_response), max(das_mean_response));
fprintf('Overall mean: %.5f nm/s\n', mean(das_mean_response));

% Check screen interval
screen_min_ft = 350;
screen_max_ft = 400;
screen_mask = (depth_ft >= screen_min_ft) & (depth_ft <= screen_max_ft);
das_in_screen = das_mean_response(screen_mask);

fprintf('\n=== PT-01b SCREEN INTERVAL (%.0f-%.0f ft) ===\n', screen_min_ft, screen_max_ft);
fprintf('Mean response in screen: %.5f nm/s\n', mean(das_in_screen));
fprintf('Max response in screen: %.5f nm/s\n', max(das_in_screen));
fprintf('Min response in screen: %.5f nm/s\n', min(das_in_screen));

% Find peak response depth
[max_response, max_idx] = max(das_mean_response);
fprintf('\n=== PEAK RESPONSE ===\n');
fprintf('Peak response: %.5f nm/s at depth %.2f ft\n', max_response, depth_ft(max_idx));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Mean_Response.las';
fid = fopen(output_file, 'w');

% Header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', min(depth_ft));
fprintf(fid, 'STOP.FT %.2f:\n', max(depth_ft));
fprintf(fid, 'STEP.FT %.3f:\n', abs(depth_ft(2) - depth_ft(1)));
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth below casing\n');
fprintf(fid, 'DAS_MEAN.NM_S : Mean Abs DAS Response (30s smoothed, recovery window)\n');
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_MEAN\n');

% Write data
for i = 1:length(depth_ft)
    fprintf(fid, '%8.2f %12.5f\n', depth_ft(i), das_mean_response(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Data points: %d\n', length(depth_ft));

%% Plot for verification
figure('Name', 'PT01b Mean Response Profile', 'Position', [100, 100, 500, 800]);
plot(das_mean_response, depth_ft, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight screen interval
screen_x = [min(das_mean_response), max(das_mean_response)];
plot(screen_x, [screen_min_ft, screen_min_ft], 'r--', 'LineWidth', 2);
plot(screen_x, [screen_max_ft, screen_max_ft], 'r--', 'LineWidth', 2);

% Highlight screen data
plot(das_in_screen, depth_ft(screen_mask), 'r-', 'LineWidth', 3);

% Mark peak
plot(max_response, depth_ft(max_idx), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');

xlabel('Mean Abs Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title(sprintf('PT-01b Mean DAS Response\n(Recovery window: 19:29:00-19:32:00, Screen: %.0f-%.0f ft)', ...
    screen_min_ft, screen_max_ft), 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
ylim([min(depth_ft), max(depth_ft)]);
legend('Mean Response', 'Screen Top', 'Screen Bottom', 'Screen Interval', 'Peak', 'Location', 'best');

fprintf('\nPlot displayed for verification\n');



