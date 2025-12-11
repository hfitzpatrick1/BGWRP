%% SIMPLE STANDALONE LINEAR REGRESSION SCRIPT
% This script loads pre-processed DAS and pressure data and generates
% individual publication-quality figures for poster/presentation
%
% Prerequisites: Data must be already processed (in data/_BATCH/_active/)
%
% Outputs:
%   - Figure 100: Linear Regression Scatter Plot
%   - Figure 101: Time Series (Strain Rate and Drawdown Rate)
%
% Usage:
%   1. Make sure BGWRP_Toolkit has been run for PT01c_Recovery_short
%   2. Run this script: run_linear_regression_simple
%   3. Figures will be generated and saved

clear; clc;
close all;

%% Add paths
addpath(genpath('src'));

%% Configuration
fprintf('\n=== STANDALONE LINEAR REGRESSION ANALYSIS ===\n');
fprintf('Loading pre-processed data and running analysis...\n\n');

% Test configuration
test_name = 'PT01c_Recovery_short';
zone_name = 'z5';

% Load configuration
cfg = config();

% Paths to pre-processed data
das_data_file = fullfile(cfg.base_input, '_active', test_name, '_das', ['Dataset_' test_name '_1Hz.mat']);
head_data_file = fullfile(cfg.base_input, '_combined_head', test_name, 'head_data.mat');

% Check if files exist
if ~exist(das_data_file, 'file')
    error('DAS data file not found: %s\nPlease run BGWRP_Toolkit first with mode=''run_correlation_analysis''', das_data_file);
end
if ~exist(head_data_file, 'file')
    error('Head data file not found: %s\nPlease process head data first', head_data_file);
end

fprintf('Loading data files:\n');
fprintf('  DAS: %s\n', das_data_file);
fprintf('  Head: %s\n', head_data_file);

%% Load DAS Data
fprintf('\nLoading DAS data...\n');
das_data = load(das_data_file);
fprintf('  ✓ DAS data loaded\n');

%% Load Head Data
fprintf('Loading head data...\n');
head_data = load(head_data_file);
fprintf('  ✓ Head data loaded\n');

%% Build das_results and head_results structures
fprintf('\nBuilding analysis structures...\n');

% Get timing information
timing_file = fullfile(cfg.base_input, '_configs', ['get_timing_' test_name '.m']);
if exist(timing_file, 'file')
    run(timing_file);
    timing_info = get_timing();
else
    error('Timing configuration not found: %s', timing_file);
end

% Build das_results structure
das_results = struct();
das_results.tests = {test_name};
das_results.timing = timing_info;

% Get analysis window from config
if isfield(cfg.analysis_windows, test_name)
    analysis_start = cfg.analysis_windows.(test_name).start;
    analysis_end = cfg.analysis_windows.(test_name).end;
else
    error('Analysis window not found for test: %s', test_name);
end

% Filter DAS data to analysis window
time_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
das_results.(test_name).analysis_time = das_data.time_array(time_mask);
das_results.(test_name).smoothed_data = das_data.smoothed_data(time_mask, :);
das_results.(test_name).time_array = das_data.time_array(time_mask);
das_results.(test_name).depth_ft = das_data.depth_ft;

% Add pumping zone information (PM-07 Zone 5: approximately 250-350 ft)
zone5_depth_min_ft = 250;
zone5_depth_max_ft = 350;
zone5_channels = find(das_data.depth_ft >= zone5_depth_min_ft & das_data.depth_ft <= zone5_depth_max_ft);
das_results.(test_name).pumping_zone.channel_idx = zone5_channels(round(length(zone5_channels)/2));  % Center channel

fprintf('  DAS time range: %s to %s\n', datestr(das_results.(test_name).analysis_time(1)), ...
    datestr(das_results.(test_name).analysis_time(end)));
fprintf('  DAS channels: %d\n', length(das_data.depth_ft));
fprintf('  Zone 5 channels: %d (depths %.1f-%.1f ft)\n', length(zone5_channels), zone5_depth_min_ft, zone5_depth_max_ft);

% Build head_results structure
head_results = struct();
head_results.(test_name).zones = struct();

