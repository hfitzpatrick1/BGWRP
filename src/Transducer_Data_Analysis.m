%% Transducer Data Analysis - Pump Well Monitoring
% This script analyzes transducer data from the pumping wells during the
% three pump tests (PT-01a, PT-01b, PT-01c)
% 
% Data includes:
% - Pressure (psi)
% - Temperature (°C) 
% - Depth (ft)
%
% Author: Hannah Fitz
% Date: 2024

clear; clc; close all;

fprintf('=== TRANSDUCER DATA ANALYSIS ===\n');

%% File Paths
data_dir = 'data/PTWells/';

% Transducer data files
pt01a_file = fullfile(data_dir, 'VuSitu_2023-11-07_08-00-00_PT-01a_Log_PT-01a_SDT_PT-01a.csv');
pt01b_file = fullfile(data_dir, 'VuSitu_2023-10-31_08-00-00_PT-01b_Log_PT-01b_SDT_PT-01b.csv');
pt01c_file = fullfile(data_dir, 'VuSitu_2023-10-24_08-00-00_PT-01c_Log_PT-01c_step_PT-01c.csv');

%% Load and Process Data
fprintf('Loading transducer data...\n');

% Load PT-01a data
if exist(pt01a_file, 'file')
    [time_01a, pressure_01a, temp_01a, depth_01a] = load_transducer_data(pt01a_file);
    fprintf('✓ Loaded PT-01a data (%d points)\n', length(time_01a));
else
    error('PT-01a file not found: %s', pt01a_file);
end

% Load PT-01b data
if exist(pt01b_file, 'file')
    [time_01b, pressure_01b, temp_01b, depth_01b] = load_transducer_data(pt01b_file);
    fprintf('✓ Loaded PT-01b data (%d points)\n', length(time_01b));
else
    error('PT-01b file not found: %s', pt01b_file);
end

% Load PT-01c data
if exist(pt01c_file, 'file')
    [time_01c, pressure_01c, temp_01c, depth_01c] = load_transducer_data(pt01c_file);
    fprintf('✓ Loaded PT-01c data (%d points)\n', length(time_01c));
else
    error('PT-01c file not found: %s', pt01c_file);
end

%% Calculate Drawdown (Pressure Change)
fprintf('Calculating drawdown profiles...\n');

% Calculate drawdown (pressure change from baseline)
drawdown_01a = calculate_drawdown(pressure_01a, time_01a);
drawdown_01b = calculate_drawdown(pressure_01b, time_01b);
drawdown_01c = calculate_drawdown(pressure_01c, time_01c);

%% Pump Test Schedules (for annotations) - Local Time (PST/PDT)
% PT-01a: Nov 7, 2023 (PST) - Convert from UTC to local
pump_start_01a = datetime(2023,11,7,16,45,0,'TimeZone','UTC');
pump_start_01a = pump_start_01a - hours(8); % Convert to PST
pump_end_01a = datetime(2023,11,7,22,40,0,'TimeZone','UTC');
pump_end_01a = pump_end_01a - hours(8); % Convert to PST
step1_01a = datetime(2023,11,7,17,45,0,'TimeZone','UTC') - hours(8); % 50 GPM
step2_01a = datetime(2023,11,7,18,45,0,'TimeZone','UTC') - hours(8); % 80 GPM
step3_01a = datetime(2023,11,7,19,45,0,'TimeZone','UTC') - hours(8); % 110 GPM
step4_01a = datetime(2023,11,7,20,45,0,'TimeZone','UTC') - hours(8); % 148 GPM

% PT-01b: Oct 31, 2023 (PDT) - Convert from UTC to local
pump_start_01b = datetime(2023,10,31,15,30,0,'TimeZone','UTC');
pump_start_01b = pump_start_01b - hours(7); % Convert to PDT
pump_end_01b = datetime(2023,10,31,19,30,0,'TimeZone','UTC');
pump_end_01b = pump_end_01b - hours(7); % Convert to PDT
step1_01b = datetime(2023,10,31,16,30,0,'TimeZone','UTC') - hours(7); % 50 GPM
step2_01b = datetime(2023,10,31,17,30,0,'TimeZone','UTC') - hours(7); % 80 GPM
step3_01b = datetime(2023,10,31,18,30,0,'TimeZone','UTC') - hours(7); % 110 GPM
step4_01b = datetime(2023,10,31,19,30,0,'TimeZone','UTC') - hours(7); % 148 GPM

