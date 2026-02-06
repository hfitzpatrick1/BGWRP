function process_pm7_transducer_data(csv_file, zone_name)
%PROCESS_PM7_TRANSDUCER_DATA Clean and analyze PM7 transducer observation well data
%
% Usage:
%   process_pm7_transducer_data(csv_file, zone_name)
%
% Inputs:
%   csv_file - Path to PM7 transducer CSV file (VuSitu format)
%   zone_name - Optional name for labeling (e.g., 'PT-01a Zone 3')
%
% Example:
%   process_pm7_transducer_data('C:\...\PM7_3_SDT_PT-01a_2023-11-07_08-00-00.csv', 'PT-01a Zone 3')

if nargin < 2
    zone_name = 'PM7 Transducer';
end

console_log('=== PM7 TRANSDUCER DATA PROCESSING ===\n');
console_log('Processing: %s\n', zone_name);
console_log('File: %s\n\n', csv_file);

%% STEP 1: Load Raw Data
console_log('STEP 1: Load Raw Data\n');
console_log('------------------------------------------------------\n');

if ~exist(csv_file, 'file')
    error('Data file not found: %s', csv_file);
end

try
    % Find the header line (contains "Date Time" and "Depth")
    fid = fopen(csv_file, 'r');
    line_count = 0;
    while ~feof(fid)
        line = fgetl(fid);
        line_count = line_count + 1;
        if contains(line, 'Date Time') && contains(line, 'Depth')
            console_log('Found header at line %d\n', line_count);
            break;
        end
    end
    fclose(fid);
    
    % Read the data with proper column names
    opts = detectImportOptions(csv_file);
    opts.DataLines = [line_count+1, inf];
    opts.VariableNames = {'DateTime', 'Pressure_psi', 'Temperature_C', 'Depth_ft'};
    
    data_table = readtable(csv_file, opts);
    
    console_log('✓ Data loaded successfully\n');
    console_log('  Rows: %d\n', height(data_table));
    console_log('  Columns: DateTime, Pressure_psi, Temperature_C, Depth_ft\n');
    
catch ME
    error('Failed to load data: %s', ME.message);
end

%% STEP 2: Parse Time and Data
console_log('\nSTEP 2: Parse Time and Data\n');
console_log('------------------------------------------------------\n');