% Load Zone 5 data
if isfield(head_data, zone_name)
    zone_data = head_data.(zone_name);
    
    % Filter to recovery period
    recovery_mask = zone_data.Date >= analysis_start & zone_data.Date <= analysis_end;
    
    head_results.(test_name).zones.(zone_name).recovery_data.Date = zone_data.Date(recovery_mask);
    head_results.(test_name).zones.(zone_name).recovery_data.Drawdownft = zone_data.Drawdownft(recovery_mask);
    
    fprintf('  Head time range: %s to %s\n', datestr(zone_data.Date(1)), datestr(zone_data.Date(end)));
    fprintf('  Head points in recovery window: %d\n', sum(recovery_mask));
else
    error('Zone %s data not found in head data file', zone_name);
end

%% Linear Regression Configuration
fprintf('\nConfiguring linear regression...\n');

lr_config.timing_correction_sec = 13;  % 13-second shift (GPS vs laptop clock offset)
lr_config.zone = zone_name;
lr_config.show_plots = false;  % We'll make our own plots
lr_config.use_displacement_rate = false;  % Use strain rate

% Recovery window (focused on peak signal)
lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                             datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];

% Depth range for PM-07 Zone 5: 76-107 m (from thesis figure)
depth_min_m = 76;
depth_max_m = 107;
depth_min_ft = depth_min_m / 0.3048;  % ~249 ft
depth_max_ft = depth_max_m / 0.3048;  % ~351 ft

lr_config.depth_range_ft = [depth_min_ft, depth_max_ft];
lr_config.depth_averaging_method = 'mean';  % Average across depth range
lr_config.strain_rate_smoothing_window = 5;  % 5-second smoothing
lr_config.strain_rate_smoothing_method = 'movmean';
lr_config.head_rate_smoothing_window = 5;  % Match strain rate smoothing

fprintf('  Timing correction: %d seconds\n', lr_config.timing_correction_sec);
fprintf('  Depth range: %.1f - %.1f m (%.1f - %.1f ft)\n', depth_min_m, depth_max_m, depth_min_ft, depth_max_ft);
fprintf('  Recovery window: %s to %s\n', datestr(lr_config.recovery_window(1)), datestr(lr_config.recovery_window(2)));

%% Run Linear Regression
fprintf('\n=== RUNNING LINEAR REGRESSION ===\n');
lr_results = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config);

fprintf('\n=== REGRESSION RESULTS ===\n');
fprintf('Slope: %.4e (1/s)/(m/s)\n', lr_results.slope);
fprintf('R: %.3f\n', lr_results.R);
fprintf('R²: %.3f\n', lr_results.R_squared);
fprintf('RMSE: %.4e 1/s\n', lr_results.RMSE);
fprintf('N points: %d\n', lr_results.n_points);

%% Calculate Storage Parameters
fprintf('\n=== STORAGE PARAMETER CALCULATION ===\n');

% Biot-Willis coefficient (from thesis)
alpha = 0.90;  % For unconsolidated sediments
gamma_w = 9810;  % N/m³ (specific weight of water)

% Poroelastic storage from slope
S_epsilon = lr_results.slope * (alpha / gamma_w);  % 1/Pa
S_s = S_epsilon * gamma_w;  % Specific storage (1/m)

fprintf('Biot-Willis coefficient (α): %.2f\n', alpha);
fprintf('Specific weight of water (γ): %.0f N/m³\n', gamma_w);
fprintf('Poroelastic storage (Sε): %.4e 1/Pa\n', S_epsilon);
fprintf('Specific storage (Ss): %.4e 1/m\n', S_s);

%% Generate Standalone Figures

% Output directory
output_dir = fullfile('output', 'Linear_Regression_Standalone');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
fprintf('\nSaving figures to: %s\n', output_dir);

%% FIGURE 100: Linear Regression Scatter Plot
fprintf('\nGenerating Figure 100: Linear Regression Scatter...\n');
fig100 = figure(100); clf;
set(fig100, 'Position', [100 100 900 800], 'Color', 'white');
set(fig100, 'Name', 'Poroelastic Storage Analysis: PT-01c Zone 5 (76-107 m) - Linear Regression');

% Scatter plot with regression line
scatter(lr_results.head_rate, lr_results.strain_rate, 35, 'b', 'filled', 'MarkerFaceAlpha', 0.7);
hold on;

% Regression line
head_rate_range = linspace(min(lr_results.head_rate), max(lr_results.head_rate), 100);
strain_predicted = lr_results.intercept + lr_results.slope * head_rate_range;
plot(head_rate_range, strain_predicted, 'r-', 'LineWidth', 3);

