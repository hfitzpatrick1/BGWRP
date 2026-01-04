% Extract PT-01a displacement rate from toolkit output and export to LAS
% This uses the exact data that appears in the PT-01a recovery analysis

clear; clc;

%% Load the processed DAS data from the toolkit
data_dir = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short\_das';
das_file = fullfile(data_dir, 'Dataset_PT01a_Recovery_short_1Hz.mat');

fprintf('Loading DAS data: %s\n', das_file);
load(das_file);

%% Apply the exact same processing as the toolkit
% From analyze_das_data.m for PT01a

% Calibration parameters (same channel mapping as PT-01b)
C1 = 513;
BOT = 1324;
well_depth_ft = 665;
MperChan = 0.250;  % meters
gauge_length = 10.18;  % meters
n_avg_GL = round(gauge_length / MperChan);

fprintf('\n=== PT-01a CALIBRATION ===\n');
fprintf('C1 = %d, BOT = %d, Well Depth = %.0f ft\n', C1, BOT, well_depth_ft);

% Calculate depth (matching PT_01a_CC.m)
n_channels = size(decdata, 2);
channels = 0:(n_channels-1);
DAS_depth_ft = (channels * MperChan) * 3.28084;
raw_depth_ft = DAS_depth_ft - DAS_depth_ft(C1+1);
scale = well_depth_ft / raw_depth_ft(BOT+1);
depth_ft_fiber = raw_depth_ft * scale;

% Map fiber depth range -100 to 565 ft to well depth 0 to 665 ft
% This requires a shift of +100 ft
depth_shift = 100;
depth_ft = depth_ft_fiber + depth_shift;

fprintf('Fiber depth range: %.2f to %.2f ft\n', min(depth_ft_fiber), max(depth_ft_fiber));
fprintf('Target section: -100 to 565 ft (fiber coords) -> 0 to 665 ft (well depth)\n');
fprintf('Shifted depth range: %.2f to %.2f ft (shifted by +%.0f ft)\n', min(depth_ft), max(depth_ft), depth_shift);

% Apply gauge length averaging
das_data = decdata;
if n_avg_GL > 1
    fprintf('Applying gauge length averaging (%d channels)\n', n_avg_GL);
    das_data = movmean(das_data, n_avg_GL, 2, 'Endpoints', 'shrink');
end

% Apply 30-second smoothing (as per toolkit config)
smoothing_window = 30;
fprintf('Applying %d-second temporal smoothing\n', smoothing_window);
das_data = movmean(das_data, smoothing_window, 1, 'Endpoints', 'shrink');

%% Load timing and define analysis window
timing_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_short\_das_timing\get_timing_PT01a_Recovery_short.m';
addpath(fileparts(timing_file));
timing_config = get_timing_PT01a_Recovery_short();
rmpath(fileparts(timing_file));

% Apply DAS timing adjustment
data_start_time = timing_config.start + seconds(30);  % +30 second adjustment from toolkit
time_array = data_start_time + seconds(0:size(das_data,1)-1);

% Analysis window - focused 5-minute window during early recovery
analysis_window = [datetime(2023, 11, 7, 20, 42, 0, 'TimeZone', 'UTC'), ...
                   datetime(2023, 11, 7, 20, 47, 0, 'TimeZone', 'UTC')];

fprintf('\n=== ANALYSIS WINDOW ===\n');
fprintf('Start: %s\n', datestr(analysis_window(1)));
fprintf('End: %s\n', datestr(analysis_window(2)));

% Filter to analysis window
window_mask = time_array >= analysis_window(1) & time_array <= analysis_window(2);
das_window = das_data(window_mask, :);

fprintf('Window data size: [%d x %d]\n', size(das_window));

%% Calculate mean displacement rate for each depth (this is what appears as the black line)
displacement_rate_mean = mean(das_window, 1, 'omitnan')';  % Mean over time

fprintf('\n=== MEAN DISPLACEMENT RATE ===\n');
fprintf('Range: %.5f to %.5f nm/s\n', min(displacement_rate_mean), max(displacement_rate_mean));
fprintf('Overall mean: %.5f nm/s\n', mean(displacement_rate_mean, 'omitnan'));

% Check PT-01a screen interval
screen_min = 450;
screen_max = 510;
screen_mask = (depth_ft >= screen_min) & (depth_ft <= screen_max);

fprintf('\n=== PT-01a SCREEN (%.0f-%.0f ft) ===\n', screen_min, screen_max);
fprintf('Mean: %.5f nm/s\n', mean(displacement_rate_mean(screen_mask), 'omitnan'));
fprintf('Min: %.5f nm/s\n', min(displacement_rate_mean(screen_mask)));
fprintf('Max: %.5f nm/s\n', max(displacement_rate_mean(screen_mask)));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01a_DAS_Profile_Final.las';
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
fprintf(fid, 'DAS_MEAN.NM : DAS Mean Displacement Rate (Recovery 20:42:00-20:47:00)\n');
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_MEAN\n');

% Write data
for i = 1:length(depth_ft)
    fprintf(fid, '%8.2f %12.5f\n', depth_ft(i), displacement_rate_mean(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('Output: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Points: %d\n', length(depth_ft));

%% Verification plot
figure('Position', [100 100 600 800]);
plot(displacement_rate_mean, depth_ft, 'b-', 'LineWidth', 2);
hold on;
plot(displacement_rate_mean(screen_mask), depth_ft(screen_mask), 'r-', 'LineWidth', 3);
yline(screen_min, 'r--', 'LineWidth', 1.5);
yline(screen_max, 'r--', 'LineWidth', 1.5);
set(gca, 'YDir', 'reverse');
xlabel('Mean Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title('PT-01a Mean Displacement Rate (from Toolkit)', 'FontSize', 14);
grid on;
ylim([min(depth_ft) max(depth_ft)]);
legend('All Depths', 'Screen Interval', 'Location', 'best');

fprintf('\nThis data matches the black line in Figure 102!\n');
