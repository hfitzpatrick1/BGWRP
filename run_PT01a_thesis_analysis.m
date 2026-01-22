%% PT-01a Recovery Analysis for Thesis
% This script runs the complete DAS-Head correlation and linear regression analysis
% for PT-01a Recovery test data
%
% Optimized settings (as of Jan 22, 2026):
%   - DAS time shift: +90 seconds forward
%   - Head timing correction: 14 seconds backward
%   - Temporal smoothing: 15-second moving average
%   - Analysis window: 20:44:30 to 20:47:30 UTC (Nov 7, 2023)
%   - Regression window: 20:45:15 to 20:46:30 UTC (peak region)
%   - Depth range: 450-510 ft (PT-01a pumping zone)
%   - Colorbar: [0.095, 0.24] nm/s
%
% Usage:
%   1. Simply run this script in MATLAB
%   2. Generates all plots automatically
%   3. Linear regression results saved to workspace as 'roi_results'

clear all;
close all;
clc;

fprintf('=== PT-01a RECOVERY ANALYSIS FOR THESIS ===\n');
fprintf('Starting analysis...\n\n');

%% STEP 1: Run Correlation Analysis
% This processes the raw DAS and head data with optimal smoothing
fprintf('STEP 1/2: Running correlation analysis...\n');
fprintf('  - Loading and smoothing DAS data (15s moving average)\n');
fprintf('  - Processing head data\n');
fprintf('  - Applying +90s time shift to DAS data\n\n');

addpath(genpath('src'));
mode = 'run_correlation_analysis';
BGWRP_Toolkit;

fprintf('\n✓ Correlation analysis complete!\n\n');
pause(2);  % Brief pause to see the message

%% STEP 2: Run ROI Linear Regression Analysis
% This performs spatial processing and linear regression on the focused region
fprintf('STEP 2/2: Running ROI linear regression analysis...\n');
fprintf('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
fprintf('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
fprintf('  - Head timing correction: 14 seconds backward\n\n');

run_roi_analysis;

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('Results saved to workspace as ''roi_results''\n');
fprintf('Key metrics:\n');
fprintf('  - R² value: %.3f\n', roi_results.R2);
fprintf('  - Slope: %.2e\n', roi_results.slope);
fprintf('  - Number of data points: %d\n', roi_results.n_points);
fprintf('\nFigures generated:\n');
fprintf('  - Figure 101: DAS Displacement Rate (waterfall)\n');
fprintf('  - Figure 102: Displacement Rate with monitoring wells\n');
fprintf('  - Figure 103: Strain with head data\n');
fprintf('  - Figure: 4-subplot regression analysis\n');
fprintf('\nAll plots ready for thesis!\n');
