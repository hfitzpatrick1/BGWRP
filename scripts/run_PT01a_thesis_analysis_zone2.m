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

fprintf('=== PT-01a RECOVERY ANALYSIS FOR THESIS (ZONE 2) ===\n');
fprintf('Starting analysis...\n\n');

%% STEP 1: Run Correlation Analysis
% This processes the raw DAS and head data with optimal smoothing
fprintf('STEP 1/2: Running correlation analysis...\n');
fprintf('  - Loading and smoothing DAS data (15s moving average)\n');
fprintf('  - Processing head data\n');
fprintf('  - Applying +90s time shift to DAS data\n');
fprintf('  - USING ZONE 2 for head data\n\n');

addpath(genpath('src'));

% Override config to use Zone 2 for PT01a
config = config();
config.head_zones.PT01a_Recovery_short.primary_zone = 'z2';  % Force Zone 2

mode = 'run_correlation_analysis';
BGWRP_Toolkit;

fprintf('\n✓ Correlation analysis complete!\n\n');
pause(2);  % Brief pause to see the message

%% STEP 2: Run ROI Linear Regression Analysis with Zone 2
% This performs spatial processing and linear regression on the focused region
fprintf('STEP 2/2: Running ROI linear regression analysis...\n');
fprintf('  - Depth range: 450-510 ft (PT-01a pumping zone)\n');
fprintf('  - Regression window: 20:45:15 to 20:46:30 UTC\n');
fprintf('  - Head timing correction: 14 seconds backward\n');
fprintf('  - HEAD ZONE: z2 (Zone 2)\n\n');

% Check if run_roi_analysis exists, otherwise run manual regression
if exist('run_roi_analysis', 'file')
    run_roi_analysis;
else
    fprintf('run_roi_analysis not found - you may need to run linear regression manually\n');
    fprintf('Make sure to specify zone=''z2'' in your regression function\n');
end

fprintf('\n=== ANALYSIS COMPLETE ===\n');
if exist('roi_results', 'var')
    fprintf('Results saved to workspace as ''roi_results''\n');
    fprintf('Key metrics:\n');
    fprintf('  - R² value: %.3f\n', roi_results.R2);
    fprintf('  - Slope: %.2e\n', roi_results.slope);
    fprintf('  - Number of data points: %d\n', roi_results.n_points);
end
fprintf('\nFigures generated:\n');
fprintf('  - Figure 101: DAS Displacement Rate (waterfall)\n');
fprintf('  - Figure 102: Displacement Rate with monitoring wells\n');
fprintf('  - Figure 103: Strain with head data\n');
fprintf('  - Figure: 4-subplot regression analysis\n');
fprintf('\nAll plots ready for thesis!\n');
fprintf('\n*** REMEMBER: This analysis uses ZONE 2 head data ***\n');
