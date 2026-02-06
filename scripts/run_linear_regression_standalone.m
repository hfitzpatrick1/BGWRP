%% STANDALONE LINEAR REGRESSION SCRIPT WITH SEPARATE FIGURE OUTPUTS
% This script runs the linear regression analysis and generates each subplot
% as a separate standalone figure for easier poster/presentation use
%
% Outputs:
%   - Figure 100: Linear Regression Scatter Plot
%   - Figure 101: Time Series (Strain Rate and Drawdown Rate)
%   
% Usage:
%   1. Make sure you have run the batch processor first to generate:
%      - das_results
%      - head_results
%   2. Run this script
%   3. Figures will be saved to the chart output directory

clear; clc;

%% Configuration
console_log('\n=== STANDALONE LINEAR REGRESSION ANALYSIS ===\n');

% Load configuration
cfg = config();

% Test to analyze
test_name = 'PT01c_Recovery_short';
zone = 'z5';

% Linear regression configuration
lr_config.timing_correction_sec = 13;  % 13-second shift to correct GPS vs laptop clock offset
lr_config.zone = zone;
lr_config.show_plots = false;  % We'll make our own plots
lr_config.use_displacement_rate = false;  % Use strain rate (not displacement rate)

% Add focused recovery window (same as analysis window)
lr_config.recovery_window = [datetime('2023-10-24 19:14:00', 'TimeZone', 'UTC'), ...
                             datetime('2023-10-24 19:17:00', 'TimeZone', 'UTC')];

% Depth range for PM-07 Zone 5 (76-107 m depth in thesis = ~250-350 ft)
% Let's use the exact range from your figure title: 76-107 m
depth_min_m = 76;
depth_max_m = 107;
depth_min_ft = depth_min_m / 0.3048;  % ~249 ft
depth_max_ft = depth_max_m / 0.3048;  % ~351 ft

lr_config.depth_range_ft = [depth_min_ft, depth_max_ft];
lr_config.depth_averaging_method = 'mean';  % Average across depth range
lr_config.strain_rate_smoothing_window = 5;  % 5-second smoothing
lr_config.strain_rate_smoothing_method = 'movmean';
lr_config.head_rate_smoothing_window = 5;  % Match strain rate smoothing

%% Load Data
console_log('\nLoading DAS and pressure data...\n');

% Check if data is already in workspace
if ~exist('das_results', 'var') || ~exist('head_results', 'var')
    console_log('⚠ Warning: das_results or head_results not found in workspace\n');
    console_log('   You need to run the batch processor first.\n');
    console_log('   Running batch processor now...\n\n');
    
    % Run batch processor to generate data
    addpath(fullfile(pwd, 'src'));
    addpath(fullfile(pwd, 'src', 'analyze'));
    addpath(fullfile(pwd, 'src', 'load'));
    addpath(fullfile(pwd, 'src', 'plot'));
    addpath(fullfile(pwd, 'src', 'process'));
    addpath(fullfile(pwd, 'src', 'util'));
    
    % Set batch processor configuration
    cfg.correlation_analysis = true;
    cfg.linear_regression = false;  % We'll run our own
    cfg.save_charts = true;
    
    % Run batch processor for this test
    console_log('Processing test: %s\n', test_name);
    [das_results, head_results] = batch_processor(test_name, cfg);
    
    console_log('\n✓ Batch processing complete\n');
end

%% Run Linear Regression
console_log('\nRunning linear regression analysis...\n');
console_log('  Test: %s\n', test_name);
console_log('  Zone: %s\n', zone);
console_log('  Timing correction: %d seconds\n', lr_config.timing_correction_sec);
console_log('  Depth range: %.1f - %.1f ft (%.1f - %.1f m)\n', ...
    depth_min_ft, depth_max_ft, depth_min_m, depth_max_m);

% Perform linear regression
lr_results = linear_regression_strain_drawdown(das_results, head_results, test_name, lr_config);

console_log('\n=== REGRESSION RESULTS ===\n');
console_log('Slope: %.4e (1/s)/(m/s)\n', lr_results.slope);
console_log('R: %.3f\n', lr_results.R);
console_log('R²: %.3f\n', lr_results.R_squared);
console_log('RMSE: %.4e 1/s\n', lr_results.RMSE);
console_log('N points: %d\n', lr_results.n_points);

%% Generate Standalone Figures

% Output directory
if cfg.save_charts
    output_dir = fullfile(cfg.chart_output_dir, test_name, 'Linear_Regression_Standalone');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    console_log('\nSaving figures to: %s\n', output_dir);
end

