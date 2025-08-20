function config = Recovery_Extract_Config()
%Recovery_Extract_Config - Configuration for recovery extract dataset
%
% This configuration is specifically for the recovery-focused TDMS files
% located in E:\PM_07 Step Test\MATLAB\recovery_extract\
%
% Key differences from main config:
% 1. Updated start times based on actual recovery extract filenames
% 2. Extended analysis windows to cover full recovery periods
% 3. Source data path points to recovery extract directory
%
% Usage: config = Recovery_Extract_Config();

%% =================================================================
%% RECOVERY EXTRACT TIME WINDOWS (based on filename analysis)
%% =================================================================

% PT-01a recovery extract window (from filenames: 20:34 to 20:54 UTC)
config.recovery_windows.a.start = datetime(2023,11,7,20,34,10,122,'TimeZone','UTC');  % First file
config.recovery_windows.a.end = datetime(2023,11,7,20,54,10,122,'TimeZone','UTC');    % Last file
config.recovery_windows.a.duration_min = 20;  % ~20 minute window

% PT-01b recovery extract window (from filenames: 19:19 to 19:39 UTC)  
config.recovery_windows.b.start = datetime(2023,10,31,19,19,47,754,'TimeZone','UTC'); % First file
config.recovery_windows.b.end = datetime(2023,10,31,19,39,47,754,'TimeZone','UTC');   % Last file
config.recovery_windows.b.duration_min = 20;  % ~20 minute window

% PT-01c recovery extract window (estimated based on pattern)
config.recovery_windows.c.start = datetime(2023,10,24,19,04,36,338,'TimeZone','UTC'); % Estimated
config.recovery_windows.c.end = datetime(2023,10,24,19,24,36,338,'TimeZone','UTC');   % Estimated
config.recovery_windows.c.duration_min = 20;  % ~20 minute window

%% =================================================================
%% SOURCE DATA PATHS (for recovery extract)
%% =================================================================

% Base directory for recovery extract TDMS files
config.source_data.base_dir = 'E:\PM_07 Step Test\MATLAB\recovery_extract\';

% TDMS source directories
config.source_data.tdms_dirs.a = fullfile(config.source_data.base_dir, 'PT01a_Recovery');
config.source_data.tdms_dirs.b = fullfile(config.source_data.base_dir, 'PT01b_Recovery');
config.source_data.tdms_dirs.c = fullfile(config.source_data.base_dir, 'PT01c_Recovery');

% Expected output MAT files after processing
config.source_data.output_files.a = 'PM07_01a_Recovery_1Hz.mat';
config.source_data.output_files.b = 'PM07_01b_Recovery_1Hz.mat';
config.source_data.output_files.c = 'PM07_01c_Recovery_1Hz.mat';

%% =================================================================
%% DAS TIMING CONFIGURATION (for recovery extract)
%% =================================================================

% DAS start times (extracted from first filename in each directory)
config.das_timing.a.start = datetime(2023,11,7,20,34,10,122,'TimeZone','UTC');  % PM07StepPT01a_UTC_20231107_203410.122.tdms
config.das_timing.a.source = 'recovery_extract_filename';
config.das_timing.a.first_file = 'PM07StepPT01a_UTC_20231107_203410.122.tdms';

config.das_timing.b.start = datetime(2023,10,31,19,19,47,754,'TimeZone','UTC'); % PM07StepPT01a_UTC_20231031_191947.754.tdms
config.das_timing.b.source = 'recovery_extract_filename';
config.das_timing.b.first_file = 'PM07StepPT01a_UTC_20231031_191947.754.tdms';

config.das_timing.c.start = datetime(2023,10,24,19,04,36,338,'TimeZone','UTC'); % Estimated based on pattern
config.das_timing.c.source = 'estimated_from_pattern';
config.das_timing.c.first_file = 'PM07StepPT01c_UTC_20231024_190436.338.tdms'; % Expected pattern

