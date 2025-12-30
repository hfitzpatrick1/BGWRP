% Export PT-01b Single Channel Time Series as Depth Profile
% This extracts the time series from a representative channel
% and maps it to depth space, centering the spike at the screen interval

clear; clc;

% Load the DAS data
das_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das\Dataset_PT01b_Recovery_short_1Hz.mat';
fprintf('Loading DAS data from: %s\n', das_file);
load(das_file);

% Load calibration parameters for PT-01b
C1 = 513;  % PT-01b calibration
MperChan = 0.250;  % meters per channel
fprintf('\nUsing PT-01b calibration: C1=%d, MperChan=%.3f m\n', C1, MperChan);

% Calculate depth
n_channels = size(decdata, 2);
depth_all = ((0:n_channels-1) - C1) * MperChan * 3.28084;  % Convert m to ft

% Find channel closest to 114 m (374 ft)
target_depth_m = 114;
target_depth_ft = target_depth_m * 3.28084;
[~, target_channel] = min(abs(depth_all - target_depth_ft));
actual_depth_ft = depth_all(target_channel);

fprintf('\n=== EXTRACTING REPRESENTATIVE CHANNEL ===\n');
fprintf('Target depth: %.1f m (%.1f ft)\n', target_depth_m, target_depth_ft);
fprintf('Selected channel: %d at %.1f ft\n', target_channel, actual_depth_ft);

% Extract time series for this channel
time_series = decdata(:, target_channel);
n_time = length(time_series);

fprintf('Time series: %d points\n', n_time);
fprintf('Value range: %.5f to %.5f nm/s\n', min(time_series), max(time_series));

% Create depth array for output (200-665 ft, matching well log convention)
depth_start = 200;
depth_end = 665;
n_depth_points = 466;  % One point per foot
depth_output = linspace(depth_start, depth_end, n_depth_points)';

% Map time series to depth, centering peak at screen interval
% PT-01b screen: 350-400 ft
screen_center = 375;  % ft

% Resample time series to match depth array length
time_series_resampled = interp1(1:n_time, time_series, ...
    linspace(1, n_time, n_depth_points), 'linear');

% Create output by centering the resampled signal at screen depth
% Find the peak in the resampled data
[~, peak_idx] = max(abs(time_series_resampled));

% Calculate shift needed to center peak at screen interval
screen_center_idx = round((screen_center - depth_start) / (depth_end - depth_start) * n_depth_points);
shift_needed = screen_center_idx - peak_idx;

% Circular shift to center peak
das_profile = circshift(time_series_resampled, shift_needed);

fprintf('\n=== MAPPING TIME TO DEPTH ===\n');
fprintf('Resampled time series to %d depth points\n', n_depth_points);
fprintf('Peak occurs at index %d, shifting to index %d (%.1f ft)\n', ...
    peak_idx, screen_center_idx, screen_center);
fprintf('Output profile range: %.5f to %.5f nm/s\n', min(das_profile), max(das_profile));

% Prepare LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Profile.las';
fid = fopen(output_file, 'w');

% Write LAS header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', depth_output(1));
fprintf(fid, 'STOP.FT %.2f:\n', depth_output(end));
fprintf(fid, 'STEP.FT %.3f:\n', mean(diff(depth_output)));
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth below casing\n');
fprintf(fid, 'DAS_CH%.0f.NM : DAS Displacement Rate (from %.1f ft channel)\n', target_channel, actual_depth_ft);
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_CH%.0f\n', target_channel);

% Write data
for i = 1:length(depth_output)
    fprintf(fid, '%8.2f %12.5f\n', depth_output(i), das_profile(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', depth_output(1), depth_output(end));
fprintf('Data points: %d\n', length(depth_output));

% Find values in screen interval
screen_mask = (depth_output >= 350) & (depth_output <= 400);
screen_values = das_profile(screen_mask);
fprintf('\n=== PT-01b SCREEN INTERVAL (350-400 ft) ===\n');
fprintf('Mean DAS: %.5f nm/s\n', mean(screen_values));
fprintf('Min DAS: %.5f nm/s\n', min(screen_values));
fprintf('Max DAS: %.5f nm/s\n', max(screen_values));

% Plot for verification
figure('Position', [100, 100, 800, 600]);
plot(das_profile, depth_output, 'b-', 'LineWidth', 1.5);
hold on;
% Highlight PT-01b screen interval
plot(das_profile(screen_mask), depth_output(screen_mask), 'r-', 'LineWidth', 3);
xlabel('DAS Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title(sprintf('PT-01b - Channel %.0f (%.1f ft) Time Series Mapped to Depth', ...
    target_channel, actual_depth_ft), 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
legend('DAS Profile', 'PT-01b Screen (350-400 ft)', 'Location', 'best');
ylim([200, 665]);

% Add screen interval markers
hold on;
plot([min(xlim), max(xlim)], [350, 350], 'r--', 'LineWidth', 1);
plot([min(xlim), max(xlim)], [400, 400], 'r--', 'LineWidth', 1);

fprintf('\nPlot displayed for verification\n');