try
    % Parse timestamps (local time, then convert to UTC)
    timestamps_local = datetime(data_table.DateTime, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    timestamps_local.TimeZone = 'America/Los_Angeles';  % PST/PDT
    
    % Convert to UTC
    timestamps = timestamps_local;
    timestamps.TimeZone = 'UTC';
    
    % Extract data
    pressure_raw = data_table.Pressure_psi;
    temperature = data_table.Temperature_C;
    depth_ft_raw = data_table.Depth_ft;
    
    console_log('✓ Data parsed successfully\n');
    console_log('  Time range (UTC): %s to %s\n', timestamps(1), timestamps(end));
    console_log('  Duration: %.2f hours\n', hours(timestamps(end) - timestamps(1)));
    console_log('  Sampling interval: %.2f seconds (median)\n', median(seconds(diff(timestamps))));
    console_log('  Pressure range: %.3f to %.3f psi\n', min(pressure_raw), max(pressure_raw));
    console_log('  Depth range: %.3f to %.3f ft\n', min(depth_ft_raw), max(depth_ft_raw));
    console_log('  Temperature range: %.2f to %.2f °C\n', min(temperature), max(temperature));
    
catch ME
    error('Failed to parse data: %s', ME.message);
end

%% STEP 3: Visualize Raw Data
console_log('\nSTEP 3: Visualize Raw Data\n');
console_log('------------------------------------------------------\n');

figure('Name', sprintf('%s - Raw Data', zone_name), 'Position', [100, 100, 1400, 900]);

% Plot 1: Raw pressure
subplot(4,1,1);
plot(timestamps, pressure_raw, 'b-', 'LineWidth', 1);
ylabel('Pressure (psi)');
title(sprintf('%s: Raw Pressure Data', zone_name));
grid on;

% Plot 2: Raw depth (water level)
subplot(4,1,2);
plot(timestamps, depth_ft_raw, 'b-', 'LineWidth', 1);
ylabel('Depth to Water (ft)');
title('Raw Depth Data (positive = deeper water level)');
grid on;

% Plot 3: Temperature
subplot(4,1,3);
plot(timestamps, temperature, 'r-', 'LineWidth', 1);
ylabel('Temperature (°C)');
title('Temperature Profile');
grid on;

% Plot 4: Outlier detection on pressure
subplot(4,1,4);
window_size = min(50, floor(length(pressure_raw)/10));
moving_median = movmedian(pressure_raw, window_size, 'omitnan');
moving_mad = movmad(pressure_raw, window_size, 'omitnan');
outlier_threshold = 3;
outliers = abs(pressure_raw - moving_median) > outlier_threshold * moving_mad;

plot(timestamps, pressure_raw, 'b-', 'LineWidth', 1);
hold on;
if any(outliers)
    plot(timestamps(outliers), pressure_raw(outliers), 'ro', 'MarkerSize', 6);
    legend('Raw Pressure', sprintf('Outliers (%d points)', sum(outliers)), 'Location', 'best');
else
    legend('Raw Pressure', 'Location', 'best');
end
ylabel('Pressure (psi)');
xlabel('Time (UTC)');
title('Outlier Detection (3-MAD threshold)');
grid on;

console_log('✓ Raw data visualization created\n');
console_log('  Identified %d potential outlier points (%.2f%% of data)\n', ...
    sum(outliers), 100*sum(outliers)/length(outliers));

%% STEP 4: Remove Outliers and Bad Data
console_log('\nSTEP 4: Remove Outliers and Bad Data\n');
console_log('------------------------------------------------------\n');

% Create cleaned arrays
pressure_cleaned = pressure_raw;
depth_cleaned = depth_ft_raw;

% Remove outliers from both pressure and depth
pressure_cleaned(outliers) = NaN;
depth_cleaned(outliers) = NaN;
console_log('✓ Removed %d outliers\n', sum(outliers));

% Interpolate over small gaps
max_gap = 5;
pressure_cleaned = fillmissing(pressure_cleaned, 'linear', 'MaxGap', max_gap);
depth_cleaned = fillmissing(depth_cleaned, 'linear', 'MaxGap', max_gap);
remaining_nans = sum(isnan(pressure_cleaned));
console_log('✓ Interpolated small gaps (<= %d points)\n', max_gap);
if remaining_nans > 0
    console_log('⚠ %d NaN values remain (larger gaps not interpolated)\n', remaining_nans);
end

%% STEP 5: Apply Smoothing Filters
console_log('\nSTEP 5: Apply Smoothing Filters\n');
console_log('------------------------------------------------------\n');

% Moving average smoothing (adjust window based on sampling rate)
% For 5-second sampling, 21 points ≈ 1.75 minutes
smooth_window = 21;
pressure_smoothed = movmean(pressure_cleaned, smooth_window, 'omitnan');
depth_smoothed = movmean(depth_cleaned, smooth_window, 'omitnan');
console_log('✓ Applied %d-point moving average filter\n', smooth_window);

% Savitzky-Golay filter for better edge preservation
try
    savgol_order = 3;
    savgol_framelen = 21;  % Must be odd
    
    pressure_final = sgolayfilt(pressure_smoothed, savgol_order, savgol_framelen);
    depth_final = sgolayfilt(depth_smoothed, savgol_order, savgol_framelen);
    
    console_log('✓ Applied Savitzky-Golay filter (order=%d, framelen=%d)\n', ...
        savgol_order, savgol_framelen);
catch ME
    console_log('⚠ Savitzky-Golay filter failed: %s\n', ME.message);
    pressure_final = pressure_smoothed;
    depth_final = depth_smoothed;
end

%% STEP 6: Calculate Drawdown
console_log('\nSTEP 6: Calculate Drawdown\n');
console_log('------------------------------------------------------\n');

% Use first 60 points as baseline (matching your existing scripts)
baseline_points = min(60, floor(length(depth_final)/10));
baseline_depth_ft = mean(depth_final(1:baseline_points), 'omitnan');
baseline_pressure_psi = mean(pressure_final(1:baseline_points), 'omitnan');

console_log('Using first %d points for baseline\n', baseline_points);
console_log('  Baseline depth: %.3f ft\n', baseline_depth_ft);
console_log('  Baseline pressure: %.3f psi\n', baseline_pressure_psi);

% Calculate drawdown (positive = deeper water = more drawdown)
drawdown_ft = depth_final - baseline_depth_ft;
pressure_change_psi = pressure_raw - baseline_pressure_psi;

console_log('✓ Calculated drawdown\n');
console_log('  Maximum drawdown: %.3f ft\n', max(drawdown_ft, [], 'omitnan'));
console_log('  Minimum drawdown: %.3f ft\n', min(drawdown_ft, [], 'omitnan'));
console_log('  Maximum pressure change: %.3f psi\n', max(pressure_change_psi, [], 'omitnan'));

%% STEP 7: Calculate Drawdown Rate (for correlation with DAS)
console_log('\nSTEP 7: Calculate Drawdown Rate\n');
console_log('------------------------------------------------------\n');

% Calculate time derivative of drawdown (ft/s)
dt_seconds = seconds(diff(timestamps));
drawdown_rate_ft_s = [0; diff(drawdown_ft) ./ dt_seconds];

% Smooth the rate (it's typically noisy)
drawdown_rate_smoothed = movmean(drawdown_rate_ft_s, smooth_window, 'omitnan');

console_log('✓ Calculated drawdown rate\n');
console_log('  Rate range: %.6f to %.6f ft/s\n', ...
    min(drawdown_rate_smoothed, [], 'omitnan'), ...
    max(drawdown_rate_smoothed, [], 'omitnan'));

%% STEP 8: Visualize Cleaned Data
console_log('\nSTEP 8: Visualize Cleaned Data\n');
console_log('------------------------------------------------------\n');

figure('Name', sprintf('%s - Cleaned Data', zone_name), 'Position', [150, 150, 1400, 1000]);

% Plot 1: Before and After Pressure
subplot(5,1,1);
plot(timestamps, pressure_raw, 'b-', 'LineWidth', 0.5, 'DisplayName', 'Raw');
hold on;
plot(timestamps, pressure_final, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
ylabel('Pressure (psi)');
title(sprintf('%s: Pressure - Raw vs Cleaned', zone_name));
legend('Location', 'best');
grid on;

% Plot 2: Noise reduction
subplot(5,1,2);
noise = pressure_raw - pressure_final;
plot(timestamps, noise, 'k-', 'LineWidth', 0.5);
ylabel('Noise (psi)');
title(sprintf('Removed Noise (RMS = %.4f psi)', rms(noise, 'omitnan')));
grid on;

% Plot 3: Drawdown (depth-based)
subplot(5,1,3);
plot(timestamps, drawdown_ft, 'b-', 'LineWidth', 1.5);
hold on;
yline(0, 'r--', 'Baseline', 'LineWidth', 1.5);
ylabel('Drawdown (ft)');
title('Drawdown Time Series (positive = water level decline)');
grid on;

% Plot 4: Drawdown rate
subplot(5,1,4);
plot(timestamps, drawdown_rate_smoothed, 'g-', 'LineWidth', 1.5);
ylabel('Drawdown Rate (ft/s)');
title('Drawdown Rate (for DAS correlation)');
grid on;

% Plot 5: Temperature for reference
subplot(5,1,5);
plot(timestamps, temperature, 'r-', 'LineWidth', 1);
ylabel('Temperature (°C)');
xlabel('Time (UTC)');
title('Temperature Profile');
grid on;

console_log('✓ Cleaned data visualization created\n');

%% STEP 9: Quality Metrics
console_log('\nSTEP 9: Data Quality Metrics\n');
console_log('------------------------------------------------------\n');

noise_rms = rms(noise, 'omitnan');
signal_std = std(pressure_final, 'omitnan');
snr = 20 * log10(signal_std / noise_rms);

console_log('Quality Metrics:\n');
console_log('  RMS Noise: %.4f psi (%.3f ft of water)\n', noise_rms, noise_rms * 2.31);
console_log('  Signal Std Dev: %.4f psi\n', signal_std);
console_log('  Signal-to-Noise Ratio: %.1f dB\n', snr);
console_log('  Data completeness: %.1f%% (%d/%d points)\n', ...
    100*sum(~isnan(pressure_final))/length(pressure_final), ...
    sum(~isnan(pressure_final)), length(pressure_final));

%% STEP 10: Export Cleaned Data
console_log('\nSTEP 10: Export Cleaned Data\n');
console_log('------------------------------------------------------\n');

% Create output directory
[input_dir, ~, ~] = fileparts(csv_file);
output_dir = fullfile(input_dir, 'processed');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Prepare data structure matching your existing format
Date = timestamps;  % UTC datetime
Drawdownft = drawdown_ft;
Pressurepsi = pressure_final;
Depthft = baseline_depth_ft;  % Scalar depth value
DrawdownRate_ft_s = drawdown_rate_smoothed;
Temperature_C = temperature;

% Save as MAT file (matches head_a_z*.mat format)
[~, base_name, ~] = fileparts(csv_file);
mat_output = fullfile(output_dir, sprintf('%s_cleaned.mat', base_name));
save(mat_output, 'Date', 'Drawdownft', 'Pressurepsi', 'Depthft', ...
    'DrawdownRate_ft_s', 'Temperature_C', 'baseline_depth_ft', 'baseline_pressure_psi');
console_log('✓ Exported MAT file: %s\n', mat_output);

% Also save as CSV for easy viewing
output_table = table(timestamps, pressure_raw, pressure_final, depth_ft_raw, depth_final, ...
    drawdown_ft, drawdown_rate_smoothed, temperature, ...
    'VariableNames', {'DateTime_UTC', 'Pressure_Raw_psi', 'Pressure_Cleaned_psi', ...
    'Depth_Raw_ft', 'Depth_Cleaned_ft', 'Drawdown_ft', 'DrawdownRate_ft_s', 'Temperature_C'});

csv_output = fullfile(output_dir, sprintf('%s_cleaned.csv', base_name));
writetable(output_table, csv_output);
console_log('✓ Exported CSV file: %s\n', csv_output);

%% Summary
console_log('\n=== PROCESSING COMPLETE ===\n');
console_log('Zone: %s\n', zone_name);
console_log('✓ Raw data points: %d\n', length(pressure_raw));
console_log('✓ Outliers removed: %d (%.2f%%)\n', sum(outliers), 100*sum(outliers)/length(outliers));
console_log('✓ RMS noise: %.4f psi\n', noise_rms);
console_log('✓ Maximum drawdown: %.3f ft\n', max(drawdown_ft, [], 'omitnan'));
console_log('✓ Output files saved to: %s\n', output_dir);

console_log('\n📋 DATA READY FOR:\n');
console_log('   - Pump test analysis (drawdown vs time)\n');
console_log('   - DAS correlation (using DrawdownRate_ft_s)\n');
console_log('   - Storage parameter estimation\n');
console_log('   - Multi-zone comparison\n\n');

console_log('💡 TIP: Load the cleaned MAT file for further analysis:\n');
console_log('   >> load(''%s'');\n', mat_output);
console_log('   >> plot(Date, Drawdownft);\n\n');

end
