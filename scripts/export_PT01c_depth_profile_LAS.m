%% Export PT01c Depth Profile to LAS file for WellCAD
% Run AFTER run_PT01c_thesis_analysis.m (needs das_results in workspace)

if ~exist('das_results', 'var')
    error('Run the thesis analysis script first to populate das_results.');
end

% Auto-detect PT01c dataset
das_fields = fieldnames(das_results);
pt01c_idx = find(startsWith(das_fields, 'PT01c_Recovery'));
if isempty(pt01c_idx)
    error('No PT01c dataset found in das_results.');
end
test_name_las = das_fields{pt01c_idx(1)};
das_data_las = das_results.(test_name_las);

% Regression window (same as run_roi_analysis_PT01c.m)
reg_start = datetime('2023-10-24 19:15:00', 'TimeZone', 'UTC');
reg_end   = datetime('2023-10-24 19:16:15', 'TimeZone', 'UTC');

% Filter to regression window and average
reg_mask = das_data_las.time_array >= reg_start & das_data_las.time_array <= reg_end;
mean_disp_rate = mean(das_data_las.smoothed_data(reg_mask, :), 1, 'omitnan');

% Spatial smoothing (60 channels = 15m at 0.25m/channel, same as depth profile plot)
mean_disp_rate = movmean(mean_disp_rate, 60);

% Depth in feet
depth_ft = das_data_las.depth_ft(:);
mean_disp_rate = mean_disp_rate(:);

% Calculate step size
step_ft = median(diff(depth_ft));

% Output file
output_dir = fullfile('C:', 'Coding', 'BGWRP', 'docs', 'LAS');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
output_file = fullfile(output_dir, 'PT01c_DAS_Profile_100Hz.las');

% Write LAS file
fid = fopen(output_file, 'w');
if fid == -1
    error('Cannot open file for writing: %s', output_file);
end

% Version section
fprintf(fid, '~Version Information\n');
fprintf(fid, 'VERS. 2.0:\n');
fprintf(fid, 'WRAP. NO:\n');
fprintf(fid, '\n');

% Well section
fprintf(fid, '~Well Information\n');
fprintf(fid, 'STRT.FT %.2f:\n', depth_ft(1));
fprintf(fid, 'STOP.FT %.2f:\n', depth_ft(end));
fprintf(fid, 'STEP.FT %.3f:\n', step_ft);
fprintf(fid, 'NULL. -999.25:\n');
fprintf(fid, 'WELL. PT01c_Recovery_100Hz:\n');
fprintf(fid, 'DATE. %s:\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '\n');

% Curve section
fprintf(fid, '~Curve Information\n');
fprintf(fid, 'DEPT.FT     : Depth below casing\n');
fprintf(fid, 'DAS_MEAN.NM/S : DAS Mean Displacement Rate (Recovery %s-%s, 60ch smoothed)\n', ...
    datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS'));
fprintf(fid, '\n');

% Data section
fprintf(fid, '~A  DEPT  DAS_MEAN\n');
for i = 1:length(depth_ft)
    fprintf(fid, '%10.2f  %12.5f\n', depth_ft(i), mean_disp_rate(i));
end

fclose(fid);

fprintf('LAS file saved to: %s\n', output_file);
fprintf('  Depth range: %.2f to %.2f ft (step %.3f ft)\n', depth_ft(1), depth_ft(end), step_ft);
fprintf('  Channels: %d\n', length(depth_ft));
fprintf('  Regression window: %s to %s UTC\n', datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS'));
fprintf('  Spatial smoothing: 60 channels (15m)\n');
