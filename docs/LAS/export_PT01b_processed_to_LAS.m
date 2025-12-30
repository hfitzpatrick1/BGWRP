% Export PT-01b PROCESSED DAS data to LAS format
% This replicates the processing pipeline to get calibrated displacement rate

clear; clc;

%% Load raw DAS data
das_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das\Dataset_PT01b_Recovery_short_1Hz.mat';
fprintf('Loading DAS data from: %s\n', das_file);
load(das_file);

%% PT-01b calibration parameters (from PT_01b_CC.m)
C1 = 513;
BOT = 1324;
well_depth_ft = 665;
MperChan = 0.250;  % meters
gauge_length = 10.18;  % meters
n_avg_GL = round(gauge_length / MperChan);

fprintf('\n=== PT-01b CALIBRATION ===\n');
fprintf('C1 = %d, BOT = %d, Well Depth = %.0f ft\n', C1, BOT, well_depth_ft);
fprintf('MperChan = %.3f m, Gauge Length = %.2f m\n', MperChan, gauge_length);
fprintf('n_avg_GL = %d channels\n', n_avg_GL);

%% Calculate depth (matching PT_01b_CC.m exactly)
n_channels = size(decdata, 2);
channels = 0:(n_channels-1);
DAS_depth_ft = (channels * MperChan) * 3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1+1);  % +1 for MATLAB indexing
scale = well_depth_ft / raw_depth_ft(BOT+1);  % +1 for MATLAB indexing
depth_ft_fiber = raw_depth_ft * scale;

% Shift to well coordinates (start near 0 like PT01c)
depth_shift = -min(depth_ft_fiber);  % Shift so minimum depth is ~0
depth_ft = depth_ft_fiber + depth_shift;

fprintf('Fiber depth range: %.2f to %.2f ft\n', min(depth_ft_fiber), max(depth_ft_fiber));
fprintf('Well depth range: %.2f to %.2f ft (shifted by +%.2f ft)\n', min(depth_ft), max(depth_ft), depth_shift);

%% Apply calibration scaling (convert to strain rate, then displacement rate)
% From analyze_das_data.m lines 197-234
das_data = decdata;

% Apply gauge length averaging (if configured)
if n_avg_GL > 1
    fprintf('\n=== GAUGE LENGTH AVERAGING ===\n');
    fprintf('Averaging over %d channels\n', n_avg_GL);
    das_data_filtered = movmean(das_data, n_avg_GL, 2, 'Endpoints', 'shrink');
    das_data = das_data_filtered;
end

% Apply 1-second temporal smoothing (minimal smoothing for more detail)
smoothing_window = 1;  % seconds
fprintf('\n=== TEMPORAL SMOOTHING ===\n');
fprintf('Applying %d-second moving mean\n', smoothing_window);
das_data_smooth = movmean(das_data, smoothing_window, 1, 'Endpoints', 'shrink');
das_data = das_data_smooth;

%% Load timing to find peak recovery time
timing_config_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das_timing\get_timing_PT01b_Recovery_short.m';
addpath(fileparts(timing_config_path));
timing_config = feval('get_timing_PT01b_Recovery_short');
rmpath(fileparts(timing_config_path));

data_start_time = timing_config.start;
if isfield(timing_config, 'das_timing_adjustment') && timing_config.das_timing_adjustment ~= 0
    data_start_time = data_start_time + seconds(timing_config.das_timing_adjustment);
end

time_array = data_start_time + seconds(0:size(das_data, 1)-1);

% Find peak recovery time (around 19:30:30 UTC based on Figure 102)
snapshot_time_target = datetime(2023, 10, 31, 19, 30, 30, 'TimeZone', 'UTC');
[~, snapshot_idx] = min(abs(time_array - snapshot_time_target));

fprintf('\n=== SELECTING SNAPSHOT TIME ===\n');
fprintf('Target time: %s\n', datestr(snapshot_time_target));
fprintf('Selected time: %s (index %d)\n', datestr(time_array(snapshot_idx)), snapshot_idx);

%% Extract spatial profile at peak time
das_snapshot = das_data(snapshot_idx, :)';  % [channels x 1]

fprintf('\n=== SNAPSHOT STATISTICS ===\n');
fprintf('DAS snapshot range: %.5f to %.5f nm/s\n', min(das_snapshot), max(das_snapshot));
fprintf('Mean: %.5f nm/s\n', mean(das_snapshot));

% Check screen interval
screen_min_ft = 350;
screen_max_ft = 400;
screen_mask = (depth_ft >= screen_min_ft) & (depth_ft <= screen_max_ft);
das_in_screen = das_snapshot(screen_mask);

fprintf('\n=== PT-01b SCREEN INTERVAL (%.0f-%.0f ft) ===\n', screen_min_ft, screen_max_ft);
fprintf('Mean DAS in screen: %.5f nm/s\n', mean(das_in_screen));
fprintf('Min DAS in screen: %.5f nm/s\n', min(das_in_screen));
fprintf('Max DAS in screen: %.5f nm/s\n', max(das_in_screen));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Processed.las';
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
fprintf(fid, 'DAS_RATE.NM_S : DAS Displacement Rate at %s (1s smoothed)\n', datestr(time_array(snapshot_idx), 'HH:MM:SS'));
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_RATE\n');

% Write data
for i = 1:length(depth_ft)
    fprintf(fid, '%8.2f %12.5f\n', depth_ft(i), das_snapshot(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Data points: %d\n', length(depth_ft));

%% Plot for verification
figure('Name', 'PT01b Processed DAS Profile', 'Position', [100, 100, 500, 800]);
plot(das_snapshot, depth_ft, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight screen interval
screen_x = [min(das_snapshot), max(das_snapshot)];
plot(screen_x, [screen_min_ft, screen_min_ft], 'r--', 'LineWidth', 2);
plot(screen_x, [screen_max_ft, screen_max_ft], 'r--', 'LineWidth', 2);

% Highlight screen data
plot(das_in_screen, depth_ft(screen_mask), 'r-', 'LineWidth', 3);

xlabel('Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title(sprintf('PT-01b DAS at %s\n(1s smoothed, Screen: %.0f-%.0f ft)', ...
    datestr(time_array(snapshot_idx), 'HH:MM:SS'), screen_min_ft, screen_max_ft), ...
    'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
ylim([min(depth_ft), max(depth_ft)]);

fprintf('\nPlot displayed for verification\n');

