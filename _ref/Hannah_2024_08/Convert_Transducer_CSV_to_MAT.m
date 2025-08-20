%% Convert Transducer CSV Files to MAT Files
% Converts all transducer CSV data to MATLAB .mat files with consistent naming
% Creates files like: head_a_z1.mat, head_a_z2.mat, etc.

clear; clc; close all

fprintf('=== CONVERTING TRANSDUCER CSV TO MAT FILES ===\n');

%% Setup paths
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');
head_dir = fullfile(data_dir, 'head');

% Create head directory if it doesn't exist
if ~exist(head_dir, 'dir')
    mkdir(head_dir);
    fprintf('Created head directory: %s\n', head_dir);
end

%% Function to load and process transducer data
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
    
    % Extract data
    depth_ft = trans_data.Depth_ft;
    pressure_psi = trans_data.Pressure_psi;
    
    % Find baseline before pumping starts
    % Use first 60 points as baseline
    baseline_depth = mean(depth_ft(1:60), 'omitnan');
    % Positive = deeper water level (more drawdown)
    drawdown_ft = depth_ft - baseline_depth;
    
    % Return raw depth data
    depth_ft_raw = depth_ft;
    
    fprintf('  Processed: %d data points, baseline: %.2f ft, max drawdown: %.2f ft\n', ...
            length(drawdown_ft), baseline_depth, max(drawdown_ft));
end

%% Process PM7 A files (PT-01a)
fprintf('\n=== PROCESSING PM7 A (PT-01a) FILES ===\n');

% Define PM7 A file paths
trans01a_files = {
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_1_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_2_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_3_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_4_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_5_SDT_PT-01a.csv');
};

% Process each zone for PM7 A
for z = 1:5
    fprintf('Processing PM7 A Zone %d...\n', z);
    
    if exist(trans01a_files{z}, 'file')
        % Load and process the data
        [Date, Drawdownft, Pressurepsi, Depthft] = load_transducer_data(trans01a_files{z});
        
        % Create output filename
        output_file = fullfile(head_dir, sprintf('head_a_z%d.mat', z));
        
        % Save to .mat file with consistent variable names
        save(output_file, 'Date', 'Drawdownft', 'Pressurepsi', 'Depthft');
        
        fprintf('  ✓ Saved: %s\n', output_file);
    else
        fprintf('  ❌ File not found: %s\n', trans01a_files{z});
    end
end

%% Process PM7 B files (PT-01b)
fprintf('\n=== PROCESSING PM7 B (PT-01b) FILES ===\n');

% Define PM7 B file paths
trans01b_files = {
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_1_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_2_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_3_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_4_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_5_SDT_PT-01b.csv');
};

% Process each zone for PM7 B
for z = 1:5
    fprintf('Processing PM7 B Zone %d...\n', z);
    
    if exist(trans01b_files{z}, 'file')
        % Load and process the data
        [Date, Drawdownft, Pressurepsi, Depthft] = load_transducer_data(trans01b_files{z});
        
        % Create output filename
        output_file = fullfile(head_dir, sprintf('head_b_z%d.mat', z));
        
        % Save to .mat file with consistent variable names
        save(output_file, 'Date', 'Drawdownft', 'Pressurepsi', 'Depthft');
        
        fprintf('  ✓ Saved: %s\n', output_file);
    else
        fprintf('  ❌ File not found: %s\n', trans01b_files{z});
    end
end

%% Process PM7 C files (PT-01c) - zones 2-5 only
fprintf('\n=== PROCESSING PM7 C (PT-01c) FILES ===\n');

% Define PM7 C file paths (zones 2-5 only)
trans01c_files = {
    '';  % Zone 1 - not available
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_2_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_3_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_4_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_5_SDT_PT-01c.csv');
};

% Process zones 2-5 for PM7 C
for z = 2:5
    fprintf('Processing PM7 C Zone %d...\n', z);
    
    if ~isempty(trans01c_files{z}) && exist(trans01c_files{z}, 'file')
        % Load and process the data
        [Date, Drawdownft, Pressurepsi, Depthft] = load_transducer_data(trans01c_files{z});
        
        % Create output filename
        output_file = fullfile(head_dir, sprintf('head_c_z%d.mat', z));
        
        % Save to .mat file with consistent variable names
        save(output_file, 'Date', 'Drawdownft', 'Pressurepsi', 'Depthft');
        
        fprintf('  ✓ Saved: %s\n', output_file);
    else
        if z == 1
            fprintf('  — Zone 1 not available for PM7 C\n');
        else
            fprintf('  ❌ File not found: %s\n', trans01c_files{z});
        end
    end
end

%% Summary
fprintf('\n=== CONVERSION COMPLETE ===\n');
fprintf('Created .mat files in: %s\n', head_dir);

% List all created files
fprintf('\nCreated files:\n');
mat_files = dir(fullfile(head_dir, 'head_*.mat'));
for i = 1:length(mat_files)
    fprintf('  ✓ %s\n', mat_files(i).name);
end

fprintf('\n✓ All transducer data converted to .mat format!\n');
fprintf('These files can now be loaded in scripts using: load(''head_a_z1.mat'')\n');