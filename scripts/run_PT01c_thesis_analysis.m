%% PT-01c Recovery Analysis for Thesis
% This script runs the complete DAS-Head correlation and linear regression analysis
% for PT-01c Recovery test data (100Hz)
%
% PT-01c parameters:
%   - 100Hz DAS data with 50-second movmean filter (5000 samples)
%   - Analysis window: 19:14:00 to 19:19:00 UTC (Oct 24, 2023)
%   - Regression window: 19:15:00 to 19:16:15 UTC (peak region)
%   - Depth range: 260-310 ft (PT-01c pumping zone)
%   - Screen: 79.25-94.49 m
%   - Calibration: C1=513, MperChan=0.25
%
% Usage:
%   cd('C:\Coding\BGWRP'); run('scripts\run_PT01c_thesis_analysis.m')

clear all;
close all;
clc;

% Initialize console logging (overwrites same file each run)
log_dir = fullfile('C:', 'Coding', 'BGWRP', 'data', '_BATCH', '_log');
if ~exist(log_dir, 'dir')
    mkdir(log_dir);
end
log_path = fullfile(log_dir, 'console_log.txt');

% Add src to path for console_log
script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(script_dir);
addpath(genpath(fullfile(parent_dir, 'src')));

console_log('init', log_path);

try
    console_log('\n=== PT-01c RECOVERY ANALYSIS FOR THESIS (100Hz Data) ===\n');
    console_log('Starting analysis...\n\n');

    %% STEP 1: Run Correlation Analysis
    console_log('STEP 1/2: Running correlation analysis...\n');
    console_log('  - Loading 100Hz DAS data\n');
    console_log('  - 50-second movmean filter (5000 samples at 100Hz)\n');
    console_log('  - Processing head data\n');
    console_log('  - Analysis window: 19:14:00 to 19:19:00 UTC (Oct 24, 2023)\n\n');
    
    mode = 'run_correlation_analysis';
    
    BGWRP_Toolkit;
    
    console_log('\n Correlation analysis complete!\n\n');
    pause(2);
    
    %% STEP 2: Run ROI Linear Regression Analysis
    console_log('STEP 2/2: Running ROI linear regression analysis...\n');
    console_log('  - Depth range: 260-310 ft (PT-01c pumping zone)\n');
    console_log('  - Regression window: 19:15:00 to 19:16:15 UTC\n\n');
    
    run_roi_analysis_PT01c;
    
    console_log('\n=== ANALYSIS COMPLETE ===\n');
    console_log('Results saved to workspace as ''roi_results''\n');
    console_log('Key metrics:\n');
    console_log('  - R squared: %.3f\n', roi_results.R_squared);
    console_log('  - Slope: %.2e\n', roi_results.slope);
    console_log('  - Correlation (R): %.3f\n', roi_results.R);
    console_log('  - RMSE: %.2e 1/s\n', roi_results.RMSE);

    %% STEP 3: Depth Profile Plot
    console_log('\nGenerating depth profile plot...\n');
    
    das_data_dp = das_results.(test_name);
    
    % Average displacement rate over regression window
    reg_start = datetime('2023-10-24 19:15:00', 'TimeZone', 'UTC');
    reg_end   = datetime('2023-10-24 19:16:15', 'TimeZone', 'UTC');
    reg_mask = das_data_dp.time_array >= reg_start & das_data_dp.time_array <= reg_end;
    mean_disp_rate = mean(das_data_dp.smoothed_data(reg_mask, :), 1, 'omitnan');
    
    % Spatial smoothing (60 channels = 15m at 0.25m/channel)
    mean_disp_rate = movmean(mean_disp_rate, 60);
    
    % Depth in meters
    depth_m = das_data_dp.depth_ft * 0.3048;
    screened_top_m = 260 * 0.3048;  % 79.25 m
    screened_bot_m = 310 * 0.3048;  % 94.49 m
    depth_bounds = get_plot_bounds([], 'depth_axis', config(), test_name);
    depth_bounds_m = depth_bounds * 0.3048;
    
    figure(104);
    set(104, 'Visible', 'on');
    clf;
    
    plot(mean_disp_rate, depth_m, 'b-', 'LineWidth', 1.2);
    hold on;
    yline(screened_top_m, '--k', 'LineWidth', 1.2);
    yline(screened_bot_m, '--k', 'LineWidth', 1.2);
    fill([min(xlim) max(xlim) max(xlim) min(xlim)], ...
         [screened_top_m screened_top_m screened_bot_m screened_bot_m], ...
         [0.9 0.9 0.9], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    plot(mean_disp_rate, depth_m, 'b-', 'LineWidth', 1.2);
    hold off;
    
    set(gca, 'YDir', 'reverse');
    ylim(depth_bounds_m);
    xlabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Depth (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Depth Profile - Mean Displacement Rate\n%s to %s UTC', ...
        datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS')), 'FontSize', 13);
    text(max(xlim)*0.98, mean([screened_top_m screened_bot_m]), ...
        sprintf('Screened Interval\n(%.0f-%.0f m)', screened_top_m, screened_bot_m), ...
        'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'middle');
    grid on;
    
    console_log('  Figure 104: Depth profile (%d time points averaged)\n', sum(reg_mask));
    
    console_log('\nFigures generated:\n');
    console_log('  - Figure 101: DAS Raw Data (waterfall)\n');
    console_log('  - Figure 102: Displacement Rate with monitoring wells\n');
    console_log('  - Figure 104: Depth profile of displacement rate\n');
    console_log('  - Figure: 4-subplot regression analysis\n');
    console_log('\nAll plots ready for thesis!\n');
    
catch ME
    console_log('\nERROR: %s\n', ME.message);
    if ~isempty(ME.stack)
        console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    console_log('close');
    rethrow(ME);
end

% Normal completion - close log
console_log('close');
