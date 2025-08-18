function config = get_batch_config()
%GET_BATCH_CONFIG Return batch processor configuration
%
% Returns a structure containing all batch processing configuration
%
% Output:
%   config - Configuration structure

%% Base Configuration
config.base_input = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';

%% Optional Overrides (uncomment to use)
% config.test_directories = {'PT01a_Recovery', 'PT01b_Recovery', 'PT01c_Recovery'};
% config.test_labels = {'a', 'b', 'c'};
% config.decimation_factor = 100;

%% Waterfall Plot Configuration
% Display bounds for all waterfall plots [min_depth, max_depth] in feet
config.waterfall_display_bounds.min_depth = 100;
config.waterfall_display_bounds.max_depth = 665;

%% Zone Filtering Configuration (per dataset)
% Using exact parameters from PM07_Recovery_Analysis.m

% PT-01c configurations
config.waterfall_zones.PT01c_Recovery.min_depth = 260;
config.waterfall_zones.PT01c_Recovery.max_depth = 310;

config.waterfall_zones.PT01c_Full.min_depth = 260;
config.waterfall_zones.PT01c_Full.max_depth = 310;

% PT-01a configurations (uncomment to use)
% config.waterfall_zones.PT01a_Recovery.min_depth = 450;
% config.waterfall_zones.PT01a_Recovery.max_depth = 510;

% PT-01b configurations (uncomment to use)
% config.waterfall_zones.PT01b_Recovery.min_depth = 350;
% config.waterfall_zones.PT01b_Recovery.max_depth = 400;

%% Chart Saving Configuration
config.save_charts = true;
% config.chart_output_dir = ''; % Leave empty to use default location

fprintf('✓ Batch configuration loaded\n');

end
