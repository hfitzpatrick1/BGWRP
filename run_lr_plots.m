%% Quick script to run linear regression and generate standalone plots
% This runs your existing analysis pipeline with linear regression enabled

clear; clc;

% Set up test
test_name = 'PT01c_Recovery_short';
mode = 'run_linear_regression';

% Run the BGWRP Toolkit
BGWRP_Toolkit;

fprintf('\n✓ Done! Check Figures 200 & 201 for standalone plots\n');


