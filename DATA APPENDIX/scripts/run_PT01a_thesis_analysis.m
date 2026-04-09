%% PT-01a Recovery Analysis for Thesis
% This script runs the complete DAS-Head correlation and linear regression analysis
% for PT-01a Recovery test data (100Hz)
%
% Current settings (as of Feb 2026):
%   - 100Hz DAS data with 50-second movmean filter (5000 samples)
%   - DAS time shift: +38 seconds forward
%   - Head timing correction: 14 seconds backward (in run_roi_analysis.m)
%   - Analysis window: 20:44:30 to 20:47:30 UTC (Nov 7, 2023)
%   - Regression window: 20:45:15 to 20:46:30 UTC (peak region)
%   - Depth range: 450-510 ft (PT-01a pumping zone)
%   - Colorbar bounds: [0.35, 0.50] nm/s
%   - R² = 0.934, Ss = 4.17e-08 1/m
%
% See docs/100Hz_Thesis_Analysis_Workflow.md for full workflow documentation
% and checklist for running PT01b/PT01c datasets.
%
% Usage:
%   1. Simply run this script in MATLAB
%   2. Generates Figures 101, 102, 103 + 4-subplot regression figure
%   3. Linear regression results saved to workspace as 'roi_results'

%clear all;
%close all;
%clc;

% Add src to path for console_log
script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(script_dir);

% Initialize console logging (overwrites same file each run)
log_dir = fullfile(parent_dir, 'data', '_BATCH', '_log');
if ~exist(log_dir, 'dir')
    mkdir(log_dir);
end
log_path = fullfile(log_dir, 'console_log.txt');
addpath(genpath(fullfile(parent_dir, 'src')));

console_log('init', log_path);

