function process_aquatroll_pump_test()
%PROCESS_AQUATROLL_PUMP_TEST Clean and process Aquatroll 700 observation well data
%
% This script provides a step-by-step workflow for cleaning noisy Aquatroll 700
% pressure/level data from a pump test observation well
%
% Workflow:
%   1. Load raw Aquatroll data
%   2. Visualize raw data to identify noise sources
%   3. Apply barometric correction (if atmospheric pressure available)
%   4. Remove outliers and spikes
%   5. Apply smoothing filters
%   6. Calculate drawdown
%   7. Validate cleaned data
%   8. Export for analysis

console_log('=== AQUATROLL 700 PUMP TEST DATA PROCESSING ===\n\n');

%% STEP 1: Load Raw Data
console_log('STEP 1: Load Raw Data\n');
console_log('------------------------------------------------------\n');

% ============================================================
% USER INPUT REQUIRED: Update these paths for your data
% ============================================================
data_file = 'C:\Coding\BGWRP\data\aquatroll\your_data_file.csv'; % UPDATE THIS
output_dir = 'C:\Coding\BGWRP\data\aquatroll\processed\'; % UPDATE THIS

% Check if file exists
if ~exist(data_file, 'file')
    console_log('⚠ Data file not found: %s\n', data_file);
    console_log('\n📋 TO DO: Update the data_file path in this script\n');
    console_log('   Line ~23: data_file = ''your_actual_file_path.csv'';\n\n');
    return;
end

% Create output directory if it doesn't exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    console_log('✓ Created output directory: %s\n', output_dir);
end

% Load Aquatroll data
% Aquatroll 700 typically exports as CSV with columns:
% Date/Time, Temperature (°C), Pressure (psi or kPa), Level (ft or m), etc.
console_log('Loading data from: %s\n', data_file);

try
    % Try reading as table first (handles headers automatically)
    data_table = readtable(data_file);
    console_log('✓ Data loaded successfully\n');
    console_log('  Columns: %s\n', strjoin(data_table.Properties.VariableNames, ', '));
    console_log('  Rows: %d\n', height(data_table));
    
    % Display first few rows to help user identify columns
    console_log('\nFirst few rows of data:\n');
    disp(data_table(1:min(5, height(data_table)), :));
    
catch ME
    console_log('✗ Error loading data: %s\n', ME.message);
    console_log('\n💡 TIP: Check that your file is a valid CSV format\n');
    return;
end

%% STEP 2: Parse and Organize Data
console_log('\n\nSTEP 2: Parse and Organize Data\n');
console_log('------------------------------------------------------\n');

% ============================================================
% USER INPUT REQUIRED: Update these column names to match your data
% ============================================================
% Common Aquatroll column names (update to match your actual columns):
time_col = 'Date_Time';           % UPDATE THIS
pressure_col = 'Pressure_psi';    % UPDATE THIS (could be Pressure_kPa, etc.)
temp_col = 'Temperature_C';        % UPDATE THIS
level_col = 'Level_ft';            % UPDATE THIS (could be Level_m, Depth_to_Water, etc.)

% Check if columns exist
required_cols = {time_col, pressure_col};
missing_cols = {};
for i = 1:length(required_cols)
    if ~any(strcmp(data_table.Properties.VariableNames, required_cols{i}))
        missing_cols{end+1} = required_cols{i};
    end
end

if ~isempty(missing_cols)
    console_log('⚠ Missing required columns: %s\n', strjoin(missing_cols, ', '));
    console_log('\n📋 TO DO: Update column names in this script (lines ~63-66)\n');
    console_log('   Your actual column names are:\n');
    console_log('   %s\n', strjoin(data_table.Properties.VariableNames, ', '));
    return;
end

