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
config.decimation_factor = 10;   % Light decimation (100Hz → 10Hz) - TEST GRID PATTERN
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
config.dynamic_bounds = true;  % Enable intelligent waterfall color bounds based on data

% Dynamic bounds mode: 'percentile', 'std_dev', 'robust', 'hybrid', 'minmax'
config.dynamic_bounds_mode = 'std_dev';

% Related dataset grouping for consistent bounds across similar tests
config.use_related_bounds = false;  % Calculate bounds across all datasets being analyzed
% When true: PT01a, PT01b, PT01c will all use the same color scale for comparison
% When false: Each dataset gets its own optimized color scale

%% Pixelation Testing Configuration
% Systematic settings to isolate pixelation sources - change one at a time for testing

% Visualization Method Testing (Priority 1 - Most Likely)
config.plot_method = 'pcolor';          % 'pcolor', 'imagesc', 'surf', 'contourf'
config.shading_method = 'interp';       % 'interp', 'flat', 'faceted'
config.edge_display = 'none';           % 'none', 'black', 'white' (for surf method)

% Colormap Testing (Priority 4 - Visual)
config.colormap_name = 'jet';           % 'jet', 'turbo', 'parula', 'viridis', 'hot'
config.colormap_resolution = 256;       % 64, 128, 256, 512, 1024 (color steps)

% Data Smoothing Testing (Priority 2 - Processing)
config.disable_analysis_smoothing = false;    % true = skip all smoothing in analyze_das_data.m
config.smoothing_method = 'movmean';           % 'movmean', 'movmedian', 'gaussian', 'none'
config.smoothing_window_factor = 1.0;         % 0.5, 1.0, 2.0 (multiplier for default window size)

% Precision Testing (Priority 5 - Data Type)
config.force_double_precision = false;        % true = force double precision throughout

% Advanced Testing Options
config.interpolation_method = 'linear';       % 'linear', 'nearest', 'cubic' (for imagesc/contourf)
config.anti_aliasing = false;                  % false = disable anti-aliasing if supported

%% Quick Test Configurations (uncomment ONE set to test)
% Uncomment one of these sections for systematic pixelation testing:

% TEST 1A: Replace pcolor with imagesc (most likely fix)
% config.plot_method = 'imagesc';
% config.shading_method = 'flat';

% TEST 1B: Try surf method with sharp edges
% config.plot_method = 'surf';
% config.shading_method = 'flat';
% config.edge_display = 'none';

% TEST 1C: Sharp pcolor with no interpolation
% config.plot_method = 'pcolor';
% config.shading_method = 'flat';

% TEST 2A: Disable all smoothing (test if smoothing causes pixelation)
% config.disable_analysis_smoothing = true;

% TEST 2B: Reduce smoothing window
% config.smoothing_window_factor = 0.5;

% TEST 3A: Fixed bounds instead of dynamic
% config.dynamic_bounds = false;

% TEST 4A: High resolution colormap (test if color quantization causes grid)
config.colormap_resolution = 1024;

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

%% Head Data Zone Configuration (per dataset)
% Specify which zone(s) to display for head data overlay in plots
% Can be: 'all' (default), single zone string 'z3', or array {'z2', 'z3'}

% Default behavior: show all available zones
config.head_zones.default.zones = 'all';  % Show all zones as separate lines
config.head_zones.default.display_mode = 'multiple';  % 'single', 'multiple', 'average'

% Dataset-specific overrides (uncomment and customize as needed)
% config.head_zones.PT01a_Recovery_short.zones = 'z3';  % Single zone
% config.head_zones.PT01a_Recovery_short.display_mode = 'single';

% config.head_zones.PT01b_Recovery_short.zones = {'z2', 'z3'};  % Multiple specific zones
% config.head_zones.PT01b_Recovery_short.display_mode = 'multiple';

% config.head_zones.PT01c_Recovery_short.zones = 'all';  % All available zones
% config.head_zones.PT01c_Recovery_short.display_mode = 'average';  % Average all zones into single line

% config.head_zones.TEST.zones = 'z3';
% config.head_zones.TEST.display_mode = 'single';

fprintf('✓ Batch configuration loaded\n');

end