% PT-01c: Oct 24, 2023 (PDT) - Convert from UTC to local
pump_start_01c = datetime(2023,10,24,15,18,0,'TimeZone','UTC');
pump_start_01c = pump_start_01c - hours(7); % Convert to PDT
pump_end_01c = datetime(2023,10,24,19,15,0,'TimeZone','UTC');
pump_end_01c = pump_end_01c - hours(7); % Convert to PDT
step1_01c = datetime(2023,10,24,16,15,0,'TimeZone','UTC') - hours(7); % 50 GPM
step2_01c = datetime(2023,10,24,17,15,0,'TimeZone','UTC') - hours(7); % 80 GPM
step3_01c = datetime(2023,10,24,18,15,0,'TimeZone','UTC') - hours(7); % 110 GPM
step4_01c = datetime(2023,10,24,19,15,0,'TimeZone','UTC') - hours(7); % 148 GPM

%% Create Dashboard
fprintf('Creating transducer data dashboard...\n');

figure('Position', [100, 100, 1400, 800]);

% PT-01a: Pressure and Drawdown
subplot(2,3,1);
plot(time_01a, pressure_01a, 'b-', 'LineWidth', 1.5);
title('PT-01a: Pressure Profile', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Pressure (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01a, pump_start_01a, pump_end_01a, step1_01a, step2_01a, step3_01a, step4_01a);

subplot(2,3,2);
plot(time_01a, drawdown_01a, 'r-', 'LineWidth', 1.5);
title('PT-01a: Drawdown Profile', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Drawdown (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01a, pump_start_01a, pump_end_01a, step1_01a, step2_01a, step3_01a, step4_01a);

% PT-01b: Pressure and Drawdown
subplot(2,3,3);
plot(time_01b, pressure_01b, 'b-', 'LineWidth', 1.5);
title('PT-01b: Pressure Profile', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Pressure (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01b, pump_start_01b, pump_end_01b, step1_01b, step2_01b, step3_01b, step4_01b);

subplot(2,3,4);
plot(time_01b, drawdown_01b, 'r-', 'LineWidth', 1.5);
title('PT-01b: Drawdown Profile', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Drawdown (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01b, pump_start_01b, pump_end_01b, step1_01b, step2_01b, step3_01b, step4_01b);

% PT-01c: Pressure and Drawdown
subplot(2,3,5);
plot(time_01c, pressure_01c, 'b-', 'LineWidth', 1.5);
title('PT-01c: Pressure Profile', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time', 'FontSize', 10);
ylabel('Pressure (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01c, pump_start_01c, pump_end_01c, step1_01c, step2_01c, step3_01c, step4_01c);

subplot(2,3,6);
plot(time_01c, drawdown_01c, 'r-', 'LineWidth', 1.5);
title('PT-01c: Drawdown Profile', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time', 'FontSize', 10);
ylabel('Drawdown (psi)', 'FontSize', 10);
grid on;
add_pump_annotations(time_01c, pump_start_01c, pump_end_01c, step1_01c, step2_01c, step3_01c, step4_01c);

sgtitle('Transducer Data Analysis - Pump Well Monitoring (Pressure & Drawdown)', 'FontSize', 16, 'FontWeight', 'bold');

%% Summary Statistics
fprintf('\n=== SUMMARY STATISTICS ===\n');

% PT-01a Statistics
fprintf('\nPT-01a (Nov 7, 2023 - PST):\n');
fprintf('  Pressure: %.2f ± %.2f psi (%.2f - %.2f)\n', mean(pressure_01a), std(pressure_01a), min(pressure_01a), max(pressure_01a));
fprintf('  Depth: %.2f ± %.2f ft (%.2f - %.2f)\n', mean(depth_01a), std(depth_01a), min(depth_01a), max(depth_01a));
fprintf('  Max Drawdown: %.2f psi\n', max(drawdown_01a));

% PT-01b Statistics
fprintf('\nPT-01b (Oct 31, 2023 - PDT):\n');
fprintf('  Pressure: %.2f ± %.2f psi (%.2f - %.2f)\n', mean(pressure_01b), std(pressure_01b), min(pressure_01b), max(pressure_01b));
fprintf('  Depth: %.2f ± %.2f ft (%.2f - %.2f)\n', mean(depth_01b), std(depth_01b), min(depth_01b), max(depth_01b));
fprintf('  Max Drawdown: %.2f psi\n', max(drawdown_01b));

% PT-01c Statistics
fprintf('\nPT-01c (Oct 24, 2023 - PDT):\n');
fprintf('  Pressure: %.2f ± %.2f psi (%.2f - %.2f)\n', mean(pressure_01c), std(pressure_01c), min(pressure_01c), max(pressure_01c));
fprintf('  Depth: %.2f ± %.2f ft (%.2f - %.2f)\n', mean(depth_01c), std(depth_01c), min(depth_01c), max(depth_01c));
fprintf('  Max Drawdown: %.2f psi\n', max(drawdown_01c));

%% Save Results
fprintf('\n=== SAVING RESULTS ===\n');
save('transducer_analysis_results.mat', 'time_01a', 'pressure_01a', 'depth_01a', 'drawdown_01a', ...
     'time_01b', 'pressure_01b', 'depth_01b', 'drawdown_01b', ...
     'time_01c', 'pressure_01c', 'depth_01c', 'drawdown_01c');
fprintf('✓ Saved transducer analysis results\n');

fprintf('\n=== TRANSDUCER ANALYSIS COMPLETE ===\n');

%% Helper Functions

function [time, pressure, temp, depth] = load_transducer_data(filename)
    % Load transducer data from CSV file
    fprintf('  Loading %s...\n', filename);
    
    % Read the file manually to handle the complex header
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    
    % Skip to line 25 (data starts here)
    for i = 1:24
        fgetl(fid);
    end
    
    % Read all data lines
    time_str = {};
    pressure = [];
    temp = [];
    depth = [];
    
    line = fgetl(fid);
    line_count = 0;
    
    while ischar(line) && line_count < 10000  % Safety limit
        line_count = line_count + 1;
        
        % Parse CSV line
        parts = strsplit(line, ',');
        if length(parts) >= 4
            time_str{end+1} = strrep(parts{1}, '"', '');  % Remove quotes
            pressure(end+1) = str2double(strrep(parts{2}, '"', ''));
            temp(end+1) = str2double(strrep(parts{3}, '"', ''));
            depth(end+1) = str2double(strrep(parts{4}, '"', ''));
        end
        
        line = fgetl(fid);
    end
    
    fclose(fid);
    
    % Convert to arrays
    time_str = time_str';
    pressure = pressure';
    temp = temp';
    depth = depth';
    
    % Convert time strings to datetime
    time = datetime(time_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', 'UTC');
    
    % Remove any NaN values
    valid_idx = ~isnan(pressure) & ~isnan(temp) & ~isnan(depth);
    time = time(valid_idx);
    pressure = pressure(valid_idx);
    temp = temp(valid_idx);
    depth = depth(valid_idx);
    
    if ~isempty(time)
        fprintf('    Time range: %s to %s\n', datestr(time(1)), datestr(time(end)));
        fprintf('    Data points: %d\n', length(time));
    else
        fprintf('    Warning: No valid data found\n');
    end
end

function drawdown = calculate_drawdown(pressure, time)
    % Calculate drawdown (pressure change from baseline)
    
    % Use first 10 minutes as baseline (120 data points at 5-second intervals)
    baseline_period = min(120, length(pressure));
    baseline_pressure = mean(pressure(1:baseline_period), 'omitnan');
    
    % Calculate drawdown (positive values indicate pressure decrease)
    drawdown = baseline_pressure - pressure;
end

function add_pump_annotations(time_data, pump_start, pump_end, step1, step2, step3, step4)
    % Add pump test annotations to plots
    
    % Get current axis limits
    ylim_current = ylim;
    
    % Add pump start/end lines
    xline(pump_start, '--k', 'LineWidth', 1.5);
    xline(pump_end, '--r', 'LineWidth', 1.5);
    
    % Add step change lines
    xline(step1, ':k', 'LineWidth', 1);
    xline(step2, ':k', 'LineWidth', 1);
    xline(step3, ':k', 'LineWidth', 1);
    xline(step4, ':k', 'LineWidth', 1);
    
    % Add labels
    text(pump_start, ylim_current(2)*0.9, 'Pump Start', 'FontSize', 8, 'Color', 'k', 'FontWeight', 'bold');
    text(pump_end, ylim_current(2)*0.9, 'Pump End', 'FontSize', 8, 'Color', 'r', 'FontWeight', 'bold');
    
    % Add step labels
    text(step1, ylim_current(2)*0.7, '50 GPM', 'FontSize', 7, 'Color', 'k', 'FontWeight', 'bold', 'Rotation', 90);
    text(step2, ylim_current(2)*0.7, '80 GPM', 'FontSize', 7, 'Color', 'k', 'FontWeight', 'bold', 'Rotation', 90);
    text(step3, ylim_current(2)*0.7, '110 GPM', 'FontSize', 7, 'Color', 'k', 'FontWeight', 'bold', 'Rotation', 90);
    text(step4, ylim_current(2)*0.7, '148 GPM', 'FontSize', 7, 'Color', 'k', 'FontWeight', 'bold', 'Rotation', 90);
end 