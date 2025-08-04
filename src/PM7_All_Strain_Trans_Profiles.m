%% Combined Strain Profile Analysis - PM7 Well
% Shows drawdown and strain profiles for all three pump tests at PM7
% with overlaid strain comparisons

clear; clc; close all

%% 1. Setup paths and load data
fprintf('=== LOADING DATA ===\n');

% Get the directory where this script is located
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load DAS data files
pt01a_file = fullfile(data_dir, 'PM07_01a_1Hz.mat');
pt01b_file = fullfile(data_dir, 'PM07_01b_1Hz.mat');
pt01c_file = fullfile(data_dir, 'PM07_01c_1Hz.mat');
channel_file = fullfile(data_dir, 'Channel1_alldataupto070224.mat');

% Load transducer data files (PM7 well - all 5 zones)
% PM7 A files (Nov 7, 2023)
trans01a_z1_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_1_SDT_PT-01a.csv');
trans01a_z2_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_2_SDT_PT-01a.csv');
trans01a_z3_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_3_SDT_PT-01a.csv');
trans01a_z4_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_4_SDT_PT-01a.csv');
trans01a_z5_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_5_SDT_PT-01a.csv');

% PM7 B files (Oct 31, 2023)
trans01b_z1_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_1_SDT_PT-01b.csv');
trans01b_z2_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_2_SDT_PT-01b.csv');
trans01b_z3_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_3_SDT_PT-01b.csv');
trans01b_z4_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_4_SDT_PT-01b.csv');
trans01b_z5_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_5_SDT_PT-01b.csv');

