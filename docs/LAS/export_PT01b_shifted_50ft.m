% Export PT-01b DAS shifted down 50 feet to align with screen interval

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
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));

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
[peak_value, peak_idx] = min(das_snapshot);  % Most negative value
current_peak_depth_ft = depth_ft(peak_idx);

fprintf('\n=== CURRENT PEAK LOCATION ===\n');
fprintf('Peak at: %.2f ft\n', current_peak_depth_ft);
fprintf('Peak value: %.5f nm/s\n', peak_value);

%% Calculate shift needed to move peak to screen center
screen_center_ft = (350 + 400) / 2;  % 375 ft
shift_ft = screen_center_ft - current_peak_depth_ft;  % Shift needed
depth_ft_shifted = depth_ft + shift_ft;

fprintf('\n=== SHIFTING TO SCREEN CENTER (%.1f ft) ===\n', screen_center_ft);
fprintf('Shift amount: %.1f feet\n', shift_ft);
fprintf('New depth range: %.2f to %.2f ft\n', min(depth_ft_shifted), max(depth_ft_shifted));
fprintf('Peak now at: %.2f ft\n', depth_ft_shifted(peak_idx));

% Check alignment with screen
screen_min_ft = 350;
screen_max_ft = 400;
fprintf('\n=== ALIGNMENT WITH SCREEN (%.0f-%.0f ft) ===\n', screen_min_ft, screen_max_ft);
if (depth_ft_shifted(peak_idx) >= screen_min_ft) && (depth_ft_shifted(peak_idx) <= screen_max_ft)
    fprintf('✓ Peak is now INSIDE screen interval\n');
else
    fprintf('Peak is %.1f ft from screen center (%.1f ft)\n', ...
        abs(depth_ft_shifted(peak_idx) - (screen_min_ft + screen_max_ft)/2), ...
        (screen_min_ft + screen_max_ft)/2);
end

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Shifted_50ft.las';
fid = fopen(output_file, 'w');

% Header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', min(depth_ft_shifted));
fprintf(fid, 'STOP.FT %.2f:\n', max(depth_ft_shifted));
fprintf(fid, 'STEP.FT %.3f:\n', mean(diff(depth_ft_shifted)));
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth (shifted to align peak with screen 350-400 ft)\n');
fprintf(fid, 'DAS_RATE.NM_S : DAS Displacement Rate at %s (30s smoothed)\n', datestr(time_array(snapshot_idx), 'HH:MM:SS'));
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_RATE\n');

% Write data
for i = 1:length(depth_ft_shifted)
    fprintf(fid, '%8.2f %12.5f\n', depth_ft_shifted(i), das_snapshot(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft_shifted), max(depth_ft_shifted));

%% Plot for verification
figure('Name', 'PT01b DAS - Shifted 50ft Down', 'Position', [100, 100, 500, 800]);
plot(das_snapshot, depth_ft_shifted, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight screen interval
screen_x = [min(das_snapshot), max(das_snapshot)];
plot(screen_x, [screen_min_ft, screen_min_ft], 'r--', 'LineWidth', 2);
plot(screen_x, [screen_max_ft, screen_max_ft], 'r--', 'LineWidth', 2);

% Highlight screen data
screen_mask = (depth_ft_shifted >= screen_min_ft) & (depth_ft_shifted <= screen_max_ft);
plot(das_snapshot(screen_mask), depth_ft_shifted(screen_mask), 'r-', 'LineWidth', 3);

% Mark peak
plot(peak_value, depth_ft_shifted(peak_idx), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');

xlabel('Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title(sprintf('PT-01b DAS at %s\n(Peak aligned to screen: %.0f-%.0f ft)', ...
    datestr(time_array(snapshot_idx), 'HH:MM:SS'), screen_min_ft, screen_max_ft), ...
    'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
ylim([0, 665]);
legend('DAS Profile', 'Screen Top (350ft)', 'Screen Bottom (400ft)', 'Screen Interval', 'Peak', 'Location', 'best');

fprintf('\nPlot displayed for verification\n');

