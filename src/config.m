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
% config.decimation_factor = 10;   % Light decimation (100Hz → 10Hz) - TEST GRID PATTERN
config.decimation_factor = 100;  % Heavy decimation (100Hz → 1Hz)
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
config.dynamic_bounds = false;  % Use manual bounds (disable intelligent waterfall color bounds)

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
config.smoothing_method = 'none';             % 'movmean', 'movmedian', 'gaussian', 'none', 'chen', 'spatial_median', 'matlab_movmean'
config.smoothing_window_factor = 1.0;         % 0.5, 1.0, 2.0 (multiplier for default window size)

%% Advanced Filtering Configuration

% Chen et al. (2023) Complete Framework Configuration
config.chen_denoising = false;                     % Enable Chen et al. 3-stage denoising
config.chen_enable_stage1 = true;                  % Enable bandpass filtering
config.chen_enable_stage2 = true;                  % Enable SOMF filtering  
config.chen_enable_stage3 = true;                  % Enable F-K filtering
config.chen_sampling_rate = 1.0;                   % Sampling rate Hz (for filter design)

% Stage 1: Butterworth Bandpass Filter
config.chen_bandpass_low = 0.001;                  % Low frequency cutoff (Hz)
config.chen_bandpass_high = 0.4;                   % High frequency cutoff (Hz) 
config.chen_bandpass_order = 6;                    % Butterworth filter order

% Stage 2: Structure-Oriented Median Filter (SOMF)
config.chen_somf_window = 17;                      % SOMF window size (samples)
config.chen_somf_strength = 0.3;                   % Filter strength (0-1)
config.chen_somf_preserve = 0.7;                   % Signal preservation (0-1)
config.chen_somf_adaptive = true;                  % Use adaptive filtering
config.chen_somf_spatial_enhance = true;           % Apply spatial coherence enhancement

% Stage 3: F-K Domain Dip Filter (KEY for grid patterns)
config.chen_fk_strength = 0.02;                    % Filter strength (0-1) - Chen paper default
config.chen_fk_target_horizontal = true;           % Target horizontal noise (grid patterns)
config.chen_fk_target_vertical = true;             % Target vertical noise
config.chen_fk_preserve_signal = 0.8;              % Signal preservation (0-1)
config.chen_fk_taper_width = 0.1;                  % Taper width for smooth filtering

% Spatial Median Filter Configuration (Standalone)
config.spatial_filter_channels = 21;               % Channel window size (odd number)
config.spatial_filter_strength = 0.1;              % Filter strength (0-1)
config.spatial_filter_temporal = 3;                % Temporal smoothing window
config.spatial_filter_preserve = 0.9;              % Signal preservation (0-1)

% Temporal Filter Configuration
config.temporal_window = 10;                       % Window size for temporal filters

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

% TEST 2C: Use MATLAB movmean filter (like PM07_PT01a_Simple.m)
% config.smoothing_method = 'matlab_movmean';
% config.matlab_movmean_window = 10;

% TEST 3A: Fixed bounds instead of dynamic
% config.dynamic_bounds = false;

% TEST 4A: High resolution colormap (test if color quantization causes grid)
config.colormap_resolution = 1024;

%% Manual Plot Bounds (used when dynamic_bounds = false)
% Per-dataset, per-chart bounds configuration for all chart types
% Based on discovered data ranges: PT01a [-30.2, 41.5], PT01b [-29.9, 30.3], PT01c [-26.3, 25.2]
%
% Chart Types:
%   - raw_data:                Raw Data Waterfall (Figure 1)
%   - displacement_rate:       Displacement Rate Waterfall (Figure 2, top subplot)
%   - strain:                  Strain Waterfall (Figure 3, top subplot)
%   - head_data:               Head Data Line Chart Y-axis (yyaxis left)
%   - displacement_rate_line:  DAS Displacement Rate Line Chart Y-axis (yyaxis right, Figure 2 bottom)
%   - strain_line:             DAS Strain Line Chart Y-axis (yyaxis right, Figure 3 bottom)
%   - depth_axis:              Depth Y-axis for all waterfall charts

