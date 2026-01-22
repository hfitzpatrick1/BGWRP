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
config.waterfall_display_bounds.min_depth = 200;
config.waterfall_display_bounds.max_depth = 665;

%% Analysis Time Windows (per dataset)
% Universal time windows used for BOTH analysis filtering AND plot display
% Format: datetime objects in UTC timezone

% PT-01a START OF PUMPING Analysis Window (NEW DATASET)
% This dataset captures the pump start at 16:00 UTC
config.analysis_windows.PT01a_start_of_pumping.start = datetime(2023,11,07,16,00,00,00,'TimeZone','UTC');
config.analysis_windows.PT01a_start_of_pumping.end = datetime(2023,11,07,16,55,00,00,'TimeZone','UTC');

% PT-01c START OF PUMPING Analysis Window (NEW DATASET)
% This dataset captures the pump start at 15:18 UTC (data available 15:02-15:30)
config.analysis_windows.PT01c_start_of_pumping.start = datetime(2023,10,24,15,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_start_of_pumping.end = datetime(2023,10,24,15,19,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_recovery.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_recovery.end = datetime(2023,10,24,19,19,00,00,'TimeZone','UTC');

% PT01c_Recovery_short analysis window (matches actual dataset name)
config.analysis_windows.PT01c_Recovery_short.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.analysis_windows.PT01c_Recovery_short.end = datetime(2023,10,24,19,19,00,00,'TimeZone','UTC');

% PT01c_Recovery_short LINEAR REGRESSION focused window (peak signal only)
config.lr_recovery_window.PT01c_Recovery_short.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.lr_recovery_window.PT01c_Recovery_short.end = datetime(2023,10,24,19,17,00,00,'TimeZone','UTC');

% PT-01a START OF PUMPING Analysis Window
% This dataset captures the pump start for PT01a at 16:43 UTC
config.analysis_windows.PT01a_start_of_pumping.start = datetime(2023,11,07,16,43,00,00,'TimeZone','UTC');
config.analysis_windows.PT01a_start_of_pumping.end = datetime(2023,11,07,16,59,00,00,'TimeZone','UTC');

% PT-01b START OF PUMPING Analysis Window
% This dataset captures the pump start period
config.analysis_windows.PT01b_start_of_pumping.start = datetime(2023,10,31,15,29,00,00,'TimeZone','UTC');
config.analysis_windows.PT01b_start_of_pumping.end = datetime(2023,10,31,15,34,00,00,'TimeZone','UTC');

% PT01b_Recovery_short analysis window
% This dataset captures the recovery period from 19:26 to 19:36 UTC
% Using focused window 19:29:00 to 19:32:00 for analysis and regression
config.analysis_windows.PT01b_Recovery_short.start = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
config.analysis_windows.PT01b_Recovery_short.end = datetime(2023,10,31,19,32,00,00,'TimeZone','UTC');

% PT01a_Recovery_short analysis window
% This dataset captures the recovery period from 20:34 to 20:54 UTC
% Using focused window 20:44:00 to 20:47:30 for Figures 101-103 plots
config.analysis_windows.PT01a_Recovery_short.start = datetime(2023,11,07,20,44,00,00,'TimeZone','UTC');
config.analysis_windows.PT01a_Recovery_short.end = datetime(2023,11,07,20,47,30,00,'TimeZone','UTC');

%% Zone Filtering Configuration (per dataset)
% PT-01a START OF PUMPING configurations (NEW DATASET)
config.waterfall_zones.PT01a_start_of_pumping.min_depth = 260;
config.waterfall_zones.PT01a_start_of_pumping.max_depth = 310;

% PT-01c START OF PUMPING configurations (NEW DATASET)
config.waterfall_zones.PT01c_start_of_pumping.min_depth = 260;
config.waterfall_zones.PT01c_start_of_pumping.max_depth = 310;
config.waterfall_zones.PT01c_recovery.min_depth = 260;
config.waterfall_zones.PT01c_recovery.max_depth = 310;

% PT-01b START OF PUMPING configurations
config.waterfall_zones.PT01b_start_of_pumping.min_depth = 350;
config.waterfall_zones.PT01b_start_of_pumping.max_depth = 400;

%% Chart Saving Configuration
config.save_charts = true;

%% Plotting Configuration
config.dynamic_bounds = false;  % Use manual bounds for consistent visualization

%% Default Depth Axis Bounds (applied to all pump tests unless overridden)
config.default_depth_axis.min = 175;  % ft
config.default_depth_axis.max = 665;  % ft

%% Manual Plot Bounds (used when dynamic_bounds = false)
% Per-dataset, per-chart bounds configuration for all chart types

% ===== PT01a_start_of_pumping bounds =====
% Initial bounds for PT01a pumping start analysis
config.manual_bounds.PT01a_start_of_pumping.raw_data.min = -0.45;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01a_start_of_pumping.raw_data.max = -0.3;
config.manual_bounds.PT01a_start_of_pumping.displacement_rate.min = -0.5;  % Figure 2: Start of pumping bounds
config.manual_bounds.PT01a_start_of_pumping.displacement_rate.max = -0.25;
config.manual_bounds.PT01a_start_of_pumping.strain.min = -0.13;           % Figure 3: Start of pumping bounds  
config.manual_bounds.PT01a_start_of_pumping.strain.max = 0.10;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01a_start_of_pumping.head_data.min = -0.08;          % Drawdown rate ft/min (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01a_start_of_pumping.head_data.max = 0.02;
config.manual_bounds.PT01a_start_of_pumping.pw_head_data.min = -54;          % PW drawdown rate (Figure 2 subplot 3)
config.manual_bounds.PT01a_start_of_pumping.pw_head_data.max = 54;
config.manual_bounds.PT01a_start_of_pumping.displacement_rate_line.min = -0.3;   % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01a_start_of_pumping.displacement_rate_line.max = 0;
config.manual_bounds.PT01a_start_of_pumping.strain_line.min = -0.2;         % DAS strain nm/m (subplot 2 & 3)
config.manual_bounds.PT01a_start_of_pumping.strain_line.max = 0.15;
config.manual_bounds.PT01a_start_of_pumping.head_data_strain.min = 0.02;   % Head levels ft (Figure 3 subplot 2) - monitoring wells only
config.manual_bounds.PT01a_start_of_pumping.head_data_strain.max = 0.08;
config.manual_bounds.PT01a_start_of_pumping.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01a_start_of_pumping.depth_axis.max = 665;
config.manual_bounds.PT01a_start_of_pumping.pw_head_strain.min = -25;     % Pumping well head levels ft (Figure 3 subplot 3)
config.manual_bounds.PT01a_start_of_pumping.pw_head_strain.max = 1;

% ===== PT01c_start_of_pumping bounds =====
% Bounds adjusted to match line plot values for consistent waterfall colorbars
config.manual_bounds.PT01c_start_of_pumping.raw_data.min = -0.45;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01c_start_of_pumping.raw_data.max = -0.25;
config.manual_bounds.PT01c_start_of_pumping.displacement_rate.min = -0.28; % Figure 2: Strain rate (matches line plot)
config.manual_bounds.PT01c_start_of_pumping.displacement_rate.max = 0.03;
config.manual_bounds.PT01c_start_of_pumping.strain.min = -0.25;          % Figure 3: Strain
config.manual_bounds.PT01c_start_of_pumping.strain.max = 0.25;           % Increased max as requested

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01c_start_of_pumping.head_data.min = -0.05;          % Drawdown rate ft/min (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01c_start_of_pumping.head_data.max = 0.02;
config.manual_bounds.PT01c_start_of_pumping.pw_head_data.min = -2;          % PW drawdown rate (Figure 2 subplot 3)
config.manual_bounds.PT01c_start_of_pumping.pw_head_data.max = 22;
config.manual_bounds.PT01c_start_of_pumping.displacement_rate_line.min = -0.3;  % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01c_start_of_pumping.displacement_rate_line.max = 0.035;
config.manual_bounds.PT01c_start_of_pumping.strain_line.min = -0.25;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01c_start_of_pumping.strain_line.max = 0.25;
config.manual_bounds.PT01c_start_of_pumping.head_data_strain.min = -0.06;   % Head levels ft (Figure 3) - monitoring wells only
config.manual_bounds.PT01c_start_of_pumping.head_data_strain.max = 0.01;
config.manual_bounds.PT01c_start_of_pumping.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01c_start_of_pumping.depth_axis.max = 665;
config.manual_bounds.PT01c_start_of_pumping.pw_head_strain.min = -9.0;     % Pumping well head levels ft (Figure 3, subplot 3)
config.manual_bounds.PT01c_start_of_pumping.pw_head_strain.max = 1.0;

% ===== PT01c_recovery bounds =====
% Recovery phase bounds for PT01c
config.manual_bounds.PT01c_recovery.raw_data.min = -0.48;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01c_recovery.raw_data.max = -0.38;
config.manual_bounds.PT01c_recovery.displacement_rate.min = -0.5; % Figure 2: Displacement rate main colorbar
config.manual_bounds.PT01c_recovery.displacement_rate.max = -0.25;
config.manual_bounds.PT01c_recovery.strain.min = -0.13;          % Figure 3: Strain main colorbar
config.manual_bounds.PT01c_recovery.strain.max = 0.10;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01c_recovery.head_data.min = 0.02;          % Drawdown rate ft/min (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01c_recovery.head_data.max = 0.12;
config.manual_bounds.PT01c_recovery.pw_head_data.min = -52;          % PW drawdown rate (Figure 2 subplot 3)
config.manual_bounds.PT01c_recovery.pw_head_data.max = 52;
config.manual_bounds.PT01c_recovery.displacement_rate_line.min = -0.3;  % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01c_recovery.displacement_rate_line.max = 0;
config.manual_bounds.PT01c_recovery.strain_line.min = -0.2;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01c_recovery.strain_line.max = 0.15;
config.manual_bounds.PT01c_recovery.head_data_strain.min = 0.02;   % Head levels ft (Figure 3 subplot 2) - monitoring wells only
config.manual_bounds.PT01c_recovery.head_data_strain.max = 0.08;
config.manual_bounds.PT01c_recovery.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01c_recovery.depth_axis.max = 665;
config.manual_bounds.PT01c_recovery.pw_head_strain.min = -25;     % Pumping well head levels ft (Figure 3 subplot 3)
config.manual_bounds.PT01c_recovery.pw_head_strain.max = 1;

% ===== PT01c_Recovery_short bounds (actual dataset name) =====
% Recovery phase bounds for PT01c (matches PT01c_recovery above)
config.manual_bounds.PT01c_Recovery_short.raw_data.min = -0.15;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01c_Recovery_short.raw_data.max = 0.1;
config.manual_bounds.PT01c_Recovery_short.displacement_rate.min = -0.12; % Figure 2: Displacement rate main colorbar
config.manual_bounds.PT01c_Recovery_short.displacement_rate.max = 0.08;
config.manual_bounds.PT01c_Recovery_short.strain.min = -0.2;          % Figure 3: Strain main colorbar
config.manual_bounds.PT01c_Recovery_short.strain.max = 0.2;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01c_Recovery_short.head_data.min = -0.02;          % Drawdown rate ft/min (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01c_Recovery_short.head_data.max = 0.1;
config.manual_bounds.PT01c_Recovery_short.pw_head_data.min = -1;          % PW drawdown rate (Figure 2 subplot 3)
config.manual_bounds.PT01c_Recovery_short.pw_head_data.max = 55;
config.manual_bounds.PT01c_Recovery_short.displacement_rate_line.min = -0.2;  % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01c_Recovery_short.displacement_rate_line.max = 0.15;
config.manual_bounds.PT01c_Recovery_short.strain_line.min = -0.2;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01c_Recovery_short.strain_line.max = 0.2;
config.manual_bounds.PT01c_Recovery_short.head_data_strain.min = -0.2;   % Head levels ft (Figure 3 subplot 2) - monitoring wells only
config.manual_bounds.PT01c_Recovery_short.head_data_strain.max = -0.01;
config.manual_bounds.PT01c_Recovery_short.depth_axis.min = 150;           % Depth axis ft
config.manual_bounds.PT01c_Recovery_short.depth_axis.max = 665;
config.manual_bounds.PT01c_Recovery_short.pw_head_strain.min = -9;     % Pumping well head levels ft (Figure 3 subplot 3)
config.manual_bounds.PT01c_Recovery_short.pw_head_strain.max = 1;

% ===== PT01a_Recovery_short bounds (restored) =====
% Recovery bounds for PT01a dataset
config.manual_bounds.PT01a_Recovery_short.raw_data.min = 0.05;        % Figure 101: Raw data waterfall
config.manual_bounds.PT01a_Recovery_short.raw_data.max = 0.3;
config.manual_bounds.PT01a_Recovery_short.displacement_rate.min = 0.05; % Figure 102: Displacement rate main colorbar
config.manual_bounds.PT01a_Recovery_short.displacement_rate.max = 0.3;
config.manual_bounds.PT01a_Recovery_short.strain.min = -0.2;          % Figure 3: Strain main colorbar
config.manual_bounds.PT01a_Recovery_short.strain.max = 0.20;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01a_Recovery_short.head_data.min = -0.0001;          % Drawdown rate m/s (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01a_Recovery_short.head_data.max = 0.0004;
config.manual_bounds.PT01a_Recovery_short.pw_head_data.min = -0.01;          % PW drawdown rate m/s (Figure 2 subplot 3)
config.manual_bounds.PT01a_Recovery_short.pw_head_data.max = 0.25;
config.manual_bounds.PT01a_Recovery_short.displacement_rate_line.min = 0.05;  % DAS displacement rate nm/s (subplot 2 & 3 right y-axis)
config.manual_bounds.PT01a_Recovery_short.displacement_rate_line.max = 0.25;
config.manual_bounds.PT01a_Recovery_short.strain_line.min = -0.2;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01a_Recovery_short.strain_line.max = 0.2;
config.manual_bounds.PT01a_Recovery_short.head_data_strain.min = 0;   % Head levels ft (Figure 3 subplot 2) - monitoring wells only
config.manual_bounds.PT01a_Recovery_short.head_data_strain.max = 0.13;
config.manual_bounds.PT01a_Recovery_short.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01a_Recovery_short.depth_axis.max = 665;
config.manual_bounds.PT01a_Recovery_short.pw_head_strain.min = -24;     % Pumping well head levels ft (Figure 3 subplot 3)
config.manual_bounds.PT01a_Recovery_short.pw_head_strain.max = 5;

% ===== PT01a_start_of_pumping bounds =====
% Bounds for PT01a pumping start analysis
config.manual_bounds.PT01a_start_of_pumping.raw_data.min = -0.48;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01a_start_of_pumping.raw_data.max = -0.25;
config.manual_bounds.PT01a_start_of_pumping.displacement_rate.min = -0.43;  % Figure 2: Start of pumping bounds
config.manual_bounds.PT01a_start_of_pumping.displacement_rate.max = -0.3;
config.manual_bounds.PT01a_start_of_pumping.strain.min = -0.4;           % Figure 3: Start of pumping bounds
config.manual_bounds.PT01a_start_of_pumping.strain.max = 0.15;

% Line chart Y-axis bounds for PT01a
config.manual_bounds.PT01a_start_of_pumping.head_data.min = -0.07;          % Drawdown rate ft/min (Figure 2) - monitoring wells only
config.manual_bounds.PT01a_start_of_pumping.head_data.max = 0.01;
config.manual_bounds.PT01a_start_of_pumping.pw_head_data.min = -2;          % PW drawdown rate (Figure 2 subplot 3)
config.manual_bounds.PT01a_start_of_pumping.pw_head_data.max = 22;
config.manual_bounds.PT01a_start_of_pumping.displacement_rate_line.min = -0.3;  % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01a_start_of_pumping.displacement_rate_line.max = 0;
config.manual_bounds.PT01a_start_of_pumping.strain_line.min = -0.4;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01a_start_of_pumping.strain_line.max = 0.3;
config.manual_bounds.PT01a_start_of_pumping.head_data_strain.min = -0.06;   % Head levels ft (Figure 3) - monitoring wells only
config.manual_bounds.PT01a_start_of_pumping.head_data_strain.max = 0.01;
config.manual_bounds.PT01a_start_of_pumping.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01a_start_of_pumping.depth_axis.max = 665;
config.manual_bounds.PT01a_start_of_pumping.pw_head_strain.min = -24;     % Pumping well head levels ft (Figure 3, subplot 3)
config.manual_bounds.PT01a_start_of_pumping.pw_head_strain.max = 5;

% ===== PT01b_start_of_pumping bounds =====
% Bounds for PT01b pumping start analysis
config.manual_bounds.PT01b_start_of_pumping.raw_data.min = -0.48;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01b_start_of_pumping.raw_data.max = -0.25;
config.manual_bounds.PT01b_start_of_pumping.displacement_rate.min = -0.43;
config.manual_bounds.PT01b_start_of_pumping.displacement_rate.max = -0.3;
config.manual_bounds.PT01b_start_of_pumping.strain.min = -0.4;
config.manual_bounds.PT01b_start_of_pumping.strain.max = 0.15;

% Line chart Y-axis bounds for PT01b
config.manual_bounds.PT01b_start_of_pumping.head_data.min = -0.07;          % Drawdown rate ft/min (Figure 2) - monitoring wells only
config.manual_bounds.PT01b_start_of_pumping.head_data.max = 0.01;
config.manual_bounds.PT01b_start_of_pumping.displacement_rate_line.min = -0.3;
config.manual_bounds.PT01b_start_of_pumping.displacement_rate_line.max = 0;
config.manual_bounds.PT01b_start_of_pumping.strain_line.min = -0.4;
config.manual_bounds.PT01b_start_of_pumping.strain_line.max = 0.3;
config.manual_bounds.PT01b_start_of_pumping.head_data_strain.min = -0.06;   % Head levels ft (Figure 3) - monitoring wells only
config.manual_bounds.PT01b_start_of_pumping.head_data_strain.max = 0.01;
config.manual_bounds.PT01b_start_of_pumping.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01b_start_of_pumping.depth_axis.max = 665;
config.manual_bounds.PT01b_start_of_pumping.pw_head_strain.min = -6.0;     % Pumping well head levels ft (if needed)
config.manual_bounds.PT01b_start_of_pumping.pw_head_strain.max = 1.0;

% ===== PT01b_Recovery_short bounds =====
% Recovery bounds for PT01b dataset
config.manual_bounds.PT01b_Recovery_short.raw_data.min = -0.5;        % Figure 1: Raw data waterfall
config.manual_bounds.PT01b_Recovery_short.raw_data.max = 0.1;
config.manual_bounds.PT01b_Recovery_short.displacement_rate.min = -0.5; % Figure 2: Displacement rate main colorbar
config.manual_bounds.PT01b_Recovery_short.displacement_rate.max = 0.1;
config.manual_bounds.PT01b_Recovery_short.strain.min = -0.2;          % Figure 3: Strain main colorbar
config.manual_bounds.PT01b_Recovery_short.strain.max = 0.2;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01b_Recovery_short.head_data.min = -0.0001;          % Drawdown rate m/s (Figure 2 subplot 2) - monitoring wells only
config.manual_bounds.PT01b_Recovery_short.head_data.max = 0.0003;
config.manual_bounds.PT01b_Recovery_short.pw_head_data.min = -0.025;          % PW drawdown rate m/s (Figure 2 subplot 3) [flipped sign]
config.manual_bounds.PT01b_Recovery_short.pw_head_data.max = 0.076;
config.manual_bounds.PT01b_Recovery_short.displacement_rate_line.min = -0.5;  % DAS displacement rate nm/s (subplot 2 & 3)
config.manual_bounds.PT01b_Recovery_short.displacement_rate_line.max = -0.3;
config.manual_bounds.PT01b_Recovery_short.strain_line.min = -0.2;        % DAS strain nm/m (matches waterfall)
config.manual_bounds.PT01b_Recovery_short.strain_line.max = 0.2;
config.manual_bounds.PT01b_Recovery_short.head_data_strain.min = -0.0001;   % Head levels m/s (Figure 3 subplot 2) - monitoring wells only
config.manual_bounds.PT01b_Recovery_short.head_data_strain.max = 0.0003;
config.manual_bounds.PT01b_Recovery_short.depth_axis.min = 200;           % Depth axis ft
config.manual_bounds.PT01b_Recovery_short.depth_axis.max = 665;
config.manual_bounds.PT01b_Recovery_short.pw_head_strain.min = -0.025;     % Pumping well drawdown rate m/s (Figure 3 subplot 3) [flipped sign]
config.manual_bounds.PT01b_Recovery_short.pw_head_strain.max = 0.076;

%% Head Data Zone Configuration (per dataset)
% PT01a START OF PUMPING zone configuration  
config.head_zones.PT01a_start_of_pumping.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01a_start_of_pumping.display_mode = 'multiple';

% PT01c START OF PUMPING zone configuration
config.head_zones.PT01c_start_of_pumping.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01c_start_of_pumping.display_mode = 'multiple';

% PT01a_Recovery_short zone configuration (restored)
config.head_zones.PT01a_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01a_Recovery_short.display_mode = 'multiple';

% PT01c RECOVERY zone configuration
config.head_zones.PT01c_recovery.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01c_recovery.display_mode = 'multiple';

% PT01c_Recovery_short zone configuration (matches actual dataset name)
config.head_zones.PT01c_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01c_Recovery_short.display_mode = 'multiple';

% PT01a_Recovery_short zone configuration (matches actual dataset name)
config.head_zones.PT01a_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01a_Recovery_short.display_mode = 'multiple';

% PT01b START OF PUMPING zone configuration  
config.head_zones.PT01b_start_of_pumping.zones = {'z2', 'z3', 'z4', 'z5'};  % Zones 2-5 (pw has time mismatch - wrong time period)
config.head_zones.PT01b_start_of_pumping.display_mode = 'multiple';

% PT01b_Recovery_short zone configuration
config.head_zones.PT01b_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5', 'pw'};  % Zones 2-5 and pumping well
config.head_zones.PT01b_Recovery_short.display_mode = 'multiple';

%% Additional Configuration Parameters
config.apply_concatenation_filter = false;
config.filter_method = 'detrend';

%% Pixelation Testing Configuration
config.plot_method = 'pcolor';
config.shading_method = 'interp';
config.colormap_name = 'jet';
config.colormap_resolution = 256;
config.disable_analysis_smoothing = false;
config.smoothing_method = 'matlab_movmean';  % Apply moving mean
config.matlab_movmean_window = 30;  % 30-second window (at 1Hz sampling)

%% Storage Analysis Parameters (Traditional Pump Test Values for Comparison)
% From PT-01A Step Drawdown Test (10/24/23)
config.traditional_T_ft2_day = 9073.6;  % Transmissivity from traditional analysis
config.traditional_K_ft_day = 22.68;    % Hydraulic conductivity from traditional analysis  
config.traditional_S = 4.206e-5;        % Storativity from traditional analysis
config.aquifer_thickness_ft = 400;      % Saturated thickness (ft)
config.aquifer_thickness_m = 122;       % Saturated thickness (m)

%% Unit System Configuration
config.use_si_units = true;  % Set to true for SI units (m, m/s), false for imperial (ft, ft/min)

fprintf('✓ Batch configuration loaded (PT01a_start_of_pumping, PT01b_start_of_pumping, PT01c_start_of_pumping, PT01c_recovery, PT01a_Recovery_short, PT01b_Recovery_short, and PT01c_Recovery_short with corrected bounds)\n');

end