try
    console_log('\n=== PT-01a RECOVERY ANALYSIS FOR THESIS (100Hz Data) ===\n');
    console_log('Starting analysis...\n\n');

    %% STEP 1: Run Correlation Analysis
    % This processes the raw DAS and head data with optimal smoothing
    console_log('STEP 1/2: Running correlation analysis...\n');
    console_log('  - Loading 100Hz DAS data\n');
    console_log('  - Applying the SAME anti-aliasing filter used for 1Hz data\n');
    console_log('  - Filter: Kaiser window FIR lowpass (cutoff 0.5 Hz)\n');
    console_log('  - Processing head data\n');
    console_log('  - Applying +90s time shift to DAS data\n\n');
    
    % Add parent directory's src to path
    script_dir = fileparts(mfilename('fullpath'));
    parent_dir = fileparts(script_dir);
    addpath(genpath(fullfile(parent_dir, 'src')));
    
    % Choose your filtering approach:
    % Option 1: Resample anti-alias filter (matches 1Hz decimation filter exactly)
    % mode = 'run_correlation_analysis_lowpass_PT01a';  % Kaiser FIR lowpass (cutoff 0.5 Hz)
    
    % Option 2: Moving average filters (ACTIVE - best R² = 0.936)
    mode = 'run_correlation_analysis';  % Standard movmean (50-sec window at 100Hz = 5000 samples)
    
    % FOR 100 HZ DATA: Use longer smoothing
    % mode = 'run_correlation_analysis_15sec';  % 15-second (1500 samples)
    % mode = 'run_correlation_analysis_20sec';  % 20-second (2000 samples)
    % mode = 'run_correlation_analysis_25sec';  % 25-second (2500 samples)
    
    % --- DIAGNOSTIC: check before Toolkit ---
    diag_rogue = fullfile('C:', 'Coding', 'BGWRP', 'data', '_BATCH', '_active', 'PT01a_Recovery_100', 'PT01a_Recovery_short');
    if exist(diag_rogue, 'dir')
        console_log('*** DIAG [PRE-TOOLKIT]: ROGUE DIR EXISTS: %s ***\n', diag_rogue);
    else
        console_log('DIAG [PRE-TOOLKIT]: No rogue dir (good).\n');
    end
    
    BGWRP_Toolkit;
    
    % --- DIAGNOSTIC: check after Toolkit ---
    if exist(diag_rogue, 'dir')
        console_log('*** DIAG [POST-TOOLKIT]: ROGUE DIR EXISTS: %s ***\n', diag_rogue);
    else
        console_log('DIAG [POST-TOOLKIT]: No rogue dir (good).\n');
    end
    
    console_log('\n✓ Correlation analysis complete!\n\n');
    pause(2);  % Brief pause to see the message
    
    %% STEP 2: Run ROI Linear Regression Analysis
    % This performs spatial processing and linear regression on the focused region
    console_log('STEP 2/2: Running ROI linear regression analysis...\n');
    console_log('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
    console_log('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
    console_log('  - Strain shift: -14 seconds (left)\n\n');
    
    % --- DIAGNOSTIC: check before ROI ---
    if exist(diag_rogue, 'dir')
        console_log('*** DIAG [PRE-ROI]: ROGUE DIR EXISTS: %s ***\n', diag_rogue);
    else
        console_log('DIAG [PRE-ROI]: No rogue dir (good).\n');
    end
    
    run_roi_analysis_PT01a_100Hz;
    test_name = dataset_name;  % ROI script uses dataset_name; thesis script expects test_name
    
    % --- DIAGNOSTIC: check after ROI ---
    if exist(diag_rogue, 'dir')
        console_log('*** DIAG [POST-ROI]: ROGUE DIR EXISTS: %s ***\n', diag_rogue);
    else
        console_log('DIAG [POST-ROI]: No rogue dir (good).\n');
    end
    
    console_log('\n=== ANALYSIS COMPLETE ===\n');
    console_log('Results saved to workspace as ''roi_results''\n');
    console_log('Key metrics:\n');
    console_log('  - R² value: %.3f\n', roi_results.R_squared);
    console_log('  - Slope: %.2e\n', roi_results.slope);
    console_log('  - Correlation (R): %.3f\n', roi_results.R);
    console_log('  - RMSE: %.2e 1/s\n', roi_results.RMSE);
    %% STEP 3: Depth Profile Plot
    console_log('\nGenerating depth profile plot...\n');
    
    das_data_dp = das_results.(test_name);
    
    % Average displacement rate over regression window
    reg_start = datetime('2023-11-07 20:45:15', 'TimeZone', 'UTC');
    reg_end   = datetime('2023-11-07 20:46:30', 'TimeZone', 'UTC');
    reg_mask = das_data_dp.time_array >= reg_start & das_data_dp.time_array <= reg_end;
    mean_disp_rate = mean(das_data_dp.smoothed_data(reg_mask, :), 1, 'omitnan');
    
    % Spatial smoothing (20 channels = 5m at 0.25m/channel)
    mean_disp_rate = movmean(mean_disp_rate, 20);
    
    % Depth in meters
    depth_m = das_data_dp.depth_ft * 0.3048;
    screened_top_m = 450 * 0.3048;
    screened_bot_m = 510 * 0.3048;
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
    xlim([0.2, 0.5]);
    xlabel('Displacement Rate (nm/s)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Depth (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('Depth Profile - Mean Displacement Rate\n%s to %s UTC', ...
        datestr(reg_start, 'HH:MM:SS'), datestr(reg_end, 'HH:MM:SS')), 'FontSize', 13);
    text(max(xlim)*0.98, mean([screened_top_m screened_bot_m]), ...
        sprintf('Screened Interval\n(%.0f–%.0f m)', screened_top_m, screened_bot_m), ...
        'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'middle');
    grid on;
    
    console_log('  ✓ Figure 104: Depth profile (%d time points averaged)\n', sum(reg_mask));
    
    console_log('\nFigures generated:\n');
    console_log('  - Figure 101: DAS Displacement Rate (waterfall)\n');
    console_log('  - Figure 102: Displacement Rate with monitoring wells\n');
    console_log('  - Figure 103: Strain with head data\n');
    console_log('  - Figure 104: Depth profile of displacement rate\n');
    console_log('  - Figure: 4-subplot regression analysis\n');
    console_log('\nAll plots ready for thesis!\n');
    
catch ME
    console_log('\nERROR: %s\n', ME.message);
    console_log('close');
    rethrow(ME);
end

% Normal completion - close log
console_log('close');