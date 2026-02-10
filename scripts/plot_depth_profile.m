%% Depth Profile of Displacement Rate (averaged over regression window)
% Run AFTER run_PT01a_thesis_analysis.m (needs das_results in workspace)

if ~exist('das_results', 'var')
    error('Run the thesis analysis script first to populate das_results.');
end

% Auto-detect PT01a dataset
das_fields = fieldnames(das_results);
pt01a_idx = find(startsWith(das_fields, 'PT01a_Recovery'));
if isempty(pt01a_idx)
    error('No PT01a dataset found in das_results.');
end
test_name = das_fields{pt01a_idx(1)};
das_data = das_results.(test_name);

% Regression window
reg_start = datetime('2023-11-07 20:45:15', 'TimeZone', 'UTC');
reg_end   = datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC');

% Filter to regression window
reg_mask = das_data.time_array >= reg_start & das_data.time_array <= reg_end;
reg_data = das_data.smoothed_data(reg_mask, :);  % [time x channels]

% Average displacement rate across the regression window
mean_disp_rate = mean(reg_data, 1, 'omitnan');  % [1 x channels]

% Spatial smoothing across channels to reduce depth-profile noise
% 20-channel window = 5m at 0.25m/channel spacing
spatial_smooth_window = 20;
mean_disp_rate = movmean(mean_disp_rate, spatial_smooth_window);

% Depth in meters
depth_m = das_data.depth_ft * 0.3048;

% Screened interval
screened_top_m = 450 * 0.3048;  % 137.2 m
screened_bot_m = 510 * 0.3048;  % 155.4 m

% Depth display range (match waterfall plots)
depth_bounds = get_plot_bounds([], 'depth_axis', config(), test_name);
depth_bounds_m = depth_bounds * 0.3048;

%% Plot
figure('Name', 'Depth Profile - Displacement Rate', 'Position', [100 100 600 800]);

plot(mean_disp_rate, depth_m, 'b-', 'LineWidth', 1.2);
hold on;

% Mark screened interval
yline(screened_top_m, '--k', 'LineWidth', 1.2);
yline(screened_bot_m, '--k', 'LineWidth', 1.2);
fill([min(xlim) max(xlim) max(xlim) min(xlim)], ...
     [screened_top_m screened_top_m screened_bot_m screened_bot_m], ...
     [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');

% Redraw the profile on top of the shading
plot(mean_disp_rate, depth_m, 'b-', 'LineWidth', 1.2);

hold off;

set(gca, 'YDir', 'reverse');  % Depth increases downward
ylim(depth_bounds_m);
xlim([0.2, 0.5]);
xlabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Depth (m)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Depth Profile - Mean Displacement Rate\n%s to %s UTC', ...
    datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS')), 'FontSize', 13);

% Label screened interval
text(max(xlim)*0.98, mean([screened_top_m screened_bot_m]), ...
    sprintf('Screened Interval\n(%.0f–%.0f m)', screened_top_m, screened_bot_m), ...
    'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'middle');

grid on;
fprintf('Regression window: %d time points averaged\n', sum(reg_mask));
fprintf('Depth range displayed: %.0f to %.0f m\n', depth_bounds_m(1), depth_bounds_m(2));
