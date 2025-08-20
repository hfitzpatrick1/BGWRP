%% PM-07 Recovery Analysis - Configurable Version
% This is a refactored version of PM07_Recovery_Analysis.m that uses
% external configuration files for better modularity and easier subset analysis
%
% Key improvements:
% 1. All hard-coded parameters moved to PM07_Recovery_Config.m
% 2. Automatic timing detection for data subsets
% 3. Easier to modify for different time windows
%
% Usage:
%   1. Modify PM07_Recovery_Config.m if needed
%   2. Run this script
%   3. For data subsets, timing will be auto-detected when possible

%% Setup and Configuration
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
data_dir = fullfile(project_dir, 'data');

% Load configuration
fprintf('=== LOADING CONFIGURATION ===\n');
config = PM07_Recovery_Config();

% Attempt automatic timing detection (especially important for data subsets)
config = PM07_Auto_Timing(data_dir, config);

%% Display Configuration Summary
fprintf('\n=== CONFIGURATION SUMMARY ===\n');
fprintf('Recovery time windows:\n');
fprintf('  PT-01a: %s to %s (%.1f minutes)\n', ...
    config.recovery_windows.a.start, config.recovery_windows.a.end, ...
    minutes(config.recovery_windows.a.end - config.recovery_windows.a.start));
fprintf('  PT-01b: %s to %s (%.1f minutes)\n', ...
    config.recovery_windows.b.start, config.recovery_windows.b.end, ...
    minutes(config.recovery_windows.b.end - config.recovery_windows.b.start));
fprintf('  PT-01b plot window: %s to %s (%.1f minutes)\n', ...
    config.recovery_windows.b.plot_start, config.recovery_windows.b.plot_end, ...
    minutes(config.recovery_windows.b.plot_end - config.recovery_windows.b.plot_start));
fprintf('  PT-01c: %s to %s (%.1f minutes)\n', ...
    config.recovery_windows.c.start, config.recovery_windows.c.end, ...
    minutes(config.recovery_windows.c.end - config.recovery_windows.c.start));

fprintf('\nDAS timing configuration:\n');
fprintf('  PT-01a: %s (source: %s)\n', config.das_timing.a.start, config.das_timing.a.source);
fprintf('  PT-01b: %s (source: %s)\n', config.das_timing.b.start, config.das_timing.b.source);
fprintf('  PT-01c: %s (source: %s)\n', config.das_timing.c.start, config.das_timing.c.source);

%% Load Head Data
fprintf('\n=== LOADING HEAD DATA ===\n');

