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
    console_log('No MAT files found in: %s\n', mat_dir);
    console_log('Trying alternative location...\n');
    mat_dir = 'C:\Coding\BGWRP\data\_BATCH_old\_tdms_to_mat\PT01c_Recovery_short\_das';
    mat_files = dir(fullfile(mat_dir, '*.mat'));
end

if isempty(mat_files)
    error('No MAT files found. Please run TDMS conversion first.');
end

first_file = fullfile(mat_dir, mat_files(1).name);
console_log('=== CHECKING MAT FILE UNITS (from TDMS conversion) ===\n');
console_log('File: %s\n\n', first_file);

% Load the MAT file
console_log('Loading MAT file...\n');
try
    loaded_data = load(first_file);
    
    % Check what variables are in the file
    console_log('\n=== FILE CONTENTS ===\n');
    vars = fieldnames(loaded_data);
    console_log('Variables in file: %s\n', strjoin(vars, ', '));
    
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
    
    console_log('\n=== DATA UNITS CHECK ===\n');
    console_log('Data variable: %s\n', data_var);
    console_log('Data size: [%d x %d]\n', size(data, 1), size(data, 2));
    console_log('Data range: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
    
    % Check for units
    if isfield(loaded_data, 'data_units')
        console_log('Stored units: %s\n', loaded_data.data_units);
        data_units = loaded_data.data_units;
    else
        console_log('WARNING: data_units variable not found\n');
        data_units = 'unknown';
    end
    
    % Check for sampling frequency
    if isfield(loaded_data, 'fs_f')
        console_log('Sampling frequency: %.2f Hz\n', loaded_data.fs_f);
        fs_f = loaded_data.fs_f;
    else
        console_log('WARNING: fs_f (sampling frequency) not found\n');
        fs_f = 100;  % Default assumption
        console_log('  Assuming %.0f Hz (default)\n', fs_f);
    end
    
    % Calculate what the units should be
    console_log('\n=== UNIT CONVERSION ANALYSIS ===\n');
    console_log('Data size: [%d time × %d channels]\n', size(data, 1), size(data, 2));
    console_log('If at 100 Hz: %.1f seconds of data\n', size(data, 1) / fs_f);
    console_log('If at 1 Hz: %.1f seconds of data\n', size(data, 1));
    
    if strcmp(data_units, 'nm/sample')
        console_log('\nData is in: nm/sample\n');
        console_log('Sampling frequency: %.0f Hz\n', fs_f);
        
        % Check if this is decimated data (1 Hz) or original (100 Hz)
        time_span_sec = size(data, 1) / fs_f;
        if time_span_sec < 120  % Less than 2 minutes suggests 100 Hz data
            console_log('  ⚠ This appears to be ORIGINAL 100 Hz data (%.1f seconds)\n', time_span_sec);
            console_log('  To convert to nm/s: multiply by %.0f\n', fs_f);
            console_log('  Current range: [%.3e, %.3e] nm/sample\n', min(data(:)), max(data(:)));
            console_log('  After conversion: [%.3e, %.3e] nm/s\n', ...
                min(data(:)) * fs_f, max(data(:)) * fs_f);
            console_log('  ⚠ WARNING: This is too large! Advisor''s data is ~±0.25 nm/s\n');
        else
            console_log('  ✓ This appears to be DECIMATED 1 Hz data (%.1f seconds)\n', time_span_sec);
            console_log('  For decimated data: values are already averaged over 1 second\n');
            console_log('  Current range: [%.3e, %.3e] nm/sample\n', min(data(:)), max(data(:)));
            console_log('  If already in nm/s: [%.3e, %.3e] nm/s\n', min(data(:)), max(data(:)));
            console_log('  If need conversion: [%.3e, %.3e] nm/s (×%.0f)\n', ...
                min(data(:)) * fs_f, max(data(:)) * fs_f, fs_f);
            console_log('  ✓ Advisor''s data is ~±0.25 nm/s - check which matches\n');
        end
    elseif strcmp(data_units, 'nm/s')
        console_log('Data is already in: nm/s\n');
        console_log('  Current range: [%.3e, %.3e] nm/s\n', min(data(:)), max(data(:)));
        console_log('  ✓ This should match advisor''s ~±0.25 nm/s\n');
    else
        console_log('Unknown units: %s\n', data_units);
        console_log('  Current range: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
        console_log('  If nm/sample: after ×%.0f = [%.3e, %.3e] nm/s\n', ...
            fs_f, min(data(:)) * fs_f, max(data(:)) * fs_f);
    end
    
catch ME
    console_log('ERROR reading TDMS file: %s\n', ME.message);
    console_log('Stack trace:\n');
    for i = 1:length(ME.stack)
        console_log('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end

console_log('\n=== CHECK COMPLETE ===\n');

