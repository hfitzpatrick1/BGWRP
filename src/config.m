function config = config()
%CONFIG Return batch processor configuration
%
% Returns a structure containing all batch processing configuration
%
% Output:
%   config - Configuration structure

%% Base Configuration
config.base_input = 'C:\Coding\BGWRP\data\_BATCH\';

%% Optional Overrides (uncomment to use)
% config.test_directories = {'PT01a_Recovery', 'PT01b_Recovery', 'PT01c_Recovery'};
% config.test_labels = {'a', 'b', 'c'};

%% Decimation Configuration
config.decimation_factor = 10;   % Light decimation (100Hz → 10Hz)  
% config.decimation_factor = 100;  % Heavy decimation (100Hz → 1Hz)
% config.decimation_factor = 1;    % No decimation (preserve 100Hz)
% config.decimation_factor = 5;    % Medium decimation (100Hz → 20Hz)

%% Waterfall Plot Configuration
% Display bounds for all waterfall plots [min_depth, max_depth] in feet
config.waterfall_display_bounds.min_depth = 100;
config.waterfall_display_bounds.max_depth = 665;

%% Analysis Time Windows (per dataset)
% Universal time windows used for BOTH analysis filtering AND plot display
% Format: datetime objects in UTC timezone

% PT-01c Recovery Analysis Window (from original PM07_Recovery_Analysis.m)
config.analysis_windows.PT01c_Recovery.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_Recovery.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

config.analysis_windows.PT01c_Full.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_Full.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

config.analysis_windows.PT01c_Full_New.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_Full_New.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

% PT-01a Recovery Analysis Window (uncomment to use)
% config.analysis_windows.PT01a_Recovery.start = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
% config.analysis_windows.PT01a_Recovery.end = datetime(2023,11,7,20,48,00,00,'TimeZone','UTC');

% PT-01b Recovery Analysis Window (uncomment to use)
% config.analysis_windows.PT01b_Recovery.start = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
% config.analysis_windows.PT01b_Recovery.end = datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');

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

%% Plotting Configuration
config.dynamic_bounds = false;  % Enable intelligent waterfall color bounds based on data

%% Filtering Configuration
config.apply_concatenation_filter = false;  % Apply post-processing filter to remove file boundary artifacts
config.filter_method = 'detrend';  % Filter method: 'none', 'detrend', 'highpass', 'median', 'overlap_smooth'

fprintf('✓ Batch configuration loaded\n');

end
