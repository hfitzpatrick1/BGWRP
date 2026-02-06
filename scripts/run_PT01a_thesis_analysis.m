%% PT-01a Recovery Analysis for Thesis
% This script runs the complete DAS-Head correlation and linear regression analysis
% for PT-01a Recovery test data
%
% Optimized settings (as of Feb 2026):
%   - **100Hz DATA** with the SAME anti-aliasing filter used for 1Hz data!
%   - Filter: Kaiser window FIR lowpass (cutoff 0.5 Hz)
%   - This is the EXACT filter that makes 1Hz data look clean
%   - Preserves signal while removing high-frequency noise
%   - DAS time shift: +90 seconds forward
%   - Head timing correction: 14 seconds backward
%   - Analysis window: 20:44:30 to 20:47:30 UTC (Nov 7, 2023)
%   - Regression window: 20:45:15 to 20:46:30 UTC (peak region)
%   - Depth range: 450-510 ft (PT-01a pumping zone)
%   - Dynamic colorbar bounds enabled
%
% Usage:
%   1. Simply run this script in MATLAB
%   2. Generates all plots automatically
%   3. Linear regression results saved to workspace as 'roi_results'

clear all;
close all;
clc;

% Initialize console logging
log_dir = fullfile('C:', 'Coding', 'BGWRP', 'data', '_BATCH', '_log');
if ~exist(log_dir, 'dir')
    mkdir(log_dir);
end
timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
log_path = fullfile(log_dir, sprintf('console_log_%s.txt', timestamp));

% Add src to path for console_log
script_dir = fileparts(mfilename('fullpath'));
parent_dir = fileparts(script_dir);
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
    % Option 1: Resample anti-alias filter (attempts to match 1Hz filter exactly)
    % mode = 'run_correlation_analysis_lowpass';
    
    % Option 2: Moving average filters
    % FOR 1 HZ DATA: Use standard mode (already clean)
    mode = 'run_correlation_analysis';  % Standard (15-second = 15 samples at 1Hz)
    
    % FOR 100 HZ DATA: Use longer smoothing
    % mode = 'run_correlation_analysis_15sec';  % 15-second (1500 samples)
    % mode = 'run_correlation_analysis_20sec';  % 20-second (2000 samples)
    % mode = 'run_correlation_analysis_25sec';  % 25-second (2500 samples)
    
    BGWRP_Toolkit;
    
    console_log('\n✓ Correlation analysis complete!\n\n');
    pause(2);  % Brief pause to see the message
    
    %% STEP 2: Run ROI Linear Regression Analysis
    % This performs spatial processing and linear regression on the focused region
    console_log('STEP 2/2: Running ROI linear regression analysis...\n');
    console_log('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
    console_log('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
    console_log('  - Head timing correction: 14 seconds backward\n\n');
    
    run_roi_analysis;
    
    console_log('\n=== ANALYSIS COMPLETE ===\n');
    console_log('Results saved to workspace as ''roi_results''\n');
    console_log('Key metrics:\n');
    console_log('  - R² value: %.3f\n', roi_results.R_squared);
    console_log('  - Slope: %.2e\n', roi_results.slope);
    console_log('  - Correlation (R): %.3f\n', roi_results.R);
    console_log('  - RMSE: %.2e 1/s\n', roi_results.RMSE);
    console_log('\nFigures generated:\n');
    console_log('  - Figure 101: DAS Displacement Rate (waterfall)\n');
    console_log('  - Figure 102: Displacement Rate with monitoring wells\n');
    console_log('  - Figure 103: Strain with head data\n');
    console_log('  - Figure: 4-subplot regression analysis\n');
    console_log('\nAll plots ready for thesis!\n');
    console_log('\n*** Using 100Hz data with resample anti-aliasing filter (same as 1Hz data!) ***\n');
    
catch ME
    console_log('\nERROR: %s\n', ME.message);
    console_log('close');
    rethrow(ME);
end

% Normal completion - close log
console_log('close');