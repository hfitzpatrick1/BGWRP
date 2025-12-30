% Export PT-01b Recovery DAS Mean data to LAS format
% This script loads processed DAS data and exports mean displacement rate vs depth

clear; clc;

% Load the DAS data
das_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das\Dataset_PT01b_Recovery_short_1Hz.mat';
fprintf('Loading DAS data from: %s\n', das_file);
load(das_file);

% Display what variables we have
fprintf('Variables loaded:\n');
whos

% Load calibration parameters for PT-01b
C1 = 513;  % PT-01b calibration
MperChan = 0.250;  % meters per channel
fprintf('\nUsing PT-01b calibration: C1=%d, MperChan=%.3f m\n', C1, MperChan);

% Extract depth and calculate mean across time
% Check which variables are available
if exist('smoothed_data', 'var')
    das_data = smoothed_data;
elseif exist('strain_rate', 'var')
    das_data = strain_rate;
elseif exist('decdata', 'var')
    das_data = decdata;
else
    error('Could not find smoothed_data, strain_rate, or decdata variable');
end

% Get depth from calibration parameters
if exist('depth_ft', 'var')
    depth = depth_ft;
elseif exist('depth', 'var')
    depth = depth;
else
    % Calculate depth from calibration if available
    if exist('C1', 'var') && exist('MperChan', 'var')
        n_channels = size(das_data, 2);
        depth = ((0:n_channels-1) - C1) * MperChan * 3.28084;  % Convert m to ft
        fprintf('Calculated depth from calibration: C1=%d, MperChan=%.3f m\n', C1, MperChan);
    else
        error('Could not find depth information');
    end
end

% Extract a single time slice during peak recovery (not mean!)
% For PT-01b recovery started around 19:30:00
% We want to capture the peak displacement rate during recovery

fprintf('Data dimensions:\n');
fprintf('  DAS data: [%d time points x %d channels]\n', size(das_data, 1), size(das_data, 2));
fprintf('  Depth: %d points\n', length(depth));

% Find the time index with maximum response in the screen interval
screen_idx = find(depth >= 350 & depth <= 400);
if isempty(screen_idx)
    error('Could not find PT-01b screen interval in depth array');
end

% Calculate mean absolute displacement for screen zone at each time
screen_signal = mean(abs(das_data(:, screen_idx)), 2, 'omitnan');
[~, peak_time_idx] = max(screen_signal);

fprintf('\n=== SELECTING PEAK RECOVERY TIME ===\n');
fprintf('Peak signal at time index: %d (out of %d)\n', peak_time_idx, size(das_data, 1));
fprintf('Peak signal magnitude in screen: %.5f nm/s\n', screen_signal(peak_time_idx));

% Extract displacement rate at this single time
das_snapshot = das_data(peak_time_idx, :)';

fprintf('Extracted snapshot: %d points\n', length(das_snapshot));

% Match sizes if needed
if length(depth) ~= length(das_snapshot)
    fprintf('WARNING: Depth and DAS snapshot sizes do not match!\n');
    min_len = min(length(depth), length(das_snapshot));
    depth = depth(1:min_len);
    das_snapshot = das_snapshot(1:min_len);
    fprintf('Truncated to %d points\n', min_len);
end

% Sort by depth (should already be sorted, but just in case)
[depth_sorted, sort_idx] = sort(depth);
das_snapshot_sorted = das_snapshot(sort_idx);

% Prepare LAS file content
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_Recovery_short_DAS_Mean.las';

% Open file for writing
fid = fopen(output_file, 'w');

% Write LAS header
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', depth_sorted(1));
fprintf(fid, 'STOP.FT %.2f:\n', depth_sorted(end));
fprintf(fid, 'STEP.FT %.3f:\n', mean(diff(depth_sorted)));
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth below casing\n');
fprintf(fid, 'DAS_SNAP.NM : DAS Displacement Rate Snapshot\n');
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_SNAP\n');

% Write data
for i = 1:length(depth_sorted)
    fprintf(fid, '%8.2f %12.5f\n', depth_sorted(i), das_snapshot_sorted(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', depth_sorted(1), depth_sorted(end));
fprintf('Data points: %d\n', length(depth_sorted));
fprintf('DAS snapshot range: %.5f to %.5f nm/s\n', min(das_snapshot_sorted), max(das_snapshot_sorted));

% Find peak in PT-01b screen interval (350-400 ft)
screen_mask = (depth_sorted >= 350) & (depth_sorted <= 400);
if any(screen_mask)
    screen_das = das_snapshot_sorted(screen_mask);
    fprintf('\n=== PT-01b SCREEN INTERVAL (350-400 ft) AT PEAK TIME ===\n');
    fprintf('Mean DAS in screen: %.5f nm/s\n', mean(screen_das));
    fprintf('Min DAS in screen: %.5f nm/s\n', min(screen_das));
    fprintf('Max DAS in screen: %.5f nm/s\n', max(screen_das));
end

% Plot for verification
figure('Position', [100, 100, 800, 600]);
plot(das_snapshot_sorted, depth_sorted, 'b-', 'LineWidth', 1.5);
hold on;
% Highlight PT-01b screen interval
plot(das_snapshot_sorted(screen_mask), depth_sorted(screen_mask), 'r-', 'LineWidth', 3);
xlabel('DAS Mean Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title('PT-01b Recovery - DAS Mean Displacement Rate vs Depth', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');  % Depth increases downward
grid on;
legend('DAS Mean', 'PT-01b Screen (350-400 ft)', 'Location', 'best');

% Add screen interval annotation
ylim([200, 665]);
hold on;
plot([min(xlim), max(xlim)], [350, 350], 'r--', 'LineWidth', 1);
plot([min(xlim), max(xlim)], [400, 400], 'r--', 'LineWidth', 1);

fprintf('\nPlot displayed for verification\n');

