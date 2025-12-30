% Export PT-01b mean displacement rate during recovery to LAS format
% This calculates the MEAN displacement rate over the recovery window
% for each depth channel - matching the processing in linear_regression_depth_range.m

clear; clc;

%% Load DAS data
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
depth_shift = -min(depth_ft_fiber);
depth_ft = depth_ft_fiber + depth_shift;

fprintf('Fiber depth range: %.2f to %.2f ft\n', min(depth_ft_fiber), max(depth_ft_fiber));
fprintf('Well depth range: %.2f to %.2f ft (shifted by +%.2f ft)\n', min(depth_ft), max(depth_ft), depth_shift);

%% Apply calibration and processing (matching linear_regression)
das_data = decdata;

% Apply gauge length averaging
if n_avg_GL > 1
    fprintf('\n=== GAUGE LENGTH AVERAGING ===\n');
    fprintf('Averaging over %d channels\n', n_avg_GL);
    das_data = movmean(das_data, n_avg_GL, 2, 'Endpoints', 'shrink');
end

% Apply minimal temporal smoothing (1 second)
smoothing_window = 1;  % seconds
fprintf('\n=== TEMPORAL SMOOTHING ===\n');
fprintf('Applying %d-second moving mean\n', smoothing_window);
das_data = movmean(das_data, smoothing_window, 1, 'Endpoints', 'shrink');

%% Load timing and define recovery window
timing_config_path = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01b_Recovery_short\_das_timing\get_timing_PT01b_Recovery_short.m';
addpath(fileparts(timing_config_path));
timing_config = feval('get_timing_PT01b_Recovery_short');
rmpath(fileparts(timing_config_path));

data_start_time = timing_config.start;
if isfield(timing_config, 'das_timing_adjustment') && timing_config.das_timing_adjustment ~= 0
    data_start_time = data_start_time + seconds(timing_config.das_timing_adjustment);
end

time_array = data_start_time + seconds(0:size(das_data, 1)-1);

% Define recovery window (from linear regression config)
recovery_window = [datetime(2023, 10, 31, 19, 29, 30, 'TimeZone', 'UTC'), ...
                   datetime(2023, 10, 31, 19, 32, 30, 'TimeZone', 'UTC')];

fprintf('\n=== RECOVERY WINDOW ===\n');
fprintf('Start: %s\n', datestr(recovery_window(1)));
fprintf('End: %s\n', datestr(recovery_window(2)));

% Filter to recovery window
recovery_mask = time_array >= recovery_window(1) & time_array <= recovery_window(2);
das_recovery = das_data(recovery_mask, :);

fprintf('Recovery data size: [%d x %d]\n', size(das_recovery));

%% Calculate mean displacement rate for each depth
das_mean = mean(das_recovery, 1, 'omitnan')';  % Mean over time, column vector

fprintf('\n=== MEAN DISPLACEMENT RATE STATISTICS ===\n');
fprintf('DAS mean range: %.5f to %.5f nm/s\n', min(das_mean), max(das_mean));
fprintf('Overall mean: %.5f nm/s\n', mean(das_mean, 'omitnan'));

% Check screen interval
screen_min_ft = 350;
screen_max_ft = 400;
screen_mask = (depth_ft >= screen_min_ft) & (depth_ft <= screen_max_ft);
das_in_screen = das_mean(screen_mask);

fprintf('\n=== PT-01b SCREEN INTERVAL (%.0f-%.0f ft) ===\n', screen_min_ft, screen_max_ft);
fprintf('Mean DAS in screen: %.5f nm/s\n', mean(das_in_screen, 'omitnan'));
fprintf('Min DAS in screen: %.5f nm/s\n', min(das_in_screen));
fprintf('Max DAS in screen: %.5f nm/s\n', max(das_in_screen));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_DAS_Profile_Final.las';
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
fprintf(fid, 'DAS_MEAN.NM : DAS Mean Displacement Rate (Recovery 19:29:30-19:32:30)\n');
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_MEAN\n');

% Write data
for i = 1:length(depth_ft)
    fprintf(fid, '%8.2f %12.5f\n', depth_ft(i), das_mean(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('LAS file created: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Data points: %d\n', length(depth_ft));

%% Plot for verification
figure('Name', 'PT01b Mean DAS Profile', 'Position', [100, 100, 500, 800]);
plot(das_mean, depth_ft, 'b-', 'LineWidth', 1.5);
hold on;

% Highlight screen interval
screen_x = [min(das_mean), max(das_mean)];
plot(screen_x, [screen_min_ft, screen_min_ft], 'r--', 'LineWidth', 2);
plot(screen_x, [screen_max_ft, screen_max_ft], 'r--', 'LineWidth', 2);

% Highlight screen data
plot(das_in_screen, depth_ft(screen_mask), 'r-', 'LineWidth', 3);

xlabel('Mean Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title(sprintf('PT-01b Mean DAS During Recovery\n(Screen: %.0f-%.0f ft)', ...
    screen_min_ft, screen_max_ft), ...
    'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'YDir', 'reverse');
grid on;
ylim([min(depth_ft), max(depth_ft)]);

fprintf('\nPlot displayed for verification\n');