% Timing adjustments (keep same as main config for consistency)
config.das_timing.a.adjustment = 0;      % No adjustment for PT-01a
config.das_timing.b.adjustment = 120;    % Shift PT-01b DAS data by 2 minutes
config.das_timing.c.adjustment = 90;     % Adjust PT-01c DAS data by +90 seconds

%% =================================================================
%% DAS CALIBRATION (same as main config)
%% =================================================================

config.das_calibration.a.C1 = 513;         % Reference channel for PT-01a
config.das_calibration.a.MperChan = 0.25;  % Meters per channel

config.das_calibration.b.C1 = 513;         % Reference channel for PT-01b  
config.das_calibration.b.MperChan = 0.25;  % Meters per channel

config.das_calibration.c.C1 = 110;         % Reference channel for PT-01c
config.das_calibration.c.MperChan = 0.25;  % Meters per channel

%% =================================================================
%% PUMPING ZONE DEFINITIONS (same as main config)
%% =================================================================

config.pumping_zones.a.min_ft = 450;
config.pumping_zones.a.max_ft = 510;

config.pumping_zones.b.min_ft = 350;
config.pumping_zones.b.max_ft = 400;

config.pumping_zones.c.min_ft = 260;
config.pumping_zones.c.max_ft = 310;

%% =================================================================
%% PROCESSING PARAMETERS (for recovery extract)
%% =================================================================

% Decimation factor for ConcatDownsample.m
config.processing.decimation_factor = 100;  % Standard decimation

% Analysis parameters
config.analysis.smooth_window = 10;        % Moving average window for head data
config.analysis.das_smooth_window = 10;    % Moving average window for DAS data
config.analysis.head_timing_adjustment_c = 10;  % Add 10 seconds to PT-01c head data

% Display parameters
config.analysis.depth_range = [100 665];   % Depth range for plots (feet)

%% =================================================================
%% FILE PATTERNS AND VALIDATION
%% =================================================================

% Expected file patterns for validation
config.validation.file_pattern = 'PM07StepPT01*_UTC_*.tdms';
config.validation.expected_file_count.a = 21;  % Based on directory listing
config.validation.expected_file_count.b = 21;  % Based on directory listing  
config.validation.expected_file_count.c = 21;  % Estimated

% Time interval between files (for validation)
config.validation.file_interval_minutes = 1;   % 1-minute intervals

%% =================================================================
%% USAGE INSTRUCTIONS
%% =================================================================

% To use this config with the prep scripts:
%
% 1. Update Silixa_TDMSDataToPhysicalDispRate.m:
%    directory = config.source_data.tdms_dirs.a;  % (or .b, .c)
%
% 2. Update ConcatDownsample.m:
%    directory = 'path_to_processed_mat_files\';
%    outname = config.source_data.output_files.a;  % (or .b, .c)
%    r = config.processing.decimation_factor;
%
% 3. Update PM07_Recovery_Config.m (or create recovery-specific version):
%    config.das_timing.a.start = Recovery_Extract_Config().das_timing.a.start;

%% =================================================================
%% COMPARISON WITH ORIGINAL WINDOWS
%% =================================================================

% Original analysis windows (for reference):
config.original_windows.a.start = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
config.original_windows.a.end = datetime(2023,11,7,20,48,00,00,'TimeZone','UTC');
config.original_windows.a.duration_min = 4;

config.original_windows.b.start = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
config.original_windows.b.end = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');
config.original_windows.b.plot_start = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
config.original_windows.b.plot_end = datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');
config.original_windows.b.duration_min = 63;  % Full window
config.original_windows.b.plot_duration_min = 4;  % Plot window

config.original_windows.c.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.original_windows.c.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');
config.original_windows.c.duration_min = 4;

fprintf('Recovery Extract Config loaded:\n');
fprintf('  PT-01a: %d min window starting %s\n', config.recovery_windows.a.duration_min, config.recovery_windows.a.start);
fprintf('  PT-01b: %d min window starting %s\n', config.recovery_windows.b.duration_min, config.recovery_windows.b.start);
fprintf('  PT-01c: %d min window starting %s\n', config.recovery_windows.c.duration_min, config.recovery_windows.c.start);

end
