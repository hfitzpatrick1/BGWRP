function config = PM07_Recovery_Config()
%PM07_Recovery_Config - Configuration parameters for PM07 Recovery Analysis
%
% This function returns a structure containing all the hard-coded parameters
% that were previously embedded in PM07_Recovery_Analysis.m
%
% Usage: config = PM07_Recovery_Config();

%% =================================================================
%% RECOVERY TIME WINDOWS
%% =================================================================

% PT-01a recovery window
config.recovery_windows.a.start = datetime(2023,11,7,20,44,00,00,'TimeZone','UTC');
config.recovery_windows.a.end = datetime(2023,11,7,20,48,00,00,'TimeZone','UTC');

% PT-01b recovery window  
config.recovery_windows.b.start = datetime(2023,10,31,19,25,00,00,'TimeZone','UTC');
config.recovery_windows.b.end = datetime(2023,10,31,20,28,00,00,'TimeZone','UTC');

% PT-01b plot window (shortened for visualization)
config.recovery_windows.b.plot_start = datetime(2023,10,31,19,29,00,00,'TimeZone','UTC');
config.recovery_windows.b.plot_end = datetime(2023,10,31,19,33,00,00,'TimeZone','UTC');

% PT-01c recovery window
config.recovery_windows.c.start = datetime(2023,10,24,19,14,00,00,'TimeZone','UTC');
config.recovery_windows.c.end = datetime(2023,10,24,19,18,00,00,'TimeZone','UTC');

%% =================================================================
%% HEAD DATA FILE CONFIGURATION
%% =================================================================

% Define available head data files for each test
config.head_files.a = {'head_a_z2.mat', 'head_a_z3.mat', 'head_a_z4.mat', 'head_a_z5.mat'};
config.head_files.b = {'head_b_z2.mat', 'head_b_z3.mat', 'head_b_z4.mat', 'head_b_z5.mat'};
config.head_files.c = {'head_c_z2.mat', 'head_c_z3.mat', 'head_c_z4.mat', 'head_c_z5.mat'};

%% =================================================================
%% DAS DATA CONFIGURATION
%% =================================================================

% DAS data file paths (relative to data directory)
config.das_files.a = fullfile('DAS Data', 'PM07_01a_1Hz.mat');
config.das_files.b = fullfile('DAS Data', 'PM07_01b_1Hz.mat');
config.das_files.c = fullfile('DAS Data', 'PM07_01c_1Hz.mat');

% DAS start times (THESE ARE THE KEY PARAMETERS TO ADJUST FOR SUBSETS)
config.das_timing.a.start = datetime(2023,11,7,16,45,36,00,'TimeZone','UTC');
config.das_timing.b.start = datetime(2023,10,31,15,29,36,00,'TimeZone','UTC');
config.das_timing.c.start = datetime(2023,10,24,15,02,36,00,'TimeZone','UTC');

% DAS timing adjustments (in seconds)
config.das_timing.a.adjustment = 0;      % No adjustment for PT-01a
config.das_timing.b.adjustment = 120;    % Shift PT-01b DAS data by 2 minutes
config.das_timing.c.adjustment = 90;     % Adjust PT-01c DAS data by +90 seconds

% DAS channel calibration parameters
config.das_calibration.a.C1 = 513;         % Reference channel for PT-01a
config.das_calibration.a.MperChan = 0.25;  % Meters per channel

config.das_calibration.b.C1 = 513;         % Reference channel for PT-01b
config.das_calibration.b.MperChan = 0.25;  % Meters per channel

config.das_calibration.c.C1 = 110;         % Reference channel for PT-01c
config.das_calibration.c.MperChan = 0.25;  % Meters per channel

%% =================================================================
%% PUMPING ZONE DEFINITIONS
%% =================================================================

% Pumping zone depth ranges (in feet)
config.pumping_zones.a.min_ft = 450;
config.pumping_zones.a.max_ft = 510;

config.pumping_zones.b.min_ft = 350;
config.pumping_zones.b.max_ft = 400;

config.pumping_zones.c.min_ft = 260;
config.pumping_zones.c.max_ft = 310;

%% =================================================================
%% ANALYSIS PARAMETERS
%% =================================================================

% Signal processing parameters
config.analysis.smooth_window = 10;        % Moving average window for head data
config.analysis.das_smooth_window = 10;    % Moving average window for DAS data

% Head data timing adjustments
config.analysis.head_timing_adjustment_c = 10;  % Add 10 seconds to PT-01c head data

% Display and plotting parameters
config.analysis.depth_range = [100 665];   % Depth range for plots (feet)

% Color ranges for displacement rate plots
config.analysis.disp_rate_range.a = [0.35 0.55];   % PT-01a range (nm/s)
config.analysis.disp_rate_range.b = [-1.0 -0.8];   % PT-01b range (nm/s)
config.analysis.disp_rate_range.c = [-0.2 0.1];    % PT-01c range (nm/s)

% Recovery rate plot ranges
config.analysis.recovery_rate_range = [-0.0001 0.0008];  % m/s

%% =================================================================
%% DIRECTORY STRUCTURE
%% =================================================================

% Subdirectory names (relative to project data directory)
config.directories.head_data = 'head';
config.directories.das_data = 'DAS Data';

%% =================================================================
%% USAGE NOTES
%% =================================================================

% To modify for shorter time windows:
% 1. Update config.das_timing.X.start to match your actual data start time
% 2. Optionally adjust config.recovery_windows.X.start/end to focus on specific periods
% 3. The recovery windows should be within your actual data time range

end
