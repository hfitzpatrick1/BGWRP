%% PT-01a Recovery Analysis for Thesis (Using Zone 2)
% This script runs the complete DAS-Head correlation and linear regression analysis
% for PT-01a Recovery test data using ZONE 2 instead of Zone 3
%
% Optimized settings (as of Jan 23, 2026):
%   - DAS time shift: +90 seconds forward
%   - Head timing correction: 14 seconds backward
%   - Temporal smoothing: 15-second moving average
%   - Analysis window: 20:44:30 to 20:47:30 UTC (Nov 7, 2023)
%   - Regression window: 20:45:15 to 20:46:30 UTC (peak region)
%   - Depth range: 450-510 ft (PT-01a pumping zone)
%   - HEAD ZONE: z2 (Zone 2) - UPDATED FROM z3
%
% Usage:
%   1. Simply run this script in MATLAB
%   2. Generates all plots automatically
%   3. Linear regression results saved to workspace as 'roi_results'

clear all;
close all;
clc;

console_log('=== PT-01a RECOVERY ANALYSIS FOR THESIS (ZONE 2) ===\n');
console_log('Starting analysis...\n\n');

%% STEP 1: Run Correlation Analysis
% This processes the raw DAS and head data with optimal smoothing
console_log('STEP 1/2: Running correlation analysis...\n');
console_log('  - Loading and smoothing DAS data (15s moving average)\n');
console_log('  - Processing head data\n');
console_log('  - Applying +90s time shift to DAS data\n');
console_log('  - USING ZONE 2 for head data\n\n');

addpath(genpath('src'));

% Override config to use Zone 2 for PT01a
config = config();
config.head_zones.PT01a_Recovery_short.primary_zone = 'z2';  % Force Zone 2

mode = 'run_correlation_analysis';
BGWRP_Toolkit;

console_log('\n✓ Correlation analysis complete!\n\n');
pause(2);  % Brief pause to see the message

%% STEP 2: Run ROI Linear Regression Analysis with Zone 2
% This performs spatial processing and linear regression on the focused region
console_log('STEP 2/2: Running ROI linear regression analysis...\n');
console_log('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
console_log('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
console_log('  - Head timing correction: 14 seconds backward\n');
console_log('  - HEAD ZONE: z2 (Zone 2)\n\n');

% Check if run_roi_analysis exists, otherwise run manual regression
if exist('run_roi_analysis', 'file')
    run_roi_analysis;
else
    console_log('run_roi_analysis not found - you may need to run linear regression manually\n');
    console_log('Make sure to specify zone=''z2'' in your regression function\n');
end

console_log('\n=== ANALYSIS COMPLETE ===\n');
if exist('roi_results', 'var')
    console_log('Results saved to workspace as ''roi_results''\n');
    console_log('Key metrics:\n');
    console_log('  - R² value: %.3f\n', roi_results.R2);
    console_log('  - Slope: %.2e\n', roi_results.slope);
    console_log('  - Number of data points: %d\n', roi_results.n_points);
end
console_log('\nFigures generated:\n');
console_log('  - Figure 101: DAS Displacement Rate (waterfall)\n');
console_log('  - Figure 102: Displacement Rate with monitoring wells\n');
console_log('  - Figure 103: Strain with head data\n');
console_log('  - Figure: 4-subplot regression analysis\n');
console_log('\nAll plots ready for thesis!\n');
console_log('\n*** REMEMBER: This analysis uses ZONE 2 head data ***\n');