%% FIGURE 100: Linear Regression Scatter Plot
console_log('\nGenerating Figure 100: Linear Regression Scatter...\n');
fig100 = figure(100); clf;
set(fig100, 'Position', [100 100 800 700], 'Color', 'white');
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

% Format to match thesis figure
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

% Legend with fit equation
legend_str = {
    'Data', 
    sprintf('Fit: y = %.2e*x + %.2e', lr_results.slope, lr_results.intercept)
};
legend(legend_str, 'Location', 'best', 'FontSize', 11);

% Statistics text box (matching thesis layout)
text_str = sprintf(['Slope: %.2e-07\n' ...
                    'R: %.3f\n' ...
                    'R^2: %.3f\n' ...
                    'RMSE: %.2e-12\n' ...
                    'N: %d\n' ...
                    'Depth: 76-107 m\n' ...
                    'Channels: %d'], ...
    lr_results.slope * 1e7, ...  % Display in scientific notation
    lr_results.R, ...
    lr_results.R_squared, ...
    lr_results.RMSE * 1e12, ...  % Display in scientific notation
    lr_results.n_points, ...
    length([depth_min_ft:0.25:depth_max_ft]));  % Approximate channel count

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
if cfg.save_charts
    % Save as high-resolution PNG
    saveas(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.png'));
    % Save as vector graphics (SVG)
    saveas(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.svg'));
    % Save as MATLAB figure
    savefig(fig100, fullfile(output_dir, 'Fig100_Linear_Regression_Scatter.fig'));
    console_log('  ✓ Saved Figure 100\n');
end

%% FIGURE 101: Time Series (Strain Rate and Drawdown Rate)
console_log('Generating Figure 101: Time Series...\n');
fig101 = figure(101); clf;
set(fig101, 'Position', [150 150 1000 600], 'Color', 'white');
set(fig101, 'Name', 'Time Series (13s correction) - Depth 76-107 m');

% Determine appropriate scaling for display
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
ylim_left = ylim;

% Right axis: Strain Rate (black)
yyaxis right;
plot(lr_results.time, lr_results.strain_rate / strain_scale, ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'DisplayName', 'Strain Rate');
ylabel(sprintf('Strain Rate (1/s) ×10^{%d}', round(log10(strain_scale))), ...
    'FontSize', 14, 'FontWeight', 'bold');
ax.YColor = 'k';

% Formatting
xlabel('Date Time UTC', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('Time Series (13s correction) - Depth 76-107 m', lr_config.timing_correction_sec), ...
    'FontSize', 16, 'FontWeight', 'bold');
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);

% Legend
legend('show', 'Location', 'best', 'FontSize', 11);

% Date formatting for X-axis
ax = gca;
ax.XAxis.TickLabelFormat = 'HH:mm:ss';
datetick('x', 'HH:MM:SS', 'keepticks', 'keeplimits');

% Save figure
if cfg.save_charts
    saveas(fig101, fullfile(output_dir, 'Fig101_Time_Series.png'));
    saveas(fig101, fullfile(output_dir, 'Fig101_Time_Series.svg'));
    savefig(fig101, fullfile(output_dir, 'Fig101_Time_Series.fig'));
    console_log('  ✓ Saved Figure 101\n');
end

%% Display Summary
console_log('\n=== ANALYSIS COMPLETE ===\n');
console_log('Generated figures:\n');
console_log('  - Figure 100: Linear Regression Scatter Plot\n');
console_log('  - Figure 101: Time Series (Strain Rate and Drawdown Rate)\n');

if cfg.save_charts
    console_log('\nFigures saved to:\n  %s\n', output_dir);
    console_log('\nFile formats:\n');
    console_log('  - PNG (high resolution, for PowerPoint/Word)\n');
    console_log('  - SVG (vector graphics, for Adobe Illustrator/Inkscape)\n');
    console_log('  - FIG (MATLAB format, for further editing)\n');
end

%% Calculate Storage Parameters
console_log('\n=== STORAGE PARAMETER CALCULATION ===\n');

% Biot-Willis coefficient (from thesis)
alpha = 0.90;  % For unconsolidated sediments

% Specific weight of water
gamma_w = 9810;  % N/m³

% Poroelastic storage from slope
S_epsilon = lr_results.slope * (alpha / gamma_w);  % 1/Pa
S_s = S_epsilon * gamma_w;  % Specific storage (1/m)

console_log('Biot-Willis coefficient (α): %.2f\n', alpha);
console_log('Specific weight of water (γ): %.0f N/m³\n', gamma_w);
console_log('Poroelastic storage (Sε): %.4e 1/Pa\n', S_epsilon);
console_log('Specific storage (Ss): %.4e 1/m\n', S_s);

console_log('\n✓ Script complete!\n\n');

