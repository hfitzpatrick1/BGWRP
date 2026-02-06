clear all
close all
clc
cd('C:\Coding\BGWRP\src')

% STEP 1: Run correlation analysis with sampling freq correction
fprintf('=== STEP 1: Running correlation analysis with corrected data ===\n\n');
mode = 'run_correlation_analysis';
BGWRP_Toolkit

% STEP 2: Run linear regression on the corrected data
fprintf('\n\n=== STEP 2: Running linear regression on corrected data ===\n\n');
config.lr_zone = 'z5';
config.lr_depth_range_ft = [279.5, 280.5];
config.lr_depth_averaging_method = 'representative';
config.lr_use_amplitude = true;
config.show_plots = true;
mode = 'run_linear_regression';
BGWRP_Toolkit

fprintf('\n\n=== ANALYSIS COMPLETE ===\n');
fprintf('Check Figure 20 - strain rate axis should now show e^-10 (not e^-12)!\n');