% ===== PT01a_Recovery_short bounds =====
config.manual_bounds.PT01a_Recovery_short.raw_data.min = -0.5;
config.manual_bounds.PT01a_Recovery_short.raw_data.max = 0.70;
config.manual_bounds.PT01a_Recovery_short.displacement_rate.min = 0.07;
config.manual_bounds.PT01a_Recovery_short.displacement_rate.max = 0.25;
config.manual_bounds.PT01a_Recovery_short.strain.min = -0.20;
config.manual_bounds.PT01a_Recovery_short.strain.max = 0.20;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01a_Recovery_short.head_data.min = 0.0;           % Head drawdown ft (yyaxis left)
config.manual_bounds.PT01a_Recovery_short.head_data.max = 0.10;
config.manual_bounds.PT01a_Recovery_short.displacement_rate_line.min = 0.07;  % DAS displacement rate nm/s (yyaxis right)
config.manual_bounds.PT01a_Recovery_short.displacement_rate_line.max = 0.25;
config.manual_bounds.PT01a_Recovery_short.strain_line.min = -0.20;         % DAS strain nm/m (yyaxis right)
config.manual_bounds.PT01a_Recovery_short.strain_line.max = 0.20;
config.manual_bounds.PT01a_Recovery_short.depth_axis.min = 100;           % Depth axis ft
config.manual_bounds.PT01a_Recovery_short.depth_axis.max = 665;

% ===== PT01b_Recovery_short bounds =====
config.manual_bounds.PT01b_Recovery_short.raw_data.min = -0.3;
config.manual_bounds.PT01b_Recovery_short.raw_data.max = 0.25;
config.manual_bounds.PT01b_Recovery_short.displacement_rate.min = -0.19;
config.manual_bounds.PT01b_Recovery_short.displacement_rate.max = -0.08;
config.manual_bounds.PT01b_Recovery_short.strain.min = -0.2;
config.manual_bounds.PT01b_Recovery_short.strain.max = 0.2;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01b_Recovery_short.head_data.min = -0.1;           % Head drawdown ft (yyaxis left)
config.manual_bounds.PT01b_Recovery_short.head_data.max = -0.02;
config.manual_bounds.PT01b_Recovery_short.displacement_rate_line.min = -0.19;  % DAS displacement rate nm/s (yyaxis right)
config.manual_bounds.PT01b_Recovery_short.displacement_rate_line.max = -0.08;
config.manual_bounds.PT01b_Recovery_short.strain_line.min = -0.2;         % DAS strain nm/m (yyaxis right)
config.manual_bounds.PT01b_Recovery_short.strain_line.max = 0.2;
config.manual_bounds.PT01b_Recovery_short.depth_axis.min = 100;           % Depth axis ft
config.manual_bounds.PT01b_Recovery_short.depth_axis.max = 665;

% ===== PT01c_Recovery_short bounds =====
config.manual_bounds.PT01c_Recovery_short.raw_data.min = -0.6;
config.manual_bounds.PT01c_Recovery_short.raw_data.max = 0.4;
config.manual_bounds.PT01c_Recovery_short.displacement_rate.min = -0.12;
config.manual_bounds.PT01c_Recovery_short.displacement_rate.max = 0.10;
config.manual_bounds.PT01c_Recovery_short.strain.min = -0.2;
config.manual_bounds.PT01c_Recovery_short.strain.max = 0.2;

% Line chart Y-axis bounds (for subplot line charts paired with waterfall charts)
config.manual_bounds.PT01c_Recovery_short.head_data.min = -0.16;           % Head drawdown ft (yyaxis left)
config.manual_bounds.PT01c_Recovery_short.head_data.max = -0.06;
config.manual_bounds.PT01c_Recovery_short.displacement_rate_line.min = -0.12;  % DAS displacement rate nm/s (yyaxis right)
config.manual_bounds.PT01c_Recovery_short.displacement_rate_line.max = 0.10;
config.manual_bounds.PT01c_Recovery_short.strain_line.min = -0.2;         % DAS strain nm/m (yyaxis right)
config.manual_bounds.PT01c_Recovery_short.strain_line.max = 0.2;
config.manual_bounds.PT01c_Recovery_short.depth_axis.min = 100;           % Depth axis ft
config.manual_bounds.PT01c_Recovery_short.depth_axis.max = 665;

% ===== Global fallback bounds (used if dataset-specific bounds not found) =====
%config.manual_bounds.global.raw_data.min = -0.25;
%config.manual_bounds.global.raw_data.max = 0.15;
%config.manual_bounds.global.displacement_rate.min = -0.25;
%config.manual_bounds.global.displacement_rate.max = 0.15;
%config.manual_bounds.global.strain.min = -3;
%config.manual_bounds.global.strain.max = 1;

