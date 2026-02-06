%% PT-01a Recovery Analysis with 100 Hz Data + Anti-Aliasing Filter
% This script processes 100 Hz DAS data with the SAME anti-aliasing filter
% that was used to create the clean 1 Hz data (Kaiser window FIR lowpass).
%
% Key differences from 1 Hz analysis:
%   - Uses PT01a_Recovery_100 dataset (100 Hz sampling)
%   - Applies resample anti-aliasing filter (cutoff 0.5 Hz)
%   - Preserves 100 Hz time resolution while achieving 1 Hz smoothness
%   - May need different time shift adjustment
%
% Usage:
%   1. Simply run this script in MATLAB
%   2. Compares results with your successful 1 Hz analysis (R² = 0.936)

clear all;
close all;
clc;

console_log('=== PT-01a RECOVERY ANALYSIS WITH 100 Hz DATA + ANTI-ALIASING ===\n');
console_log('Using the SAME filter that makes 1 Hz data look clean!\n');
console_log('Filter: Kaiser window FIR lowpass (cutoff 0.5 Hz)\n\n');

%% Navigate to correct directory and add paths
% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
% Navigate to the parent directory (main BGWRP folder)
main_dir = fileparts(script_dir);
cd(main_dir);
console_log('Changed to main directory: %s\n\n', main_dir);

% Add all subdirectories to path
addpath(genpath('src'));
addpath(genpath('scripts'));  % Scripts were moved for organization (Feb 6, 2026)

% CRITICAL: Clear BGWRP_Toolkit from memory to reload with new mode
clear BGWRP_Toolkit;
console_log('Cleared BGWRP_Toolkit from memory (reloading with new configuration mode)\n\n');

%% STEP 1: Run Correlation Analysis with Anti-Aliasing Filter
console_log('STEP 1/2: Running correlation analysis with anti-aliasing filter...\n');
console_log('  - Loading PT01a_Recovery_100 (100 Hz DAS data)\n');
console_log('  - Applying resample anti-aliasing filter (same as 1 Hz decimation)\n');
console_log('  - Filter cutoff: 0.5 Hz (Nyquist frequency for 1 Hz)\n');
console_log('  - Processing head data\n');
console_log('  - Applying time shift to DAS data\n\n');

% Use the PT01a-specific lowpass filter mode (lowercase since BGWRP_Toolkit uses lower(mode))
mode = 'run_correlation_analysis_lowpass_pt01a';
BGWRP_Toolkit;

console_log('\n✓ Correlation analysis complete!\n\n');
pause(2);

%% STEP 2: Run ROI Linear Regression Analysis
console_log('STEP 2/2: Running ROI linear regression analysis...\n');
console_log('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
console_log('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
console_log('  - Head timing correction: 14 seconds backward\n\n');

run_roi_analysis_PT01a_100Hz;

%% Display Results
console_log('\n=== ANALYSIS COMPLETE ===\n');
console_log('Dataset: PT01a_Recovery_100 (100 Hz with anti-aliasing filter)\n');
console_log('Filter: Resample anti-aliasing (Kaiser window FIR, cutoff 0.5 Hz)\n\n');
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

console_log('\n=== COMPARISON WITH 1 Hz ANALYSIS ===\n');
console_log('1 Hz data results (from your documentation):\n');
console_log('  - R² value: 0.936\n');
console_log('  - Time shift: +38 seconds\n');
console_log('  - Smoothing: 50 seconds (pre-decimation + 50s moving average)\n');
console_log('\n100 Hz + anti-aliasing results:\n');
console_log('  - R² value: %.3f\n', roi_results.R_squared);
console_log('  - Time shift: +38 seconds (from 1Hz optimization)\n');
console_log('  - Smoothing: Anti-aliasing filter (0.5 Hz cutoff) + minimal additional\n');

if roi_results.R_squared < 0.90
    console_log('\n*** R² is lower than expected. Try adjusting das_time_shift_seconds ***\n');
    console_log('*** Edit BGWRP_Toolkit.m line ~870, try values 33-43 seconds ***\n');
else
    console_log('\n*** Excellent! R² meets or exceeds target of 0.90 ***\n');
end
