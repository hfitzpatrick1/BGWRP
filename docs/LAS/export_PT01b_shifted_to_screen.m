% Export PT-01b DAS to LAS with peak shifted to screen interval
% This takes the spatial profile and shifts it so the peak aligns with the screen

clear; clc;

%% Load the processed data
das_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das\Dataset_PT01b_Recovery_short_1Hz.mat';
fprintf('Loading DAS data from: %s\n', das_file);
load(das_file);

%% PT-01b calibration parameters
C1 = 513;  
MperChan = 0.250;  
gauge_length = 10.18;
n_avg_GL = round(gauge_length / MperChan);

%% Calculate depth
n_channels = size(decdata, 2);
channels = 1:n_channels;
depth_m = (channels - C1 - 1) * MperChan;
depth_ft = depth_m / 0.3048;

fprintf('\n=== ORIGINAL DEPTH RANGE ===\n');
fprintf('Depth range: %.2f to %.2f m (%.2f to %.2f ft)\n', min(depth_m), max(depth_m), min(depth_ft), max(depth_ft));

%% Apply processing
das_data = decdata;

% Gauge length averaging
if n_avg_GL > 1
    das_data = movmean(das_data, n_avg_GL, 2, 'Endpoints', 'shrink');
end

% 30-second temporal smoothing
smoothing_window = 30;
das_data = movmean(das_data, smoothing_window, 1, 'Endpoints', 'shrink');

%% Load timing and extract snapshot at peak
timing_config_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das_timing\get_timing_PT01b_Recovery_short.m';
addpath(fileparts(timing_config_path));
timing_config = feval('get_timing_PT01b_Recovery_short');
rmpath(fileparts(timing_config_path));

data_start_time = timing_config.start;
if isfield(timing_config, 'das_timing_adjustment') && timing_config.das_timing_adjustment ~= 0
    data_start_time = data_start_time + seconds(timing_config.das_timing_adjustment);
end

time_array = data_start_time + seconds(0:size(das_data, 1)-1);
snapshot_time_target = datetime(2023, 10, 31, 19, 30, 30, 'TimeZone', 'UTC');
[~, snapshot_idx] = min(abs(time_array - snapshot_time_target));

das_snapshot = das_data(snapshot_idx, :)';

fprintf('\n=== SNAPSHOT AT %s ===\n', datestr(time_array(snapshot_idx)));
fprintf('DAS range: %.5f to %.5f nm/s\n', min(das_snapshot), max(das_snapshot));

%% Find current peak location
[peak_value, peak_idx] = min(das_snapshot);  % Most negative value (strongest response)
current_peak_depth_m = depth_m(peak_idx);
current_peak_depth_ft = depth_ft(peak_idx);

fprintf('\n=== CURRENT PEAK LOCATION ===\n');
fprintf('Peak at: %.2f m (%.2f ft)\n', current_peak_depth_m, current_peak_depth_ft);
fprintf('Peak value: %.5f nm/s\n', peak_value);

%% Calculate shift needed to move peak to screen center
% PT-01b screen: 107-122 m (350-400 ft)
screen_center_m = (107 + 122) / 2;  % 114.5 m
screen_center_ft = screen_center_m * 3.28084;  % 375.7 ft

shift_needed_m = screen_center_m - current_peak_depth_m;
shift_needed_ft = shift_needed_m * 3.28084;

fprintf('\n=== SHIFTING TO SCREEN INTERVAL ===\n');
fprintf('Screen center: %.2f m (%.2f ft)\n', screen_center_m, screen_center_ft);
fprintf('Shift needed: %.2f m (%.2f ft)\n', shift_needed_m, shift_needed_ft);

%% Apply shift to depth array
depth_m_shifted = depth_m + shift_needed_m;
depth_ft_shifted = depth_m_shifted * 3.28084;

fprintf('\n=== SHIFTED DEPTH RANGE ===\n');
fprintf('New depth range: %.2f to %.2f m (%.2f to %.2f ft)\n', ...
    min(depth_m_shifted), max(depth_m_shifted), min(depth_ft_shifted), max(depth_ft_shifted));

% Verify peak is now at screen
[~, new_peak_idx] = min(das_snapshot);
fprintf('Peak now at: %.2f m (%.2f ft)\n', depth_m_shifted(new_peak_idx), depth_ft_shifted(new_peak_idx));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Shifted.las';
fid = fopen(output_file, 'w');

% Header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.M %.2f:\n', min(depth_m_shifted));
fprintf(fid, 'STOP.M %.2f:\n', max(depth_m_shifted));
fprintf(fid, 'STEP.M %.3f:\n', MperChan);
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.M      : Depth (shifted to align peak with screen)\n');
fprintf(fid, 'DAS_RATE.NM_S : DAS Displacement Rate at %s (30s smoothed)\n', datestr(time_array(snapshot_idx), 'HH:MM:SS'));
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_RATE\n');

% Write data
for i = 1:length(depth_m_shifted)
    fprintf(fid, '%8.2f %12.5f\n', depth_m_shifted(i), das_snapshot(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f m\n', min(depth_m_shifted), max(depth_m_shifted));
fprintf('Data points: %d\n', length(depth_m_shifted));

%% Plot for verification
figure('Name', 'PT01b DAS Profile - Shifted to Screen', 'Position', [100, 100, 500, 800]);
plot(das_snapshot, depth_m_shifted, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight screen interval
screen_top_m = 107;
screen_bottom_m = 122;
screen_x = [min(das_snapshot), max(das_snapshot)];
plot(screen_x, [screen_top_m, screen_top_m], 'r--', 'LineWidth', 2);
plot(screen_x, [screen_bottom_m, screen_bottom_m], 'r--', 'LineWidth', 2);

% Highlight screen data
screen_mask = (depth_m_shifted >= screen_top_m) & (depth_m_shifted <= screen_bottom_m);
plot(das_snapshot(screen_mask), depth_m_shifted(screen_mask), 'r-', 'LineWidth', 3);

% Mark peak
plot(peak_value, depth_m_shifted(new_peak_idx), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');

xlabel('Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (m)', 'FontSize', 12);
title(sprintf('PT-01b DAS at %s\n(Shifted: Peak aligned with screen 107-122 m)', ...
    datestr(time_array(snapshot_idx), 'HH:MM:SS')), 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
ylim([min(depth_m_shifted), max(depth_m_shifted)]);
legend('DAS Profile', 'Screen Top (107m)', 'Screen Bottom (122m)', 'Screen Interval', 'Peak', 'Location', 'best');

fprintf('\nPlot displayed for verification\n');



