%% Batch Process All PM7 Transducer Data
% Processes all PT-01a, PT-01b, and PT-01c transducer files
% Uses the existing file structure from your data directory

clear; clc; close all;

console_log('=== BATCH PROCESSING ALL PM7 TRANSDUCER DATA ===\n\n');

%% Setup paths
script_dir = fileparts(mfilename('fullpath'));
data_dir = fullfile(script_dir, 'data');

%% Define zone depths for labeling
zone_info = struct();
zone_info.z1 = '645-665 ft';
zone_info.z2 = '485-505 ft';
zone_info.z3 = '420-440 ft';
zone_info.z4 = '360-380 ft';
zone_info.z5 = '290-310 ft';

%% Process PT-01a files (all 5 zones)
console_log('=== PROCESSING PT-01a TRANSDUCER DATA ===\n');

pt01a_files = {
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_1_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_2_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_3_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_4_SDT_PT-01a.csv');
    fullfile(data_dir, 'Transducer Data', 'a', 'VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_5_SDT_PT-01a.csv');
};

for z = 1:5
    console_log('\n--- Processing PT-01a Zone %d ---\n', z);
    if exist(pt01a_files{z}, 'file')
        zone_label = sprintf('PT-01a Zone %d (%s)', z, zone_info.(sprintf('z%d', z)));
        try
            process_pm7_transducer_data(pt01a_files{z}, zone_label);
            console_log('✓ PT-01a Zone %d complete\n', z);
        catch ME
            console_log('❌ PT-01a Zone %d failed: %s\n', z, ME.message);
        end
    else
        console_log('⚠ File not found: %s\n', pt01a_files{z});
    end
end

%% Process PT-01b files (all 5 zones)
console_log('\n\n=== PROCESSING PT-01b TRANSDUCER DATA ===\n');

pt01b_files = {
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_1_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_2_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_3_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_4_SDT_PT-01b.csv');
    fullfile(data_dir, 'Transducer Data', 'b', 'VuSitu_2023-10-31_08-00-00_PM7_Log_PM7_5_SDT_PT-01b.csv');
};

for z = 1:5
    console_log('\n--- Processing PT-01b Zone %d ---\n', z);
    if exist(pt01b_files{z}, 'file')
        zone_label = sprintf('PT-01b Zone %d (%s)', z, zone_info.(sprintf('z%d', z)));
        try
            process_pm7_transducer_data(pt01b_files{z}, zone_label);
            console_log('✓ PT-01b Zone %d complete\n', z);
        catch ME
            console_log('❌ PT-01b Zone %d failed: %s\n', z, ME.message);
        end
    else
        console_log('⚠ File not found: %s\n', pt01b_files{z});
    end
end

%% Process PT-01c files (zones 2-5 only, zone 1 incomplete)
console_log('\n\n=== PROCESSING PT-01c TRANSDUCER DATA ===\n');

pt01c_files = {
    '';  % Zone 1 not available
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_2_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_3_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_4_SDT_PT-01c.csv');
    fullfile(data_dir, 'Transducer Data', 'c', 'VuSitu_2023-10-24_08-00-00_PM7_Log_PM7_5_SDT_PT-01c.csv');
};

for z = 2:5  % Skip zone 1
    console_log('\n--- Processing PT-01c Zone %d ---\n', z);
    if ~isempty(pt01c_files{z}) && exist(pt01c_files{z}, 'file')
        zone_label = sprintf('PT-01c Zone %d (%s)', z, zone_info.(sprintf('z%d', z)));
        try
            process_pm7_transducer_data(pt01c_files{z}, zone_label);
            console_log('✓ PT-01c Zone %d complete\n', z);
        catch ME
            console_log('❌ PT-01c Zone %d failed: %s\n', z, ME.message);
        end
    else
        if z == 1
            console_log('— Zone 1 not available for PT-01c (skipped)\n');
        else
            console_log('⚠ File not found: %s\n', pt01c_files{z});
        end
    end
end

%% Summary
console_log('\n\n=== BATCH PROCESSING COMPLETE ===\n');
console_log('Processed transducer data for:\n');
console_log('  - PT-01a: 5 zones\n');
console_log('  - PT-01b: 5 zones\n');
console_log('  - PT-01c: 4 zones (zones 2-5)\n');
console_log('\nCleaned data files saved in respective ''processed'' subdirectories.\n');
console_log('Check each file''s processed folder for:\n');
console_log('  - *_cleaned.mat - MATLAB format for analysis\n');
console_log('  - *_cleaned.csv - CSV format for review\n\n');
