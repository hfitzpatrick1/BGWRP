%% Check Raw TDMS File Values
% This script reads a raw TDMS file directly to see original values

clear all
close all
clc

% Path to raw TDMS files
tdms_dir = 'C:\Coding\BGWRP\data\_BATCH_old\_raw\PT01c_Recovery_short\_das';

% Get first TDMS file
tdms_files = dir(fullfile(tdms_dir, '*.tdms'));
if isempty(tdms_files)
    error('No TDMS files found in: %s', tdms_dir);
end

first_file = fullfile(tdms_dir, tdms_files(1).name);
console_log('=== CHECKING RAW TDMS FILE ===\n');
console_log('File: %s\n\n', first_file);

% Add path to TDMS reader
addpath('C:\Coding\BGWRP\src\prepare');

% Set up to read ONE file without saving
directory = [tdms_dir '\'];
filesearch = tdms_files(1).name;
fileindex = 1;  % Just read the first file
save_data = 0;  % Don't save
save_directory = 'C:\temp';  % Dummy directory (won't be used)

% Create temp directory if needed
if ~exist(save_directory, 'dir')
    mkdir(save_directory);
end

console_log('Reading raw TDMS file...\n');
try
    % Run the Silixa script to convert TDMS
    Silixa_TDMSDataToPhysicalDispRate;
    
    % Check what we got
    if exist('data', 'var')
        console_log('\n=== RAW TDMS DATA ===\n');
        console_log('Data size: [%d time × %d channels]\n', size(data, 1), size(data, 2));
        console_log('Data range: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
        
        if exist('data_units', 'var')
            console_log('Units: %s\n', data_units);
        end
        
        if exist('fs_f', 'var')
            console_log('Sampling frequency: %.2f Hz\n', fs_f);
            console_log('Time span: %.1f seconds\n', size(data, 1) / fs_f);
        end
        
        % Calculate what this should be after conversion
        console_log('\n=== CONVERSION ANALYSIS ===\n');
        if strcmp(data_units, 'nm/sample')
            console_log('Raw data is in: nm/sample at %.0f Hz\n', fs_f);
            console_log('Raw range: [%.3e, %.3e] nm/sample\n', min(data(:)), max(data(:)));
            console_log('To convert to nm/s: multiply by %.0f\n', fs_f);
            console_log('After conversion: [%.3e, %.3e] nm/s\n', ...
                min(data(:)) * fs_f, max(data(:)) * fs_f);
            console_log('Advisor''s data: ~±0.25 nm/s\n');
            
            % Check if raw values make sense
            raw_abs_max = max(abs(data(:)));
            if raw_abs_max * fs_f > 100
                console_log('  ⚠ WARNING: Converted values are very large!\n');
                console_log('  This suggests the raw TDMS values might be wrong\n');
            elseif raw_abs_max * fs_f < 0.01
                console_log('  ⚠ WARNING: Converted values are very small!\n');
            else
                console_log('  ✓ Converted values seem reasonable\n');
            end
        end
        
    else
        console_log('ERROR: Data variable not created\n');
    end
    
catch ME
    console_log('ERROR: %s\n', ME.message);
    if ~isempty(ME.stack)
        console_log('  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

console_log('\n=== CHECK COMPLETE ===\n');