% Extract time series
try
    % Parse timestamps
    if isdatetime(data_table.(time_col))
        timestamps = data_table.(time_col);
    else
        timestamps = datetime(data_table.(time_col), 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
    end
    
    % Extract pressure data
    pressure_raw = data_table.(pressure_col);
    
    % Extract temperature if available
    if any(strcmp(data_table.Properties.VariableNames, temp_col))
        temperature = data_table.(temp_col);
    else
        temperature = [];
        console_log('⚠ Temperature column not found - skipping\n');
    end
    
    % Extract level if available
    if any(strcmp(data_table.Properties.VariableNames, level_col))
        level_raw = data_table.(level_col);
    else
        level_raw = [];
        console_log('⚠ Level column not found - will calculate from pressure\n');
    end
    
    console_log('✓ Data parsed successfully\n');
    console_log('  Time range: %s to %s\n', timestamps(1), timestamps(end));
    console_log('  Duration: %.2f hours\n', hours(timestamps(end) - timestamps(1)));
    console_log('  Sampling interval: %.2f seconds (median)\n', median(seconds(diff(timestamps))));
    console_log('  Pressure range: %.3f to %.3f psi\n', min(pressure_raw), max(pressure_raw));
    
catch ME
    console_log('✗ Error parsing data: %s\n', ME.message);
    return;
end

%% STEP 3: Visualize Raw Data
console_log('\n\nSTEP 3: Visualize Raw Data\n');
console_log('------------------------------------------------------\n');

figure('Name', 'Raw Aquatroll Data', 'Position', [100, 100, 1200, 800]);

% Plot 1: Raw pressure
subplot(3,1,1);
plot(timestamps, pressure_raw, 'b-', 'LineWidth', 1);
ylabel('Pressure (psi)');
title('Raw Pressure Data');
grid on;
legend('Raw Pressure', 'Location', 'best');

% Plot 2: Pressure with outliers highlighted
subplot(3,1,2);
% Identify potential outliers using moving median absolute deviation
window_size = min(50, floor(length(pressure_raw)/10)); % Adaptive window
moving_median = movmedian(pressure_raw, window_size, 'omitnan');
moving_mad = movmad(pressure_raw, window_size, 'omitnan');
outlier_threshold = 3; % Number of MADs for outlier detection
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
title('Outlier Detection (3-MAD threshold)');
grid on;

% Plot 3: Rate of change (helps identify spikes)
subplot(3,1,3);
dt_seconds = seconds(diff(timestamps));
pressure_rate = [0; diff(pressure_raw) ./ dt_seconds]; % psi per second
plot(timestamps, pressure_rate, 'b-', 'LineWidth', 1);
ylabel('Pressure Rate (psi/s)');
xlabel('Time');
title('Rate of Change (helps identify sudden spikes)');
grid on;

console_log('✓ Raw data visualization created\n');
console_log('  Identified %d potential outlier points (%.2f%% of data)\n', ...
    sum(outliers), 100*sum(outliers)/length(outliers));

%% STEP 4: Remove Outliers and Bad Data
console_log('\n\nSTEP 4: Remove Outliers and Bad Data\n');
console_log('------------------------------------------------------\n');

% Create clean data array
pressure_cleaned = pressure_raw;

% Remove outliers (replace with NaN)
pressure_cleaned(outliers) = NaN;
console_log('✓ Removed %d outliers\n', sum(outliers));

% Remove physically impossible values (if any)
min_reasonable = 0; % Adjust based on your site
max_reasonable = 100; % Adjust based on your site (psi)
unreasonable = pressure_cleaned < min_reasonable | pressure_cleaned > max_reasonable;
pressure_cleaned(unreasonable) = NaN;
console_log('✓ Removed %d physically unreasonable values\n', sum(unreasonable));

% Interpolate over small gaps (< 5 consecutive points)
max_gap = 5;
pressure_cleaned = fillmissing(pressure_cleaned, 'linear', 'MaxGap', max_gap);
remaining_nans = sum(isnan(pressure_cleaned));
console_log('✓ Interpolated small gaps (<= %d points)\n', max_gap);
if remaining_nans > 0
    console_log('⚠ %d NaN values remain (larger gaps not interpolated)\n', remaining_nans);
end

%% STEP 5: Apply Smoothing Filter
console_log('\n\nSTEP 5: Apply Smoothing Filter\n');
console_log('------------------------------------------------------\n');

% Apply moving average smoothing
smooth_window = 5; % 5-point moving average (adjust as needed)
pressure_smoothed = movmean(pressure_cleaned, smooth_window, 'omitnan');
console_log('✓ Applied %d-point moving average filter\n', smooth_window);

% Optional: Apply additional Savitzky-Golay filter for better edge preservation
use_savgol = true;
if use_savgol
    try
        % Savitzky-Golay parameters
        savgol_order = 2; % Polynomial order
        savgol_framelen = min(11, floor(length(pressure_smoothed)/10)); % Frame length (must be odd)
        if mod(savgol_framelen, 2) == 0
            savgol_framelen = savgol_framelen + 1;
        end
        
        % Apply filter to non-NaN sections
        pressure_final = sgolayfilt(pressure_smoothed, savgol_order, savgol_framelen);
        console_log('✓ Applied Savitzky-Golay filter (order=%d, framelen=%d)\n', ...
            savgol_order, savgol_framelen);
    catch ME
        console_log('⚠ Savitzky-Golay filter failed: %s\n', ME.message);
        pressure_final = pressure_smoothed;
    end
else
    pressure_final = pressure_smoothed;
end

%% STEP 6: Barometric Correction (Optional)
console_log('\n\nSTEP 6: Barometric Correction (Optional)\n');
console_log('------------------------------------------------------\n');

% ============================================================
% USER INPUT: Do you have barometric pressure data?
% ============================================================
has_baro_data = false; % Set to true if you have atmospheric pressure data

if has_baro_data
    console_log('⚠ Barometric correction not yet implemented\n');
    console_log('💡 TIP: If you have barometric data, you should correct for atmospheric pressure changes\n');
    console_log('   Corrected Pressure = Measured Pressure - (Barometric Pressure - Reference Pressure)\n');
    % TODO: Implement barometric correction here
else
    console_log('ℹ Skipping barometric correction (no atmospheric pressure data)\n');
    console_log('💡 TIP: For best results, consider collecting barometric data\n');
end

%% STEP 7: Calculate Drawdown
console_log('\n\nSTEP 7: Calculate Drawdown\n');
console_log('------------------------------------------------------\n');

% ============================================================
% USER INPUT: Define static water level (pre-pumping baseline)
% ============================================================
% Option 1: Use average of first N points
baseline_points = min(100, floor(length(pressure_final)/10));
static_pressure = mean(pressure_final(1:baseline_points), 'omitnan');
console_log('Using first %d points for static pressure baseline\n', baseline_points);

% Option 2: Manually specify static pressure
% static_pressure = 14.5; % UNCOMMENT and set if you know the static value

% Convert pressure to water level (assuming freshwater)
% For freshwater: 1 psi = 2.31 ft of water
% For saltwater: 1 psi = 2.25 ft of water
psi_to_ft = 2.31; % Adjust for water density if needed

water_level_ft = pressure_final * psi_to_ft;
static_level_ft = static_pressure * psi_to_ft;

% Calculate drawdown (positive = water level decline)
drawdown_ft = static_level_ft - water_level_ft;

console_log('✓ Calculated drawdown\n');
console_log('  Static pressure: %.3f psi (%.2f ft water)\n', static_pressure, static_level_ft);
console_log('  Maximum drawdown: %.3f ft\n', max(drawdown_ft, [], 'omitnan'));
console_log('  Minimum drawdown: %.3f ft\n', min(drawdown_ft, [], 'omitnan'));

%% STEP 8: Visualize Cleaned Data
console_log('\n\nSTEP 8: Visualize Cleaned Data\n');
console_log('------------------------------------------------------\n');

figure('Name', 'Cleaned Aquatroll Data', 'Position', [150, 150, 1200, 900]);

% Plot 1: Before and After Pressure
subplot(4,1,1);
plot(timestamps, pressure_raw, 'b-', 'LineWidth', 0.5, 'DisplayName', 'Raw');
hold on;
plot(timestamps, pressure_final, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Cleaned');
ylabel('Pressure (psi)');
title('Pressure: Raw vs Cleaned');
legend('Location', 'best');
grid on;

% Plot 2: Noise reduction
subplot(4,1,2);
noise = pressure_raw - pressure_final;
plot(timestamps, noise, 'k-', 'LineWidth', 0.5);
ylabel('Noise (psi)');
title(sprintf('Removed Noise (RMS = %.4f psi)', rms(noise, 'omitnan')));
grid on;

% Plot 3: Water level
subplot(4,1,3);
plot(timestamps, water_level_ft, 'b-', 'LineWidth', 1.5);
hold on;
yline(static_level_ft, 'r--', 'Static Level', 'LineWidth', 1.5);
ylabel('Water Level (ft)');
title('Water Level Time Series');
legend('Measured', 'Static Level', 'Location', 'best');
grid on;

% Plot 4: Drawdown
subplot(4,1,4);
plot(timestamps, drawdown_ft, 'k-', 'LineWidth', 1.5);
ylabel('Drawdown (ft)');
xlabel('Time');
title('Drawdown Time Series (positive = decline)');
grid on;

console_log('✓ Cleaned data visualization created\n');

%% STEP 9: Quality Metrics
console_log('\n\nSTEP 9: Data Quality Metrics\n');
console_log('------------------------------------------------------\n');

% Calculate quality metrics
noise_rms = rms(noise, 'omitnan');
signal_std = std(pressure_final, 'omitnan');
snr = 20 * log10(signal_std / noise_rms); % Signal-to-noise ratio in dB

console_log('Quality Metrics:\n');
console_log('  RMS Noise: %.4f psi (%.3f ft)\n', noise_rms, noise_rms * psi_to_ft);
console_log('  Signal Std Dev: %.4f psi\n', signal_std);
console_log('  Signal-to-Noise Ratio: %.1f dB\n', snr);
console_log('  Data completeness: %.1f%% (%d/%d points)\n', ...
    100*sum(~isnan(pressure_final))/length(pressure_final), ...
    sum(~isnan(pressure_final)), length(pressure_final));

%% STEP 10: Export Cleaned Data
console_log('\n\nSTEP 10: Export Cleaned Data\n');
console_log('------------------------------------------------------\n');

% Create output table
output_table = table(timestamps, pressure_raw, pressure_final, ...
    water_level_ft, drawdown_ft, ...
    'VariableNames', {'DateTime', 'Pressure_Raw_psi', 'Pressure_Cleaned_psi', ...
    'WaterLevel_ft', 'Drawdown_ft'});

% Add temperature if available
if ~isempty(temperature)
    output_table.Temperature_C = temperature;
end

% Save as CSV
csv_output = fullfile(output_dir, 'aquatroll_cleaned.csv');
writetable(output_table, csv_output);
console_log('✓ Exported cleaned data to CSV: %s\n', csv_output);

% Save as MAT file
mat_output = fullfile(output_dir, 'aquatroll_cleaned.mat');
save(mat_output, 'timestamps', 'pressure_raw', 'pressure_final', ...
    'water_level_ft', 'drawdown_ft', 'static_pressure', 'static_level_ft', ...
    'temperature', 'noise_rms', 'snr');
console_log('✓ Exported cleaned data to MAT: %s\n', mat_output);

%% Summary
console_log('\n\n=== PROCESSING COMPLETE ===\n');
console_log('✓ Raw data points: %d\n', length(pressure_raw));
console_log('✓ Outliers removed: %d (%.2f%%)\n', sum(outliers), 100*sum(outliers)/length(outliers));
console_log('✓ RMS noise: %.4f psi\n', noise_rms);
console_log('✓ Maximum drawdown: %.3f ft\n', max(drawdown_ft, [], 'omitnan'));
console_log('✓ Output files saved to: %s\n', output_dir);

console_log('\n📋 NEXT STEPS:\n');
console_log('   1. Review the cleaned data plots\n');
console_log('   2. Verify the drawdown calculation looks correct\n');
console_log('   3. If needed, adjust filter parameters and re-run\n');
console_log('   4. Use the cleaned data for pump test analysis\n');
console_log('\n');

end