% Global line chart Y-axis bounds (fallback when dataset-specific bounds not found)
%config.manual_bounds.global.head_data.min = -2.0;           % Head drawdown ft (yyaxis left)
%config.manual_bounds.global.head_data.max = 0.5;
%config.manual_bounds.global.displacement_rate_line.min = -0.25;  % DAS displacement rate nm/s (yyaxis right)
%config.manual_bounds.global.displacement_rate_line.max = 0.15;
%config.manual_bounds.global.strain_line.min = -3.0;         % DAS strain nm/m (yyaxis right)
%config.manual_bounds.global.strain_line.max = 1.0;
%config.manual_bounds.global.depth_axis.min = 100;           % Depth axis ft
%config.manual_bounds.global.depth_axis.max = 700;

%% TDMS Conversion Configuration
config.tdms_scaling_method = 'single_step';   % 'two_stage', 'single_step', 'double_precision'
config.tdms_adc_factor = 1/8192;              % ADC normalization factor
config.tdms_physical_factor = 116;            % Physical units conversion factor (nm/sample)
config.tdms_force_double = false;             % Force double precision during conversion

%% Filtering Configuration
config.apply_concatenation_filter = false;  % Apply post-processing filter to remove file boundary artifacts
config.filter_method = 'detrend';  % Filter method: 'none', 'detrend', 'highpass', 'median', 'overlap_smooth'

%% Ensemble Averaging Configuration (Signal Extraction)
% Multi-channel ensemble averaging for grid pattern mitigation
config.ensemble_zone_window = 50;         % Depth window for averaging (ft)
config.ensemble_signal_weight = 0.7;      % Weight for original vs ensemble (0-1)
config.ensemble_min_channels = 5;         % Minimum channels per zone for reliable averaging
config.ensemble_overlap_ratio = 0.3;      % Zone overlap for smooth transitions (0-0.5)

%% Dual Bandstop Filter Configuration (Targeted Grid Removal)
% Based on diagnostic analysis - removes specific grid pattern frequencies
config.slow_grid_low = 0.30;              % Hz - Slow grid pattern lower bound (target 0.35 Hz)
config.slow_grid_high = 0.40;             % Hz - Slow grid pattern upper bound (target 0.35 Hz)  
config.fast_grid_low = 0.395;             % Hz - Fast grid pattern lower bound
config.fast_grid_high = 0.473;            % Hz - Fast grid pattern upper bound
config.bandstop_order = 4;                % Filter order for bandstop filters

%% Moving Average Filter Configuration (Parameterized)
% This is the same filter used in basic 'run' mode, now controllable
config.movavg_window = 10;                % Window size for moving average (samples)
config.movavg_method = 'mean';            % 'mean' or 'median'
config.movavg_dimension = 1;              % 1=temporal, 2=spatial  
config.movavg_endpoints = 'shrink';       % 'shrink', 'fill', 'discard'

%% MATLAB movmean Filter Configuration (Direct MATLAB Implementation)
% Uses MATLAB's built-in movmean function directly (like PM07_PT01a_Simple.m)
config.matlab_movmean_window = 10;        % Window size for MATLAB movmean (samples)
config.matlab_movmean_dimension = 1;      % 1=temporal, 2=spatial
config.matlab_movmean_endpoints = 'shrink'; % 'shrink', 'fill', 'discard' (MATLAB nanflag options)

%% Head Data Zone Configuration (per dataset)
% Specify which zone(s) to display for head data overlay in plots
% Can be: 'all' (default), single zone string 'z3', or array {'z2', 'z3'}

% Default behavior: show zones z2, z3, z4, z5 (exclude z1)
config.head_zones.default.zones = {'z2', 'z3', 'z4', 'z5'};  % Exclude z1, show z2-z5
config.head_zones.default.display_mode = 'multiple';  % 'single', 'multiple', 'average'

% Dataset-specific overrides: Use consistent zones z2-z5 for all datasets
config.head_zones.PT01a_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5'};  % Exclude z1
config.head_zones.PT01a_Recovery_short.display_mode = 'multiple';

config.head_zones.PT01b_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5'};  % Exclude z1 
config.head_zones.PT01b_Recovery_short.display_mode = 'multiple';

config.head_zones.PT01c_Recovery_short.zones = {'z2', 'z3', 'z4', 'z5'};  % Already has z2-z5
config.head_zones.PT01c_Recovery_short.display_mode = 'multiple';

% config.head_zones.TEST.zones = 'z3';
% config.head_zones.TEST.display_mode = 'single';

fprintf('✓ Batch configuration loaded\n');

end
