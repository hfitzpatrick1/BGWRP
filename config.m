function config = config()
%CONFIG Return batch processor configuration
%
% Returns a structure containing all batch processing configuration
%
% Output:
%   config - Configuration structure

%% Base Configuration
config.base_input = 'C:\Coding\BGWRP\data\_BATCH\';

%% Decimation Configuration
config.decimation_factor = 100;  % Heavy decimation (100Hz → 1Hz)

%% Waterfall Plot Configuration
% Display bounds for all waterfall plots [min_depth, max_depth] in feet
config.waterfall_display_bounds.min_depth = 100;
config.waterfall_display_bounds.max_depth = 665;

%% Analysis Time Windows (per dataset)
% Universal time windows used for BOTH analysis filtering AND plot display
% Format: datetime objects in UTC timezone

% PT-01c START OF PUMPING Analysis Window (NEW DATASET)
% This dataset captures the pump start at 15:18 UTC
config.analysis_windows.PT01c_start_of_pumping.start = datetime(2023,10,24,15,10,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_start_of_pumping.end = datetime(2023,10,24,15,25,00,00,'TimeZone','UTC');

%% Zone Filtering Configuration (per dataset)
% PT-01c START OF PUMPING configurations (NEW DATASET)
config.waterfall_zones.PT01c_start_of_pumping.min_depth = 260;
config.waterfall_zones.PT01c_start_of_pumping.max_depth = 310;

%% Chart Saving Configuration
config.save_charts = true;

%% Plotting Configuration
config.dynamic_bounds = false;  % Use manual bounds for consistent visualization

%% Manual Plot Bounds (used when dynamic_bounds = false)
% Per-dataset, per-chart bounds configuration for all chart types

% ===== PT01c_start_of_pumping bounds =====
% Bounds adjusted to match line plot values for consistent waterfall colorbars
config.manual_bounds.PT01c_start_of_pumping.raw_data.min = -1.0;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01c_start_of_pumping.raw_data.max = 0.8;
config.manual_bounds.PT01c_start_of_pumping.displacement_rate.min = -0.35; % Figure 2: Strain rate (matches line plot)
config.manual_bounds.PT01c_start_of_pumping.displacement_rate.max = 0.02;
config.manual_bounds.PT01c_start_of_pumping.strain.min = -0.25;          % Figure 3: Strain
config.manual_bounds.PT01c_start_of_pumping.strain.max = 0.25;           % Increased max as requested

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01c_start_of_pumping.head_data.min = -0.07;          % Drawdown rate ft/min (Figure 2)
config.manual_bounds.PT01c_start_of_pumping.head_data.max = 0.01;
config.manual_bounds.PT01c_start_of_pumping.displacement_rate_line.min = -0.35;  % DAS strain rate nm/s (matches waterfall)
config.manual_bounds.PT01c_start_of_pumping.displacement_rate_line.max = 0.02;
config.manual_bounds.PT01c_start_of_pumping.strain_line.min = -0.25;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01c_start_of_pumping.strain_line.max = 0.25;
config.manual_bounds.PT01c_start_of_pumping.head_data_strain.min = -0.06;   % Head levels ft (Figure 3)
config.manual_bounds.PT01c_start_of_pumping.head_data_strain.max = 0.01;
config.manual_bounds.PT01c_start_of_pumping.depth_axis.min = 100;           % Depth axis ft
config.manual_bounds.PT01c_start_of_pumping.depth_axis.max = 665;

%% Head Data Zone Configuration (per dataset)
% PT01c START OF PUMPING zone configuration
config.head_zones.PT01c_start_of_pumping.zones = {'z2', 'z3', 'z4', 'z5'};  % Zones 2-5
config.head_zones.PT01c_start_of_pumping.display_mode = 'multiple';

%% Additional Configuration Parameters
config.apply_concatenation_filter = false;
config.filter_method = 'detrend';

%% Pixelation Testing Configuration
config.plot_method = 'pcolor';
config.shading_method = 'interp';
config.colormap_name = 'jet';
config.colormap_resolution = 256;
config.disable_analysis_smoothing = false;
config.smoothing_method = 'none';

fprintf('✓ Batch configuration loaded (PT01c_start_of_pumping with corrected bounds)\n');

end
