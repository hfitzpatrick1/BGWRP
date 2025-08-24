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
% config.decimation_factor = 10;   % Light decimation (100Hz → 10Hz)  
config.decimation_factor = 10;  % Heavy decimation (100Hz → 1Hz)
% config.decimation_factor = 1;    % No decimation (preserve 100Hz)
% config.decimation_factor = 5;    % Medium decimation (100Hz → 20Hz)

%% Waterfall Plot Configuration
% Display bounds for all waterfall plots [min_depth, max_depth] in feet
config.waterfall_display_bounds.min_depth = 100;
config.waterfall_display_bounds.max_depth = 665;

%% Analysis Time Windows (per dataset)
% Universal time windows used for BOTH analysis filtering AND plot display
% Format: datetime objects in UTC timezone

% Current datasets based on actual files in _active directory:
% PT01a_Recovery_short, PT01b_Recovery_short, PT01c_Recovery_short

% PT-01a Recovery Analysis Window
config.analysis_windows.PT01a_Recovery_short.start = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
config.analysis_windows.PT01a_Recovery_short.end = datetime(2023,11,7,20,48,00,00,'TimeZone','UTC');

% PT-01b Recovery Analysis Window  
config.analysis_windows.PT01b_Recovery_short.start = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
config.analysis_windows.PT01b_Recovery_short.end = datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');

% PT-01c Recovery Analysis Window
config.analysis_windows.PT01c_Recovery_short.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_Recovery_short.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

%% Zone Filtering Configuration (per dataset)
% Updated for actual dataset names and calibrated for data ranges

% PT-01a configurations (data range: [-30.2, 41.5])
config.waterfall_zones.PT01a_Recovery_short.min_depth = 450;
config.waterfall_zones.PT01a_Recovery_short.max_depth = 510;

% PT-01b configurations (data range: [-29.9, 30.3])  
config.waterfall_zones.PT01b_Recovery_short.min_depth = 350;
config.waterfall_zones.PT01b_Recovery_short.max_depth = 400;

% PT-01c configurations (data range: [-26.3, 25.2])
config.waterfall_zones.PT01c_Recovery_short.min_depth = 260;
config.waterfall_zones.PT01c_Recovery_short.max_depth = 310;

%% Chart Saving Configuration
config.save_charts = true;
% config.chart_output_dir = ''; % Leave empty to use default location

%% Plotting Configuration
config.dynamic_bounds = false;  % Enable intelligent waterfall color bounds based on data

% Dynamic bounds mode: 'percentile', 'std_dev', 'robust', 'hybrid', 'minmax'
config.dynamic_bounds_mode = 'std_dev';

% Related dataset grouping for consistent bounds across similar tests
config.use_related_bounds = false;  % Calculate bounds across all datasets being analyzed
% When true: PT01a, PT01b, PT01c will all use the same color scale for comparison
% When false: Each dataset gets its own optimized color scale

%% Manual Plot Bounds (used when dynamic_bounds = false)
% Based on discovered data ranges: PT01a [-30.2, 41.5], PT01b [-29.9, 30.3], PT01c [-26.3, 25.2]

% Raw data bounds (conservative range covering all datasets)
config.manual_bounds.raw.min = -35;
config.manual_bounds.raw.max = 45;

% Displacement rate bounds (more focused)
config.manual_bounds.displacement.min = -0.35;
config.manual_bounds.displacement.max = 0.25;

% Strain bounds (typically negative accumulation)
config.manual_bounds.strain.min = -3;
config.manual_bounds.strain.max = 1;

%% Filtering Configuration
config.apply_concatenation_filter = false;  % Apply post-processing filter to remove file boundary artifacts
config.filter_method = 'detrend';  % Filter method: 'none', 'detrend', 'highpass', 'median', 'overlap_smooth'

fprintf('✓ Batch configuration loaded\n');

end
