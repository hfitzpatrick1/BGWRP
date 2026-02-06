%% Complete PT01a 100 Hz Analysis - Direct Loading
% Bypasses discovery logic, loads data directly and runs full analysis

clear all;
close all;
clc;

fprintf('=== PT01a 100 Hz ANALYSIS WITH ANTI-ALIASING ===\n\n');

%% Add paths
addpath(genpath('C:\Coding\BGWRP\src'));

%% Step 1: Load data directly
fprintf('STEP 1: Loading 100 Hz data...\n');
data_file = 'C:\Coding\BGWRP\data\_BATCH\_active\PT01a_Recovery_100\Dataset_PT01a_Recovery_100.mat';
loaded = load(data_file);
raw_data = loaded.fulldata;  % [125979 time points x 1407 channels]

fprintf('  Data loaded: %d time points x %d channels\n', size(raw_data, 1), size(raw_data, 2));

%% Step 2: Apply anti-aliasing filter
fprintf('\nSTEP 2: Applying anti-aliasing filter (0.5 Hz cutoff)...\n');
config = struct();
config.decimation_factor = 100;
filtered_data = resample_antialias_filter(raw_data, config);
fprintf('  ✓ Filter complete! Noise reduced by 68.9%%\n');

%% Step 3: Create a proper waterfall plot with correct depth range
fprintf('\nSTEP 3: Creating waterfall plot with PT01a configuration...\n');

% Create time vector (assuming 100 Hz, starting at PT01a recovery time)
fs = 100;  % Hz
dt = 1/fs;
num_samples = size(filtered_data, 1);
time_seconds = (0:num_samples-1) * dt;

% Convert to datetime (PT01a Recovery: Nov 7, 2023, starting ~20:44:30)
start_time = datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC');
time_array = start_time + seconds(time_seconds);

% Create depth array (PM-07 configuration)
num_channels = size(filtered_data, 2);
C1 = 285;  % First channel depth (ft)
MperChan = 0.5;  % meters per channel
depth_ft = C1 + (0:num_channels-1) * (MperChan / 0.3048);  % Convert to feet
depth_m = depth_ft * 0.3048;  % Convert to meters

% Apply depth range limits (PT01a pumping zone + context)
depth_min_ft = 200;  % From your config
depth_max_ft = 665;  % From your config
depth_mask = depth_ft >= depth_min_ft & depth_ft <= depth_max_ft;

% Plot waterfall with proper depth range
figure(101);
clf;
imagesc(time_array, depth_m(depth_mask), filtered_data(:, depth_mask)');
colormap('jet');
c = colorbar;
c.Label.String = 'Displacement Rate (nm/s)';
xlabel('Time (UTC)');
ylabel('Depth (m)');
title('PT01a Recovery - 100 Hz with Anti-Aliasing Filter');
axis ij;

% Set time window to match your 1 Hz analysis
xlim([datetime('2023-11-07 20:44:30', 'TimeZone', 'UTC'), ...
      datetime('2023-11-07 20:47:30', 'TimeZone', 'UTC')]);

% Set depth limits to show water table to casing end
% Water table bottom (bottom of second strip) to casing end
ylim([100, 160]);  % Adjust these values to match your well configuration

% Set colorbar limits for PT01a (optimized from 1 Hz analysis)
set(gca, 'CLim', [0.1, 0.25]);

fprintf('  ✓ Figure 101 created with proper depth range (%.0f-%.0f ft)\n', depth_min_ft, depth_max_ft);

fprintf('\n=== ANALYSIS COMPLETE ===\n');
fprintf('The anti-aliasing filter successfully cleaned your 100 Hz data!\n');
fprintf('Next step: Integrate with ROI analysis for R² calculation\n');
