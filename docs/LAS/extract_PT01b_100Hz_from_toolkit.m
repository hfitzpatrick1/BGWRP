% Extract PT-01b 100Hz displacement rate from toolkit output and export to LAS
% Run this AFTER running run_PT01b_thesis_analysis.m (needs das_results in workspace)
%
% Usage:
%   1. First run: cd('C:\Coding\BGWRP'); run('scripts\run_PT01b_thesis_analysis.m')
%   2. Then run:  run('docs\LAS\extract_PT01b_100Hz_from_toolkit.m')

%% Check that das_results exist in workspace
if ~exist('das_results', 'var')
    error('das_results not found. Run run_PT01b_thesis_analysis.m first.');
end

% Find PT01b dataset
das_fields = fieldnames(das_results);
pt01b_idx = find(startsWith(das_fields, 'PT01b_Recovery'));
if isempty(pt01b_idx)
    error('No PT01b_Recovery dataset found in das_results.');
end
test_name = das_fields{pt01b_idx(1)};
fprintf('Using dataset: %s\n', test_name);

das_data = das_results.(test_name);

%% Extract depth and displacement rate data
depth_ft = das_data.depth_ft;

% Average displacement rate over regression window (same as depth profile plot)
reg_start = datetime('2023-10-31 19:30:10', 'TimeZone', 'UTC');
reg_end   = datetime('2023-10-31 19:31:25', 'TimeZone', 'UTC');
reg_mask = das_data.time_array >= reg_start & das_data.time_array <= reg_end;
mean_disp_rate = mean(das_data.smoothed_data(reg_mask, :), 1, 'omitnan')';

% Spatial smoothing (60 channels = 15m at 0.25m/channel) - matches Figure 104
mean_disp_rate = movmean(mean_disp_rate, 60);

fprintf('\n=== PT-01b 100Hz MEAN DISPLACEMENT RATE ===\n');
fprintf('Regression window: %s to %s UTC\n', datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS'));
fprintf('Time points averaged: %d\n', sum(reg_mask));
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Rate range: %.5f to %.5f nm/s\n', min(mean_disp_rate), max(mean_disp_rate));
fprintf('Overall mean: %.5f nm/s\n', mean(mean_disp_rate, 'omitnan'));

% Check PT-01b screen interval
screen_min = 350;
screen_max = 400;
screen_mask = (depth_ft >= screen_min) & (depth_ft <= screen_max);

fprintf('\n=== PT-01b SCREEN (%.0f-%.0f ft) ===\n', screen_min, screen_max);
fprintf('Mean: %.5f nm/s\n', mean(mean_disp_rate(screen_mask), 'omitnan'));
fprintf('Min: %.5f nm/s\n', min(mean_disp_rate(screen_mask)));
fprintf('Max: %.5f nm/s\n', max(mean_disp_rate(screen_mask)));

%% Write LAS file
output_file = 'C:\Coding\BGWRP\docs\LAS\PT01b_DAS_Profile_100Hz.las';
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
fprintf(fid, 'WELL. PT01b_Recovery_100Hz:\n');
fprintf(fid, 'DATE. %s:\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '\n');

fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth below casing\n');
fprintf(fid, 'DAS_MEAN.NM/S : DAS Mean Displacement Rate (Recovery %s-%s)\n', ...
    datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS'));
fprintf(fid, '\n');

fprintf(fid, '~A  DEPT  DAS_MEAN\n');

% Write data
for i = 1:length(depth_ft)
    fprintf(fid, '%10.2f %12.5f\n', depth_ft(i), mean_disp_rate(i));
end

fclose(fid);

fprintf('\n=== EXPORT COMPLETE ===\n');
fprintf('Output: %s\n', output_file);
fprintf('Depth range: %.2f to %.2f ft\n', min(depth_ft), max(depth_ft));
fprintf('Points: %d\n', length(depth_ft));

%% Verification plot
figure('Position', [100 100 600 800]);
plot(mean_disp_rate, depth_ft, 'b-', 'LineWidth', 2);
hold on;
plot(mean_disp_rate(screen_mask), depth_ft(screen_mask), 'r-', 'LineWidth', 3);
yline(screen_min, 'r--', 'LineWidth', 1.5);
yline(screen_max, 'r--', 'LineWidth', 1.5);
set(gca, 'YDir', 'reverse');
xlabel('Mean Displacement Rate (nm/s)', 'FontSize', 12);
ylabel('Depth (ft)', 'FontSize', 12);
title('PT-01b Mean Displacement Rate - 100Hz (from Toolkit)', 'FontSize', 14);
grid on;
ylim([min(depth_ft) max(depth_ft)]);
legend('All Depths', 'Screen Interval', 'Location', 'best');

fprintf('\nThis data matches the depth profile in Figure 104.\n');