% Load all PT-01a head data
fprintf('\nPT-01a head data files:\n');
data_a = struct();
for i = 1:length(config.head_files.a)
    file_path = fullfile(data_dir, config.directories.head_data, config.head_files.a{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = config.head_files.a{i}(8:9); % Extract z1, z2, etc.
        data_a.(zone_name).Date = Date;
        data_a.(zone_name).Date.TimeZone = 'UTC';
        data_a.(zone_name).Drawdownft = Drawdownft;
        data_a.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_a.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s\n', ...
            zone_name, data_a.(zone_name).Depthft, data_a.(zone_name).n_points, ...
            min(Date), max(Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', config.head_files.a{i});
    end
end

% Load all PT-01b head data
fprintf('\nPT-01b head data files:\n');
data_b = struct();
for i = 1:length(config.head_files.b)
    file_path = fullfile(data_dir, config.directories.head_data, config.head_files.b{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = config.head_files.b{i}(8:9); % Extract z1, z2, etc.
        data_b.(zone_name).Date = Date;
        data_b.(zone_name).Date.TimeZone = 'UTC';
        data_b.(zone_name).Drawdownft = Drawdownft;
        data_b.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_b.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s\n', ...
            zone_name, data_b.(zone_name).Depthft, data_b.(zone_name).n_points, ...
            min(Date), max(Date));
    else
        fprintf('  %s: FILE NOT FOUND\n', config.head_files.b{i});
    end
end

% Load all PT-01c head data
fprintf('\nPT-01c head data files:\n');
data_c = struct();
for i = 1:length(config.head_files.c)
    file_path = fullfile(data_dir, config.directories.head_data, config.head_files.c{i});
    if exist(file_path, 'file')
        load(file_path);
        zone_name = config.head_files.c{i}(8:9); % Extract z2, z3, etc.
        
        % Apply timing adjustment for PT-01c
        data_c.(zone_name).Date = Date + seconds(config.analysis.head_timing_adjustment_c);
        data_c.(zone_name).Date.TimeZone = 'UTC';
        data_c.(zone_name).Drawdownft = Drawdownft;
        data_c.(zone_name).Depthft = mean(Depthft, 'omitnan');
        data_c.(zone_name).n_points = length(Date);
        fprintf('  %s: depth %.1f ft, %d data points, %s to %s (adjusted +%ds)\n', ...
            zone_name, data_c.(zone_name).Depthft, data_c.(zone_name).n_points, ...
            min(data_c.(zone_name).Date), max(data_c.(zone_name).Date), ...
            config.analysis.head_timing_adjustment_c);
    else
        fprintf('  %s: FILE NOT FOUND\n', config.head_files.c{i});
    end
end

%% Load DAS Data
fprintf('\n=== LOADING DAS DATA ===\n');

% PT-01a DAS data
load(fullfile(data_dir, config.das_files.a));
data1Hz_a = decdata;

% PT-01b DAS data
load(fullfile(data_dir, config.das_files.b));
data1Hz_b = decdata;

% PT-01c DAS data
load(fullfile(data_dir, config.das_files.c));
if exist('decdata', 'var')
    data1Hz_c = decdata;
else
    data1Hz_c = data1Hz;
end

fprintf('DAS data loaded successfully for all three tests\n');

%% Create time arrays using configuration
fprintf('\n=== CREATING TIME ARRAYS ===\n');

% Use configured start times (potentially auto-detected)
Tdas_a = config.das_timing.a.start + seconds(0:size(data1Hz_a,1)-1);
Tdas_b = config.das_timing.b.start + seconds(0:size(data1Hz_b,1)-1) + seconds(config.das_timing.b.adjustment);
Tdas_c = config.das_timing.c.start + seconds(0:size(data1Hz_c,1)-1) + seconds(config.das_timing.c.adjustment);

fprintf('DAS time arrays created:\n');
fprintf('  PT-01a: %s to %s (%d points)\n', min(Tdas_a), max(Tdas_a), length(Tdas_a));
fprintf('  PT-01b: %s to %s (%d points)\n', min(Tdas_b), max(Tdas_b), length(Tdas_b));
fprintf('  PT-01c: %s to %s (%d points)\n', min(Tdas_c), max(Tdas_c), length(Tdas_c));

%% Validation: Check if recovery windows are within DAS data range
fprintf('\n=== VALIDATING TIME WINDOWS ===\n');

tests = {'a', 'b', 'c'};
test_names = {'PT-01a', 'PT-01b', 'PT-01c'};
time_arrays = {Tdas_a, Tdas_b, Tdas_c};

for i = 1:length(tests)
    test = tests{i};
    test_name = test_names{i};
    Tdas = time_arrays{i};
    
    recovery_start = config.recovery_windows.(test).start;
    recovery_end = config.recovery_windows.(test).end;
    
    if recovery_start >= min(Tdas) && recovery_end <= max(Tdas)
        fprintf('  ✓ %s: Recovery window is within DAS data range\n', test_name);
    else
        fprintf('  ⚠ %s: Recovery window may be outside DAS data range!\n', test_name);
        fprintf('    Recovery: %s to %s\n', recovery_start, recovery_end);
        fprintf('    DAS data: %s to %s\n', min(Tdas), max(Tdas));
    end
end

fprintf('\n=== CONFIGURATION COMPLETE ===\n');
fprintf('The analysis can now proceed with properly configured parameters.\n');
fprintf('To modify timing or windows, edit PM07_Recovery_Config.m and re-run.\n');

% Note: The rest of the original analysis code would continue here...
% This is just showing the configuration and setup portion