% PM7 C files (Oct 24, 2023) - Zone 1 removed due to incomplete data, all zones use "SDT"
trans01c_z2_file = fullfile(data_dir, 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_2_SDT_PT-01c.csv');
trans01c_z3_file = fullfile(data_dir, 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_3_SDT_PT-01c.csv');
trans01c_z4_file = fullfile(data_dir, 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_4_SDT_PT-01c.csv');
trans01c_z5_file = fullfile(data_dir, 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_5_SDT_PT-01c.csv');

% Check all files exist
required_files = {pt01a_file, pt01b_file, pt01c_file, channel_file, ...
                 trans01a_z1_file, trans01a_z2_file, trans01a_z3_file, trans01a_z4_file, trans01a_z5_file, ...
                 trans01b_z1_file, trans01b_z2_file, trans01b_z3_file, trans01b_z4_file, trans01b_z5_file, ...
                 trans01c_z2_file, trans01c_z3_file, trans01c_z4_file, trans01c_z5_file};
for i = 1:length(required_files)
    if ~exist(required_files{i}, 'file')
        error('❌ Required file not found: %s', required_files{i});
    end
end

% Load DAS data
load(pt01a_file); data_01a = decdata; clear decdata;
load(pt01b_file); data_01b = decdata; clear decdata;
load(pt01c_file); data_01c = decdata; clear decdata;
ld = load(channel_file);
DTS_depth_ft = ld.distance*3.28084;

% Memory optimization: Downsample DAS data to reduce memory usage
% Take every 10th point (from 1Hz to 0.1Hz) to reduce memory by ~90%
downsample_factor = 10;
data_01a = data_01a(1:downsample_factor:end, :);
data_01b = data_01b(1:downsample_factor:end, :);
data_01c = data_01c(1:downsample_factor:end, :);

fprintf('✓ Loaded all DAS data files\n');
fprintf('✓ Downsampled DAS data by factor of %d to reduce memory usage\n', downsample_factor);

%% 2. Process each dataset with consistent parameters
% Common parameters
C1 = 110; BOT = 920; well_depth_ft = 665; water_table_depth_ft = 89;
dx_m = 0.25; dx_ft = dx_m*3.28084;

% Function to process DAS data
function [Tdas, strain_pump_zone] = process_das_data(data, start_time, pump_zone_top, pump_zone_bot, downsample_factor)
    % Depth control
    DAS_depth_ft = ((0:size(data,2)-1).*0.25)*3.28084;
    raw_depth_ft = DAS_depth_ft - DAS_depth_ft(110);  % C1 = 110
    scale = 665/raw_depth_ft(920);  % well_depth_ft/raw_depth_ft(BOT)
    final_depth_ft = raw_depth_ft*scale;
    
    % Time axis (accounting for downsampling)
    Tdas = start_time + seconds((0:size(data,1)-1) * downsample_factor);
    
    % Focus on well casing region
    roi = final_depth_ft>=90 & final_depth_ft<=665;
    depth_roi = final_depth_ft(roi);
    
    % Common mode removal
    data_cleaned = zeros(size(data));
    for ch = 1:size(data, 2)
        channel_data = data(:, ch);
        temporal_mean = mean(channel_data, 'omitnan');
        data_cleaned(:, ch) = channel_data - temporal_mean;
    end
    
    % Integration and baseline
    intdata = cumtrapz(data_cleaned, 1);
    idata_roi = intdata(:, roi);
    
    % Calculate baseline (first 5 minutes)
    baseline = mean(idata_roi(1:300,:), 1, 'omitnan');  % 300 seconds = 5 minutes
    dstrain = idata_roi - baseline;
    
    % Extract pumping zone data
    pump_zone_mask = depth_roi >= pump_zone_top & depth_roi <= pump_zone_bot;
    strain_pump_zone = mean(dstrain(:, pump_zone_mask), 2, 'omitnan');
end

% Function to load and process transducer data
function [trans_time_utc, drawdown_ft, pressure_psi, depth_ft_raw] = load_transducer_data(filename)
    % Read CSV file, skipping header lines
    fid = fopen(filename, 'r');
    line_count = 0;
    while ~feof(fid)
        line = fgetl(fid);
        line_count = line_count + 1;
        if contains(line, 'Date Time') && contains(line, 'Depth')
            break;
        end
    end
    fclose(fid);
    
    % Read the actual data
    opts = detectImportOptions(filename);
    opts.DataLines = [line_count+1, inf];
    opts.VariableNames = {'DateTime', 'Pressure_psi', 'Temperature_C', 'Depth_ft'};
    
    trans_data = readtable(filename, opts);
    
    % Convert datetime
    trans_time = datetime(trans_data.DateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    trans_time.TimeZone = 'America/Los_Angeles';  % Local time
    trans_time_utc = trans_time;
    trans_time_utc.TimeZone = 'UTC';  % This automatically converts to UTC
    
    fprintf('  First time local: %s\n', datestr(trans_time(1)));
    fprintf('  First time UTC: %s\n', datestr(trans_time_utc(1)));
    
    % Extract data
    depth_ft = trans_data.Depth_ft;
    pressure_psi = trans_data.Pressure_psi;
    
    % Find baseline before pumping starts
    % Use first 60 points as baseline (matching working scripts)
    baseline_depth = mean(depth_ft(1:60), 'omitnan');
    % Positive = deeper water level (more drawdown)
    drawdown_ft = depth_ft - baseline_depth;
    
    % Debug output
    fprintf('Transducer data from %s:\n', filename);
    fprintf('  Time range: %s to %s\n', datestr(min(trans_time_utc)), datestr(max(trans_time_utc)));
    fprintf('  Baseline depth: %.2f ft\n', baseline_depth);
    fprintf('  Max drawdown: %.2f ft\n', max(drawdown_ft));
    fprintf('  Pressure range: %.2f - %.2f psi\n', min(pressure_psi), max(pressure_psi));
    fprintf('  Data points: %d\n', length(drawdown_ft));
    
    % Return raw depth data for potential recalculation
    depth_ft_raw = depth_ft;
end

% Function to recalculate drawdown with filtered baseline
function [drawdown_filt, baseline_depth_filt] = recalculate_drawdown_with_filtered_baseline(trans_time, depth_ft, start_time, duration_hours, duration_minutes, duration_seconds)
    % Filter the data first
    [trans_time_filt, depth_ft_filt] = filter_by_duration(trans_time, depth_ft, start_time, duration_hours, duration_minutes, duration_seconds);
    
    % Calculate baseline using first 60 points of filtered data
    baseline_depth_filt = mean(depth_ft_filt(1:60), 'omitnan');
    
    % Recalculate drawdown using filtered baseline
    drawdown_filt = depth_ft_filt - baseline_depth_filt;
    
    fprintf('  Recalculated baseline: %.2f ft (from filtered data)\n', baseline_depth_filt);
end

% Function to apply Savitzky-Golay smoothing to transducer data
function [smoothed_data] = smooth_transducer_data(data, window_size, poly_order, data_name)
    % Apply Savitzky-Golay smoothing
    smoothed_data = sgolayfilt(data, poly_order, window_size);
    
    fprintf('  Applied Savitzky-Golay smoothing to %s:\n', data_name);
    fprintf('    Window size: %d points (%.1f minutes at 5-sec intervals)\n', window_size, window_size * 5 / 60);
    fprintf('    Polynomial order: %d\n', poly_order);
    fprintf('    Data points: %d (original) -> %d (smoothed)\n', length(data), length(smoothed_data));
end

% Process PM7 A data (Nov 7, 2023 test)
[Tdas_01a, strain_01a] = process_das_data(data_01a, ...
    datetime(2023,11,7,16,51,49,'TimeZone','UTC'), 450, 510, downsample_factor);

% Load all 5 zones for PM7 A
[trans_time_01a_z1, drawdown_01a_z1, pressure_01a_z1, depth_01a_z1_raw] = load_transducer_data(trans01a_z1_file);
[trans_time_01a_z2, drawdown_01a_z2, pressure_01a_z2, depth_01a_z2_raw] = load_transducer_data(trans01a_z2_file);
[trans_time_01a_z3, drawdown_01a_z3, pressure_01a_z3, depth_01a_z3_raw] = load_transducer_data(trans01a_z3_file);
[trans_time_01a_z4, drawdown_01a_z4, pressure_01a_z4, depth_01a_z4_raw] = load_transducer_data(trans01a_z4_file);
[trans_time_01a_z5, drawdown_01a_z5, pressure_01a_z5, depth_01a_z5_raw] = load_transducer_data(trans01a_z5_file);

% Process PM7 B data (Oct 31, 2023 test)
[Tdas_01b, strain_01b] = process_das_data(data_01b, ...
    datetime(2023,10,31,15,20,24,'TimeZone','UTC'), 450, 510, downsample_factor);

% Load all 5 zones for PM7 B
[trans_time_01b_z1, drawdown_01b_z1, pressure_01b_z1, depth_01b_z1_raw] = load_transducer_data(trans01b_z1_file);
[trans_time_01b_z2, drawdown_01b_z2, pressure_01b_z2, depth_01b_z2_raw] = load_transducer_data(trans01b_z2_file);
[trans_time_01b_z3, drawdown_01b_z3, pressure_01b_z3, depth_01b_z3_raw] = load_transducer_data(trans01b_z3_file);
[trans_time_01b_z4, drawdown_01b_z4, pressure_01b_z4, depth_01b_z4_raw] = load_transducer_data(trans01b_z4_file);
[trans_time_01b_z5, drawdown_01b_z5, pressure_01b_z5, depth_01b_z5_raw] = load_transducer_data(trans01b_z5_file);

% Process PM7 C data (Oct 24, 2023 test)
[Tdas_01c, strain_01c] = process_das_data(data_01c, ...
    datetime(2023,10,24,15,18,36,'TimeZone','UTC'), 450, 510, downsample_factor);

% Load zones 2-5 for PM7 C (Zone 1 removed due to incomplete data)
[trans_time_01c_z2, drawdown_01c_z2, pressure_01c_z2, depth_01c_z2_raw] = load_transducer_data(trans01c_z2_file);
[trans_time_01c_z3, drawdown_01c_z3, pressure_01c_z3, depth_01c_z3_raw] = load_transducer_data(trans01c_z3_file);
[trans_time_01c_z4, drawdown_01c_z4, pressure_01c_z4, depth_01c_z4_raw] = load_transducer_data(trans01c_z4_file);
[trans_time_01c_z5, drawdown_01c_z5, pressure_01c_z5, depth_01c_z5_raw] = load_transducer_data(trans01c_z5_file);

%% 2.5. Apply time filtering to standardize datasets
fprintf('\n=== APPLYING TIME FILTERING ===\n');

% Define start times for each test (when pumping started)
start_time_01a = datetime(2023,11,7,16,45,0,'TimeZone','UTC');  % PM7 A pump start
start_time_01b = datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % PM7 B pump start  
start_time_01c = datetime(2023,10,24,15,18,0,'TimeZone','UTC');  % PM7 C pump start

% Filter PM7 A data - truncate to 6 hours or specific end times
fprintf('Filtering PM7 A data:\n');
[trans_time_01a_z1_filt, drawdown_01a_z1_filt] = filter_by_duration(trans_time_01a_z1, drawdown_01a_z1, start_time_01a, 5, 55, 46);
[trans_time_01a_z2_filt, drawdown_01a_z2_filt] = filter_by_duration(trans_time_01a_z2, drawdown_01a_z2, start_time_01a, 6, 0, 0);
[trans_time_01a_z3_filt, drawdown_01a_z3_filt] = filter_by_duration(trans_time_01a_z3, drawdown_01a_z3, start_time_01a, 6, 0, 0);
[trans_time_01a_z4_filt, drawdown_01a_z4_filt] = filter_by_duration(trans_time_01a_z4, drawdown_01a_z4, start_time_01a, 6, 0, 0);
[trans_time_01a_z5_filt, drawdown_01a_z5_filt] = filter_by_duration(trans_time_01a_z5, drawdown_01a_z5, start_time_01a, 6, 0, 0);

% Filter PM7 B data - truncate to 6 hours or specific end times
fprintf('Filtering PM7 B data:\n');
[trans_time_01b_z1_filt, drawdown_01b_z1_filt] = filter_by_duration(trans_time_01b_z1, drawdown_01b_z1, start_time_01b, 5, 44, 16);
[trans_time_01b_z2_filt, drawdown_01b_z2_filt] = filter_by_duration(trans_time_01b_z2, drawdown_01b_z2, start_time_01b, 5, 50, 36);
[trans_time_01b_z3_filt, drawdown_01b_z3_filt] = filter_by_duration(trans_time_01b_z3, drawdown_01b_z3, start_time_01b, 5, 55, 26);

% Special handling for Zone 4 Test B - recalculate drawdown with filtered baseline
fprintf('Special handling for Zone 4 Test B:\n');
[trans_time_01b_z4_filt, depth_01b_z4_filt] = filter_by_duration(trans_time_01b_z4, depth_01b_z4_raw, start_time_01b, 5, 25, 0);
[drawdown_01b_z4_filt, baseline_01b_z4_filt] = recalculate_drawdown_with_filtered_baseline(trans_time_01b_z4, depth_01b_z4_raw, start_time_01b, 5, 25, 0);

[trans_time_01b_z5_filt, drawdown_01b_z5_filt] = filter_by_duration(trans_time_01b_z5, drawdown_01b_z5, start_time_01b, 6, 0, 0);

% Filter PM7 C data - truncate to 6 hours (Zone 1 already removed)
fprintf('Filtering PM7 C data:\n');
[trans_time_01c_z2_filt, drawdown_01c_z2_filt] = filter_by_duration(trans_time_01c_z2, drawdown_01c_z2, start_time_01c, 6, 0, 0);
[trans_time_01c_z3_filt, drawdown_01c_z3_filt] = filter_by_duration(trans_time_01c_z3, drawdown_01c_z3, start_time_01c, 6, 0, 0);
[trans_time_01c_z4_filt, drawdown_01c_z4_filt] = filter_by_duration(trans_time_01c_z4, drawdown_01c_z4, start_time_01c, 6, 0, 0);
[trans_time_01c_z5_filt, drawdown_01c_z5_filt] = filter_by_duration(trans_time_01c_z5, drawdown_01c_z5, start_time_01c, 6, 0, 0);

% Also filter pressure data with same time windows
fprintf('Filtering pressure data:\n');
[~, pressure_01a_z1_filt] = filter_by_duration(trans_time_01a_z1, pressure_01a_z1, start_time_01a, 5, 55, 46);
[~, pressure_01a_z2_filt] = filter_by_duration(trans_time_01a_z2, pressure_01a_z2, start_time_01a, 6, 0, 0);
[~, pressure_01a_z3_filt] = filter_by_duration(trans_time_01a_z3, pressure_01a_z3, start_time_01a, 6, 0, 0);
[~, pressure_01a_z4_filt] = filter_by_duration(trans_time_01a_z4, pressure_01a_z4, start_time_01a, 6, 0, 0);
[~, pressure_01a_z5_filt] = filter_by_duration(trans_time_01a_z5, pressure_01a_z5, start_time_01a, 6, 0, 0);

[~, pressure_01b_z1_filt] = filter_by_duration(trans_time_01b_z1, pressure_01b_z1, start_time_01b, 5, 44, 16);
[~, pressure_01b_z2_filt] = filter_by_duration(trans_time_01b_z2, pressure_01b_z2, start_time_01b, 5, 50, 36);
[~, pressure_01b_z3_filt] = filter_by_duration(trans_time_01b_z3, pressure_01b_z3, start_time_01b, 5, 55, 26);
[~, pressure_01b_z4_filt] = filter_by_duration(trans_time_01b_z4, pressure_01b_z4, start_time_01b, 5, 25, 0);
[~, pressure_01b_z5_filt] = filter_by_duration(trans_time_01b_z5, pressure_01b_z5, start_time_01b, 6, 0, 0);

[~, pressure_01c_z2_filt] = filter_by_duration(trans_time_01c_z2, pressure_01c_z2, start_time_01c, 6, 0, 0);
[~, pressure_01c_z3_filt] = filter_by_duration(trans_time_01c_z3, pressure_01c_z3, start_time_01c, 6, 0, 0);
[~, pressure_01c_z4_filt] = filter_by_duration(trans_time_01c_z4, pressure_01c_z4, start_time_01c, 6, 0, 0);
[~, pressure_01c_z5_filt] = filter_by_duration(trans_time_01c_z5, pressure_01c_z5, start_time_01c, 6, 0, 0);

%% 2.6. Apply smoothing to transducer data
fprintf('\n=== APPLYING SMOOTHING TO TRANSDUCER DATA ===\n');

% Define smoothing parameters
smooth_window = 21;  % 21 points = 1 minute 45 seconds at 5-sec intervals
smooth_poly_order = 3;  % Polynomial order for Savitzky-Golay

fprintf('Smoothing parameters: Window=%d points (%.1f min), Polynomial order=%d\n', ...
        smooth_window, smooth_window * 5 / 60, smooth_poly_order);

% Apply smoothing to PM7 A drawdown data
fprintf('\nSmoothing PM7 A drawdown data:\n');
drawdown_01a_z1_smooth = smooth_transducer_data(drawdown_01a_z1_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 1 drawdown');
drawdown_01a_z2_smooth = smooth_transducer_data(drawdown_01a_z2_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 2 drawdown');
drawdown_01a_z3_smooth = smooth_transducer_data(drawdown_01a_z3_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 3 drawdown');
drawdown_01a_z4_smooth = smooth_transducer_data(drawdown_01a_z4_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 4 drawdown');
drawdown_01a_z5_smooth = smooth_transducer_data(drawdown_01a_z5_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 5 drawdown');

% Apply smoothing to PM7 B drawdown data
fprintf('\nSmoothing PM7 B drawdown data:\n');
drawdown_01b_z1_smooth = smooth_transducer_data(drawdown_01b_z1_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 1 drawdown');
drawdown_01b_z2_smooth = smooth_transducer_data(drawdown_01b_z2_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 2 drawdown');
drawdown_01b_z3_smooth = smooth_transducer_data(drawdown_01b_z3_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 3 drawdown');
drawdown_01b_z4_smooth = smooth_transducer_data(drawdown_01b_z4_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 4 drawdown');
drawdown_01b_z5_smooth = smooth_transducer_data(drawdown_01b_z5_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 5 drawdown');

% Apply smoothing to PM7 C drawdown data (zones 2-5 only)
fprintf('\nSmoothing PM7 C drawdown data:\n');
drawdown_01c_z2_smooth = smooth_transducer_data(drawdown_01c_z2_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 2 drawdown');
drawdown_01c_z3_smooth = smooth_transducer_data(drawdown_01c_z3_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 3 drawdown');
drawdown_01c_z4_smooth = smooth_transducer_data(drawdown_01c_z4_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 4 drawdown');
drawdown_01c_z5_smooth = smooth_transducer_data(drawdown_01c_z5_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 5 drawdown');

% Apply smoothing to pressure data
fprintf('\nSmoothing pressure data:\n');
pressure_01a_z1_smooth = smooth_transducer_data(pressure_01a_z1_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 1 pressure');
pressure_01a_z2_smooth = smooth_transducer_data(pressure_01a_z2_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 2 pressure');
pressure_01a_z3_smooth = smooth_transducer_data(pressure_01a_z3_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 3 pressure');
pressure_01a_z4_smooth = smooth_transducer_data(pressure_01a_z4_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 4 pressure');
pressure_01a_z5_smooth = smooth_transducer_data(pressure_01a_z5_filt, smooth_window, smooth_poly_order, 'PM7 A Zone 5 pressure');

pressure_01b_z1_smooth = smooth_transducer_data(pressure_01b_z1_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 1 pressure');
pressure_01b_z2_smooth = smooth_transducer_data(pressure_01b_z2_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 2 pressure');
pressure_01b_z3_smooth = smooth_transducer_data(pressure_01b_z3_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 3 pressure');
pressure_01b_z4_smooth = smooth_transducer_data(pressure_01b_z4_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 4 pressure');
pressure_01b_z5_smooth = smooth_transducer_data(pressure_01b_z5_filt, smooth_window, smooth_poly_order, 'PM7 B Zone 5 pressure');

pressure_01c_z2_smooth = smooth_transducer_data(pressure_01c_z2_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 2 pressure');
pressure_01c_z3_smooth = smooth_transducer_data(pressure_01c_z3_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 3 pressure');
pressure_01c_z4_smooth = smooth_transducer_data(pressure_01c_z4_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 4 pressure');
pressure_01c_z5_smooth = smooth_transducer_data(pressure_01c_z5_filt, smooth_window, smooth_poly_order, 'PM7 C Zone 5 pressure');

% Function to filter data by time duration
function [filtered_time, filtered_data] = filter_by_duration(time, data, start_time, duration_hours, duration_minutes, duration_seconds)
    % Calculate end time based on duration
    end_time = start_time + hours(duration_hours) + minutes(duration_minutes) + seconds(duration_seconds);
    
    % Filter data within the time range
    time_mask = time >= start_time & time <= end_time;
    filtered_time = time(time_mask);
    filtered_data = data(time_mask);
    
    fprintf('  Filtered data: %s to %s (%.1f hours)\n', ...
            datestr(min(filtered_time)), datestr(max(filtered_time)), ...
            hours(max(filtered_time) - min(filtered_time)));
end

% Function to interpolate data between time grids
function data_interp = interpolate_drawdown(source_time, source_data, target_time)
    % Check input sizes
    if length(source_time) ~= length(source_data)
        data_interp = NaN(size(target_time));
        return;
    end
    
    % Remove NaN and infinite values from source data
    valid_mask = isfinite(source_time) & isfinite(source_data);
    
    % Ensure we don't exceed array bounds
    if length(valid_mask) > length(source_time) || length(valid_mask) > length(source_data)
        valid_mask = valid_mask(1:min(length(source_time), length(source_data)));
    end
    
    if sum(valid_mask) < 2
        data_interp = NaN(size(target_time));
        return;
    end
    
    % Extract valid data using explicit indexing to avoid bounds issues
    valid_indices = find(valid_mask);
    if isempty(valid_indices)
        data_interp = NaN(size(target_time));
        return;
    end
    
    % Ensure indices don't exceed array bounds
    max_valid_index = min(length(source_time), length(source_data));
    valid_indices = valid_indices(valid_indices <= max_valid_index);
    
    if isempty(valid_indices)
        data_interp = NaN(size(target_time));
        return;
    end
    
    trans_clean = source_time(valid_indices);
    data_clean = source_data(valid_indices);
    
    % Sort by time
    [trans_clean, sort_idx] = sort(trans_clean);
    data_clean = data_clean(sort_idx);
    
    % Initialize with NaN
    data_interp = NaN(size(target_time));
    
    % Find the time range where we have actual data
    min_time = min(trans_clean);
    max_time = max(trans_clean);
    
    % Only interpolate within the actual data range
    valid_target_mask = target_time >= min_time & target_time <= max_time;
    if sum(valid_target_mask) > 0
        data_interp(valid_target_mask) = interp1(trans_clean, data_clean, target_time(valid_target_mask), 'linear');
    end
end

% Create interpolated DAS strain to transducer time grid (preserves hydraulic delays)
% PM7 A - interpolate DAS strain to each zone's time grid
strain_01a_z1_interp = interpolate_drawdown(Tdas_01a, strain_01a, trans_time_01a_z1_filt);
strain_01a_z2_interp = interpolate_drawdown(Tdas_01a, strain_01a, trans_time_01a_z2_filt);
strain_01a_z3_interp = interpolate_drawdown(Tdas_01a, strain_01a, trans_time_01a_z3_filt);
strain_01a_z4_interp = interpolate_drawdown(Tdas_01a, strain_01a, trans_time_01a_z4_filt);
strain_01a_z5_interp = interpolate_drawdown(Tdas_01a, strain_01a, trans_time_01a_z5_filt);

% PM7 B - interpolate DAS strain to each zone's time grid
strain_01b_z1_interp = interpolate_drawdown(Tdas_01b, strain_01b, trans_time_01b_z1_filt);
strain_01b_z2_interp = interpolate_drawdown(Tdas_01b, strain_01b, trans_time_01b_z2_filt);
strain_01b_z3_interp = interpolate_drawdown(Tdas_01b, strain_01b, trans_time_01b_z3_filt);
strain_01b_z4_interp = interpolate_drawdown(Tdas_01b, strain_01b, trans_time_01b_z4_filt);
strain_01b_z5_interp = interpolate_drawdown(Tdas_01b, strain_01b, trans_time_01b_z5_filt);

% PM7 C - interpolate DAS strain to each zone's time grid
strain_01c_z2_interp = interpolate_drawdown(Tdas_01c, strain_01c, trans_time_01c_z2_filt);
strain_01c_z3_interp = interpolate_drawdown(Tdas_01c, strain_01c, trans_time_01c_z3_filt);
strain_01c_z4_interp = interpolate_drawdown(Tdas_01c, strain_01c, trans_time_01c_z4_filt);
strain_01c_z5_interp = interpolate_drawdown(Tdas_01c, strain_01c, trans_time_01c_z5_filt);

% Create interpolated pressure for all PM7 zones using SMOOTHED data
% PM7 A - all 5 zones
pressure_01a_z1_interp = interpolate_drawdown(trans_time_01a_z1_filt, pressure_01a_z1_smooth, Tdas_01a);
pressure_01a_z2_interp = interpolate_drawdown(trans_time_01a_z2_filt, pressure_01a_z2_smooth, Tdas_01a);
pressure_01a_z3_interp = interpolate_drawdown(trans_time_01a_z3_filt, pressure_01a_z3_smooth, Tdas_01a);
pressure_01a_z4_interp = interpolate_drawdown(trans_time_01a_z4_filt, pressure_01a_z4_smooth, Tdas_01a);
pressure_01a_z5_interp = interpolate_drawdown(trans_time_01a_z5_filt, pressure_01a_z5_smooth, Tdas_01a);

% PM7 B - all 5 zones
pressure_01b_z1_interp = interpolate_drawdown(trans_time_01b_z1_filt, pressure_01b_z1_smooth, Tdas_01b);
pressure_01b_z2_interp = interpolate_drawdown(trans_time_01b_z2_filt, pressure_01b_z2_smooth, Tdas_01b);
pressure_01b_z3_interp = interpolate_drawdown(trans_time_01b_z3_filt, pressure_01b_z3_smooth, Tdas_01b);
pressure_01b_z4_interp = interpolate_drawdown(trans_time_01b_z4_filt, pressure_01b_z4_smooth, Tdas_01b);
pressure_01b_z5_interp = interpolate_drawdown(trans_time_01b_z5_filt, pressure_01b_z5_smooth, Tdas_01b);

% PM7 C - zones 2-5 (Zone 1 removed due to incomplete data)
pressure_01c_z2_interp = interpolate_drawdown(trans_time_01c_z2_filt, pressure_01c_z2_smooth, Tdas_01c);
pressure_01c_z3_interp = interpolate_drawdown(trans_time_01c_z3_filt, pressure_01c_z3_smooth, Tdas_01c);
pressure_01c_z4_interp = interpolate_drawdown(trans_time_01c_z4_filt, pressure_01c_z4_smooth, Tdas_01c);
pressure_01c_z5_interp = interpolate_drawdown(trans_time_01c_z5_filt, pressure_01c_z5_smooth, Tdas_01c);

fprintf('✓ Processed all datasets\n');

%% 3. Create comparison plots
fprintf('\n=== CREATING COMPARISON PLOTS ===\n');

% Figure settings
figure('Position', [100, 100, 1200, 900]);

% Define colors and depths for each zone (used in all plots)
zone_colors = [0 0 1; 0 0.7 0; 1 0.5 0; 0.7 0 0.7; 0 0.7 0.7]; % Blue, Green, Orange, Purple, Cyan
zone_depths = {'645-665 ft', '485-505 ft', '420-440 ft', '360-380 ft', '290-310 ft'};

% Use full datasets - no trimming
% This will show the complete time series like in your example

% Adjust plot styles and time alignment
% Ensure both DAS and transducer data are in UTC

% Plot 1: PM7 A DAS and all 5 zones (using transducer timestamps)
subplot(3,1,1)
yyaxis left
plot(trans_time_01a_z1_filt, strain_01a_z1_interp, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot all 5 zones using their actual timestamps
if ~isempty(drawdown_01a_z1_smooth)
    plot(trans_time_01a_z1_filt, drawdown_01a_z1_smooth, 'Color', zone_colors(1,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 1 drawdown: %d points\n', length(drawdown_01a_z1_smooth));
end
if ~isempty(drawdown_01a_z2_smooth)
    plot(trans_time_01a_z2_filt, drawdown_01a_z2_smooth, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 2 drawdown: %d points\n', length(drawdown_01a_z2_smooth));
end
if ~isempty(drawdown_01a_z3_smooth)
    plot(trans_time_01a_z3_filt, drawdown_01a_z3_smooth, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 3 drawdown: %d points\n', length(drawdown_01a_z3_smooth));
end
if ~isempty(drawdown_01a_z4_smooth)
    plot(trans_time_01a_z4_filt, drawdown_01a_z4_smooth, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 4 drawdown: %d points\n', length(drawdown_01a_z4_smooth));
end
if ~isempty(drawdown_01a_z5_smooth)
    plot(trans_time_01a_z5_filt, drawdown_01a_z5_smooth, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 A Zone 5 drawdown: %d points\n', length(drawdown_01a_z5_smooth));
end
hold off

ylabel('Drawdown (ft)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 A: DAS Strain vs All Zone Drawdowns')
grid on
legend({'PM7 A Strain', ['Zone 1 (' zone_depths{1} ')'], ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 A
hold on
% PM7 A pump times (UTC)
pump_times_01a = [
    datetime(2023,11,7,16,45,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,11,7,17,47,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,11,7,18,45,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,11,7,19,45,0,'TimeZone','UTC');  % 150 GPM
    datetime(2023,11,7,20,45,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01a = [0, 50, 80, 110, 150, 0];

for i = 2:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01a)-1
        text(pump_times_01a(i), 800, sprintf('%d GPM', pump_rates_01a(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01a(i), 800, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Plot 2: PM7 B DAS and all 5 zones (using transducer timestamps)
subplot(3,1,2)
yyaxis left
plot(trans_time_01b_z1_filt, strain_01b_z1_interp, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot all 5 zones using their actual timestamps
if ~isempty(drawdown_01b_z1_smooth)
    plot(trans_time_01b_z1_filt, drawdown_01b_z1_smooth, 'Color', zone_colors(1,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 1 drawdown: %d points\n', length(drawdown_01b_z1_smooth));
end
if ~isempty(drawdown_01b_z2_smooth)
    plot(trans_time_01b_z2_filt, drawdown_01b_z2_smooth, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 2 drawdown: %d points\n', length(drawdown_01b_z2_smooth));
end
if ~isempty(drawdown_01b_z3_smooth)
    plot(trans_time_01b_z3_filt, drawdown_01b_z3_smooth, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 3 drawdown: %d points\n', length(drawdown_01b_z3_smooth));
end
if ~isempty(drawdown_01b_z4_smooth)
    plot(trans_time_01b_z4_filt, drawdown_01b_z4_smooth, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 4 drawdown: %d points\n', length(drawdown_01b_z4_smooth));
end
if ~isempty(drawdown_01b_z5_smooth)
    plot(trans_time_01b_z5_filt, drawdown_01b_z5_smooth, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 B Zone 5 drawdown: %d points\n', length(drawdown_01b_z5_smooth));
end
hold off

ylabel('Drawdown (ft)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 B: DAS Strain vs All Zone Drawdowns')
grid on
legend({'PM7 B Strain', ['Zone 1 (' zone_depths{1} ')'], ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 B
hold on
% PM7 B pump times (UTC)
pump_times_01b = [
    datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,31,16,30,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,31,17,30,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,31,18,30,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,31,19,30,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01b = [0, 50, 80, 110, 148, 0];

for i = 2:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01b)-1
        text(pump_times_01b(i), 100, sprintf('%d GPM', pump_rates_01b(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01b(i), 100, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Plot 3: PM7 C DAS and zones 2-5 (using transducer timestamps)
subplot(3,1,3)
yyaxis left
plot(trans_time_01c_z2_filt, strain_01c_z2_interp, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot zones 2-5 using their actual timestamps
if ~isempty(drawdown_01c_z2_smooth)
    plot(trans_time_01c_z2_filt, drawdown_01c_z2_smooth, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 2 drawdown: %d points\n', length(drawdown_01c_z2_smooth));
end
if ~isempty(drawdown_01c_z3_smooth)
    plot(trans_time_01c_z3_filt, drawdown_01c_z3_smooth, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 3 drawdown: %d points\n', length(drawdown_01c_z3_smooth));
end
if ~isempty(drawdown_01c_z4_smooth)
    plot(trans_time_01c_z4_filt, drawdown_01c_z4_smooth, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 4 drawdown: %d points\n', length(drawdown_01c_z4_smooth));
end
if ~isempty(drawdown_01c_z5_smooth)
    plot(trans_time_01c_z5_filt, drawdown_01c_z5_smooth, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 C Zone 5 drawdown: %d points\n', length(drawdown_01c_z5_smooth));
end
hold off

ylabel('Drawdown (ft)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 C: DAS Strain vs Zone Drawdowns (Zones 2-5)')
grid on
legend({'PM7 C Strain', ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 C
hold on
% PM7 C pump times (UTC)
pump_times_01c = [
    datetime(2023,10,24,15,18,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,24,16,15,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,24,17,15,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,24,18,15,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,24,19,15,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01c = [0, 50, 80, 110, 148, 0];

for i = 2:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01c)-1
        text(pump_times_01c(i), 800, sprintf('%d GPM', pump_rates_01c(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01c(i), 800, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Overall title
sgtitle('PM7 Well Pump Test Comparisons: DAS Strain vs Zone Drawdowns (A&B: All 5 Zones, C: Zones 2-5)', 'FontSize', 14)

fprintf('✓ Created drawdown comparison plots\n');

%% 4. Create pressure comparison plots
fprintf('\n=== CREATING PRESSURE COMPARISON PLOTS ===\n');

% Figure settings
figure('Position', [150, 150, 1200, 900]);

% Define colors and depths for each zone (used in all plots)
zone_colors = [0 0 1; 0 0.7 0; 1 0.5 0; 0.7 0 0.7; 0 0.7 0.7]; % Blue, Green, Orange, Purple, Cyan
zone_depths = {'645-665 ft', '485-505 ft', '420-440 ft', '360-380 ft', '290-310 ft'};

% Plot 1: PM7 A DAS and pressure data (all 5 zones)
subplot(3,1,1)
yyaxis left
plot(Tdas_01a, strain_01a, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot all 5 zones pressure
if ~isempty(pressure_01a_z1_interp)
    plot(Tdas_01a, pressure_01a_z1_interp, 'Color', zone_colors(1,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 1 pressure: %d points\n', length(pressure_01a_z1_interp));
end
if ~isempty(pressure_01a_z2_interp)
    plot(Tdas_01a, pressure_01a_z2_interp, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 2 pressure: %d points\n', length(pressure_01a_z2_interp));
end
if ~isempty(pressure_01a_z3_interp)
    plot(Tdas_01a, pressure_01a_z3_interp, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 3 pressure: %d points\n', length(pressure_01a_z3_interp));
end
if ~isempty(pressure_01a_z4_interp)
    plot(Tdas_01a, pressure_01a_z4_interp, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 A Zone 4 pressure: %d points\n', length(pressure_01a_z4_interp));
end
if ~isempty(pressure_01a_z5_interp)
    plot(Tdas_01a, pressure_01a_z5_interp, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 A Zone 5 pressure: %d points\n', length(pressure_01a_z5_interp));
end
hold off

ylabel('Pressure (psi)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 A: DAS Strain vs All Zone Pressures')
grid on
legend({'PM7 A Strain', ['Zone 1 (' zone_depths{1} ')'], ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 A
hold on
% PM7 A pump times (UTC)
pump_times_01a = [
    datetime(2023,11,7,16,45,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,11,7,17,47,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,11,7,18,45,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,11,7,19,45,0,'TimeZone','UTC');  % 150 GPM
    datetime(2023,11,7,20,45,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01a = [0, 50, 80, 110, 150, 0];

for i = 2:length(pump_times_01a)
    xline(pump_times_01a(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01a)-1
        text(pump_times_01a(i), 800, sprintf('%d GPM', pump_rates_01a(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01a(i), 800, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Plot 2: PM7 B DAS and pressure data (all 5 zones)
subplot(3,1,2)
yyaxis left
plot(Tdas_01b, strain_01b, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot all 5 zones pressure
if ~isempty(pressure_01b_z1_interp)
    plot(Tdas_01b, pressure_01b_z1_interp, 'Color', zone_colors(1,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 1 pressure: %d points\n', length(pressure_01b_z1_interp));
end
if ~isempty(pressure_01b_z2_interp)
    plot(Tdas_01b, pressure_01b_z2_interp, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 2 pressure: %d points\n', length(pressure_01b_z2_interp));
end
if ~isempty(pressure_01b_z3_interp)
    plot(Tdas_01b, pressure_01b_z3_interp, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 3 pressure: %d points\n', length(pressure_01b_z3_interp));
end
if ~isempty(pressure_01b_z4_interp)
    plot(Tdas_01b, pressure_01b_z4_interp, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 B Zone 4 pressure: %d points\n', length(pressure_01b_z4_interp));
end
if ~isempty(pressure_01b_z5_interp)
    plot(Tdas_01b, pressure_01b_z5_interp, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 B Zone 5 pressure: %d points\n', length(pressure_01b_z5_interp));
end
hold off

ylabel('Pressure (psi)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 B: DAS Strain vs All Zone Pressures')
grid on
legend({'PM7 B Strain', ['Zone 1 (' zone_depths{1} ')'], ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 B
hold on
% PM7 B pump times (UTC)
pump_times_01b = [
    datetime(2023,10,31,15,30,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,31,16,30,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,31,17,30,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,31,18,30,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,31,19,30,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01b = [0, 50, 80, 110, 148, 0];

for i = 2:length(pump_times_01b)
    xline(pump_times_01b(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01b)-1
        text(pump_times_01b(i), 100, sprintf('%d GPM', pump_rates_01b(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01b(i), 100, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Plot 3: PM7 C DAS and pressure data (zones 2-5, Zone 1 removed due to incomplete data)
subplot(3,1,3)
yyaxis left
plot(Tdas_01c, strain_01c, 'r-', 'LineWidth', 1);
ylabel('DAS Strain (nε)', 'Color', 'r')

yyaxis right
hold on
% Plot zones 2-5 pressure (Zone 1 removed due to incomplete data)
if ~isempty(pressure_01c_z2_interp)
    plot(Tdas_01c, pressure_01c_z2_interp, 'Color', zone_colors(2,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 2 pressure: %d points\n', length(pressure_01c_z2_interp));
end
if ~isempty(pressure_01c_z3_interp)
    plot(Tdas_01c, pressure_01c_z3_interp, 'Color', zone_colors(3,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 3 pressure: %d points\n', length(pressure_01c_z3_interp));
end
if ~isempty(pressure_01c_z4_interp)
    plot(Tdas_01c, pressure_01c_z4_interp, 'Color', zone_colors(4,:), 'LineWidth', 1, 'LineStyle', '-');
    fprintf('Plotting PM7 C Zone 4 pressure: %d points\n', length(pressure_01c_z4_interp));
end
if ~isempty(pressure_01c_z5_interp)
    plot(Tdas_01c, pressure_01c_z5_interp, 'Color', zone_colors(5,:), 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    fprintf('Plotting PM7 C Zone 5 pressure: %d points\n', length(pressure_01c_z5_interp));
end
hold off

ylabel('Pressure (psi)', 'Color', 'k')
ax = gca;
ax.YAxis(2).Color = [0 0 0];

title('PM7 C: DAS Strain vs Zone Pressures (Zones 2-5)')
grid on
legend({'PM7 C Strain', ['Zone 2 (' zone_depths{2} ')'], ...
        ['Zone 3 (' zone_depths{3} ')'], ['Zone 4 (' zone_depths{4} ')'], ['Zone 5 (' zone_depths{5} ')']}, ...
       'Location', 'eastoutside', 'FontSize', 8)

% Add pump step annotations for PM7 C
hold on
% PM7 C pump times (UTC)
pump_times_01c = [
    datetime(2023,10,24,15,18,0,'TimeZone','UTC');  % 50 GPM starts
    datetime(2023,10,24,16,15,0,'TimeZone','UTC');  % 80 GPM
    datetime(2023,10,24,17,15,0,'TimeZone','UTC');  % 110 GPM
    datetime(2023,10,24,18,15,0,'TimeZone','UTC');  % 148 GPM
    datetime(2023,10,24,19,15,0,'TimeZone','UTC');  % 0 GPM (off)
];
pump_rates_01c = [0, 50, 80, 110, 148, 0];

for i = 2:length(pump_times_01c)
    xline(pump_times_01c(i), 'k--', 'LineWidth', 1);
    if i <= length(pump_rates_01c)-1
        text(pump_times_01c(i), 800, sprintf('%d GPM', pump_rates_01c(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(pump_times_01c(i), 800, '0 GPM', 'HorizontalAlignment', 'center', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
end
hold off

% Overall title
sgtitle('PM7 Well Pump Test Comparisons: DAS Strain vs Zone Pressures (A&B: All 5 Zones, C: Zones 2-5)', 'FontSize', 14)

fprintf('✓ Created pressure comparison plots\n');