%PLOT_DEPTH_RANGE_260_310 Plot time series for depth range 260-310 ft
% 
% This creates a plot similar to the representative channel plot but for
% depth-averaged data over 260-310 ft range

%% Load data (assuming you've run correlation analysis)
% Make sure das_results and head_results are in workspace
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    error('Please run correlation analysis first to load das_results and head_results');
end

test_name = 'PT01c_Recovery_short';
depth_range_ft = [260, 310];

%% Extract DAS data
das_data = das_results.(test_name);
head_data = head_results.(test_name);

% Get full time and depth arrays
% Check which time field exists
if isfield(das_data, 'time_array')
    time_das = das_data.time_array;
elseif isfield(das_data, 'analysis_time')
    time_das = das_data.analysis_time;
else
    error('Cannot find time array in das_data');
end

depth_ft = das_data.depth_ft;
displacement_rate_full = das_data.smoothed_data;  % [time × depth] in nm/s

% Make sure dimensions match
if size(displacement_rate_full, 1) ~= length(time_das)
    error('Time array length (%d) does not match displacement rate rows (%d)', ...
        length(time_das), size(displacement_rate_full, 1));
end

% Find channels in depth range
depth_mask = depth_ft >= depth_range_ft(1) & depth_ft <= depth_range_ft(2);
channels_in_range = find(depth_mask);
n_channels = length(channels_in_range);

fprintf('Depth range: %.0f-%.0f ft\n', depth_range_ft(1), depth_range_ft(2));
fprintf('Channels in range: %d\n', n_channels);
fprintf('Channel depths: %.1f to %.1f ft\n', min(depth_ft(depth_mask)), max(depth_ft(depth_mask)));

% Average displacement rate across depth range
fprintf('Full displacement rate matrix size: [%d time points × %d channels]\n', ...
    size(displacement_rate_full, 1), size(displacement_rate_full, 2));
fprintf('Channels selected for averaging: %d channels\n', sum(depth_mask));

displacement_rate_avg = mean(displacement_rate_full(:, depth_mask), 2);  % Average across channels

fprintf('Averaged displacement rate size: [%d time points]\n', length(displacement_rate_avg));
fprintf('Averaged displacement rate range: %.3f to %.3f nm/s\n', ...
    min(displacement_rate_avg), max(displacement_rate_avg));

% Get analysis time window - use FULL time array, not filtered
% The full time_array should contain all time points
analysis_start = min(time_das);
analysis_end = max(time_das);
time_analysis = time_das;
displacement_analysis = displacement_rate_avg;

fprintf('Time range: %s to %s\n', datestr(analysis_start), datestr(analysis_end));
fprintf('Using FULL time array (not filtered to analysis window)\n');

%% Extract head data
zone_colors = containers.Map({'z4', 'z5'}, ...
    {[0.4940 0.1840 0.5560], [0.4660 0.6740 0.1880]});

%% Create plot
figure('Position', [100, 100, 1400, 600]);
set(gcf, 'Name', sprintf('Depth Range %.0f-%.0f ft - %s', depth_range_ft(1), depth_range_ft(2), upper(test_name)));

% Left axis: Drawdown rate
yyaxis left;
hold on;

for zone_name = {'z4', 'z5'}
    zone_name = zone_name{1};
    if isfield(head_data.zones, zone_name)
        zone_data = head_data.zones.(zone_name);
        if isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data)
            [drawdown_rate, rate_time] = calculate_drawdown_rate(zone_data.recovery_data.Date, ...
                zone_data.recovery_data.Drawdownft, 'ft_per_sec');  % Use ft/s to match new units
            
            if zone_colors.isKey(zone_name)
                zone_color = zone_colors(zone_name);
            else
                zone_color = [0 0 0];
            end
            
            plot(rate_time, drawdown_rate, ...
                'Color', zone_color, 'LineStyle', '-', 'LineWidth', 2.5, ...
                'DisplayName', sprintf('Drawdown Rate %s', zone_name));
        end
    end
end

hold off;
% Set specific time window for plot
plot_start = datetime(2023, 10, 24, 19, 14, 0, 'TimeZone', 'UTC');
plot_end = datetime(2023, 10, 24, 19, 19, 0, 'TimeZone', 'UTC');
xlim([plot_start, plot_end]);
xlabel('Date Time UTC', 'FontSize', 12);
ylabel('Drawdown Rate (ft/s)', 'FontSize', 12, 'FontWeight', 'bold');
legend('show', 'Location', 'best', 'FontSize', 10);
ax = gca;
ax.YColor = [0.4660 0.6740 0.1880];

% Right axis: DAS displacement rate (averaged)
yyaxis right;
plot(time_analysis, displacement_analysis, ...
    'Color', [0 0 0], 'LineStyle', '-', 'LineWidth', 2.5, ...
    'DisplayName', sprintf('DAS Avg (%.0f-%.0f ft, %d ch)', depth_range_ft(1), depth_range_ft(2), n_channels));
ylabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
ax.YColor = 'k';

title(sprintf('Depth Range %.0f-%.0f ft (%d channels) - %s', ...
    depth_range_ft(1), depth_range_ft(2), n_channels, upper(test_name)), ...
    'FontSize', 14, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 11);

fprintf('\nPlot created! Check alignment between drawdown rate and DAS signals.\n');
fprintf('If peaks don''t align, you may need to adjust timing correction.\n');