% Labels and formatting
xlabel('Drawdown Rate (m/s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Strain Rate (1/s)', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('Linear Regression: R = %.3f, R^2 = %.3f', lr_results.R, lr_results.R_squared), ...
    'FontSize', 16, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

% Legend with fit equation
legend_str = {
    'Data', 
    sprintf('Fit: y = %.2e·x + %.2e', lr_results.slope, lr_results.intercept)
};
legend(legend_str, 'Location', 'best', 'FontSize', 11);

% Statistics text box (matching thesis layout)
% Estimate number of channels in depth range
n_channels = round((depth_max_ft - depth_min_ft) / 0.82);  % 0.82 ft = 0.25 m per channel

text_str = sprintf(['Slope: %.2e\n' ...
                    'R: %.3f\n' ...
                    'R²: %.3f\n' ...
                    'RMSE: %.2e\n' ...
                    'N: %d\n' ...
                    'Depth: %.0f-%.0f m\n' ...
                    'Channels: %d'], ...
    lr_results.slope, ...
    lr_results.R, ...
    lr_results.R_squared, ...
    lr_results.RMSE, ...
    lr_results.n_points, ...
    depth_min_m, depth_max_m, ...
    n_channels);

text(0.05, 0.95, text_str, ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'LineWidth', 1.5, ...
    'FontSize', 11, ...
    'FontName', 'Arial');

hold off;

% Save figure
saveas(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.png'));
saveas(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.svg'));
savefig(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.fig'));
fprintf('  ✓ Saved Figure 100\n');

%% FIGURE 101: Time Series (Strain Rate and Drawdown Rate)
fprintf('Generating Figure 101: Time Series...\n');
fig101 = figure(101); clf;
set(fig101, 'Position', [150 150 1200 600], 'Color', 'white');
set(fig101, 'Name', sprintf('Time Series (13s correction) - Depth %.0f-%.0f m', depth_min_m, depth_max_m));

% Determine appropriate scaling
strain_scale = 1e-11;  % Display strain rate in units of 10^-11 1/s
head_scale = 1e-4;     % Display drawdown rate in units of 10^-4 m/s

% Left axis: Drawdown Rate (green)
yyaxis left;
plot(lr_results.time, lr_results.head_rate / head_scale, ...
    'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2.5, 'DisplayName', 'Drawdown Rate');
ylabel(sprintf('Drawdown Rate (m/s) ×10^{%d}', round(log10(head_scale))), ...
    'FontSize', 14, 'FontWeight', 'bold');
ax = gca;
ax.YColor = [0.4660 0.6740 0.1880];

% Right axis: Strain Rate (black)
yyaxis right;
plot(lr_results.time, lr_results.strain_rate / strain_scale, ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
ylabel(sprintf('Strain Rate (1/s) ×10^{%d}', round(log10(strain_scale))), ...
    'FontSize', 14, 'FontWeight', 'bold');
ax.YColor = 'k';

% Formatting
xlabel('Date Time UTC', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('Time Series (%ds correction) - Depth %.0f-%.0f m', ...
    lr_config.timing_correction_sec, depth_min_m, depth_max_m), ...
    'FontSize', 16, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

% Legend
legend('show', 'Location', 'best', 'FontSize', 11);

% Format time axis
datetick('x', 'HH:MM:SS', 'keepticks');

% Save figure
saveas(fig101, fullfile(output_dir, 'Fig101_Time_Series.png'));
saveas(fig101, fullfile(output_dir, 'Fig101_Time_Series.svg'));
savefig(fig101, fullfile(output_dir, 'Fig101_Time_Series.fig'));
fprintf('  ✓ Saved Figure 101\n');

%% Summary
fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Generated figures:\n');
fprintf('  - Figure 100: Linear Regression Scatter Plot\n');
fprintf('  - Figure 101: Time Series (Strain Rate and Drawdown Rate)\n');
fprintf('\nFigures saved to:\n  %s\n', output_dir);
fprintf('\nFile formats:\n');
fprintf('  - PNG (high resolution, for PowerPoint/Word)\n');
fprintf('  - SVG (vector graphics, for Adobe Illustrator/Inkscape)\n');
fprintf('  - FIG (MATLAB format, for further editing)\n');
fprintf('\n✓ Script complete!\n\n');








