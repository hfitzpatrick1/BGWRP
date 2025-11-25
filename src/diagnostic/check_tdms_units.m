%% Check TDMS File Units
% This script checks what units are stored in the converted MAT files

clear all
close all
clc

% Path to converted MAT files (from TDMS conversion)
mat_dir = 'C:\Coding\BGWRP\data\_BATCH\_tdms_to_mat\PT01c_Recovery_short\_das';

% Get first MAT file
mat_files = dir(fullfile(mat_dir, '*.mat'));
if isempty(mat_files)
    fprintf('No MAT files found in: %s\n', mat_dir);
    fprintf('Trying alternative location...\n');
    mat_dir = 'C:\Coding\BGWRP\data\_BATCH_old\_tdms_to_mat\PT01c_Recovery_short\_das';
    mat_files = dir(fullfile(mat_dir, '*.mat'));
end

if isempty(mat_files)
    error('No MAT files found. Please run TDMS conversion first.');
end

first_file = fullfile(mat_dir, mat_files(1).name);
fprintf('=== CHECKING MAT FILE UNITS (from TDMS conversion) ===\n');
fprintf('File: %s\n\n', first_file);

% Load the MAT file
fprintf('Loading MAT file...\n');
try
    loaded_data = load(first_file);
    
    % Check what variables are in the file
    fprintf('\n=== FILE CONTENTS ===\n');
    vars = fieldnames(loaded_data);
    fprintf('Variables in file: %s\n', strjoin(vars, ', '));
    
    % Get data
    if isfield(loaded_data, 'data')
        data = loaded_data.data;
        data_var = 'data';
    elseif isfield(loaded_data, 'Data')
        data = loaded_data.Data;
        data_var = 'Data';
    else
        error('No data variable found. Available: %s', strjoin(vars, ', '));
    end
    
    fprintf('\n=== DATA UNITS CHECK ===\n');
    fprintf('Data variable: %s\n', data_var);
    fprintf('Data size: [%d x %d]\n', size(data, 1), size(data, 2));
    fprintf('Data range: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
    
    % Check for units
    if isfield(loaded_data, 'data_units')
        fprintf('Stored units: %s\n', loaded_data.data_units);
        data_units = loaded_data.data_units;
    else
        fprintf('WARNING: data_units variable not found\n');
        data_units = 'unknown';
    end
    
    % Check for sampling frequency
    if isfield(loaded_data, 'fs_f')
        fprintf('Sampling frequency: %.2f Hz\n', loaded_data.fs_f);
        fs_f = loaded_data.fs_f;
    else
        fprintf('WARNING: fs_f (sampling frequency) not found\n');
        fs_f = 100;  % Default assumption
        fprintf('  Assuming %.0f Hz (default)\n', fs_f);
    end
    
    % Calculate what the units should be
    fprintf('\n=== UNIT CONVERSION ANALYSIS ===\n');
    fprintf('Data size: [%d time × %d channels]\n', size(data, 1), size(data, 2));
    fprintf('If at 100 Hz: %.1f seconds of data\n', size(data, 1) / fs_f);
    fprintf('If at 1 Hz: %.1f seconds of data\n', size(data, 1));
    
    if strcmp(data_units, 'nm/sample')
        fprintf('\nData is in: nm/sample\n');
        fprintf('Sampling frequency: %.0f Hz\n', fs_f);
        
        % Check if this is decimated data (1 Hz) or original (100 Hz)
        time_span_sec = size(data, 1) / fs_f;
        if time_span_sec < 120  % Less than 2 minutes suggests 100 Hz data
            fprintf('  ⚠ This appears to be ORIGINAL 100 Hz data (%.1f seconds)\n', time_span_sec);
            fprintf('  To convert to nm/s: multiply by %.0f\n', fs_f);
            fprintf('  Current range: [%.3e, %.3e] nm/sample\n', min(data(:)), max(data(:)));
            fprintf('  After conversion: [%.3e, %.3e] nm/s\n', ...
                min(data(:)) * fs_f, max(data(:)) * fs_f);
            fprintf('  ⚠ WARNING: This is too large! Advisor''s data is ~±0.25 nm/s\n');
        else
            fprintf('  ✓ This appears to be DECIMATED 1 Hz data (%.1f seconds)\n', time_span_sec);
            fprintf('  For decimated data: values are already averaged over 1 second\n');
            fprintf('  Current range: [%.3e, %.3e] nm/sample\n', min(data(:)), max(data(:)));
            fprintf('  If already in nm/s: [%.3e, %.3e] nm/s\n', min(data(:)), max(data(:)));
            fprintf('  If need conversion: [%.3e, %.3e] nm/s (×%.0f)\n', ...
                min(data(:)) * fs_f, max(data(:)) * fs_f, fs_f);
            fprintf('  ✓ Advisor''s data is ~±0.25 nm/s - check which matches\n');
        end
    elseif strcmp(data_units, 'nm/s')
        fprintf('Data is already in: nm/s\n');
        fprintf('  Current range: [%.3e, %.3e] nm/s\n', min(data(:)), max(data(:)));
        fprintf('  ✓ This should match advisor''s ~±0.25 nm/s\n');
    else
        fprintf('Unknown units: %s\n', data_units);
        fprintf('  Current range: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
        fprintf('  If nm/sample: after ×%.0f = [%.3e, %.3e] nm/s\n', ...
            fs_f, min(data(:)) * fs_f, max(data(:)) * fs_f);
    end
    
catch ME
    fprintf('ERROR reading TDMS file: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

fprintf('\n=== CHECK COMPLETE ===\n');

