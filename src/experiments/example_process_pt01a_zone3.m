%% Example: Process PT-01a Zone 3 Transducer Data
% This script shows how to process a single PM7 transducer file
% Customize the file path and zone name as needed

clear; clc; close all;

console_log('=== PROCESSING PT-01a ZONE 3 TRANSDUCER DATA ===\n\n');

%% Define file path
% Your PT-01a Zone 3 file is in the standard location:
csv_file = 'C:/Coding/BGWRP/data/Transducer Data/a/VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_3_SDT_PT-01a.csv';

%% Check if file exists
if ~exist(csv_file, 'file')
    console_log('❌ File not found: %s\n\n', csv_file);
    console_log('📋 Please update the csv_file path in this script (line 10)\n');
    console_log('   to point to your actual transducer data file.\n\n');
    
    % Try to help locate the file
    console_log('Searching for PM7 transducer files in common locations...\n');
    search_paths = {
        'C:/Coding/BGWRP/data/Transducer Data';
        'C:/Coding/BGWRP/Transducer Data 10_24_2023';
        'C:/Coding/BGWRP';
    };
    
    for i = 1:length(search_paths)
        if exist(search_paths{i}, 'dir')
            console_log('\nChecking: %s\n', search_paths{i});
            csv_files = dir(fullfile(search_paths{i}, '**', '*PT-01a*.csv'));
            if ~isempty(csv_files)
                console_log('  Found %d CSV file(s):\n', length(csv_files));
                for j = 1:min(5, length(csv_files))
                    console_log('    - %s\n', fullfile(csv_files(j).folder, csv_files(j).name));
                end
                if length(csv_files) > 5
                    console_log('    ... and %d more files\n', length(csv_files) - 5);
                end
            end
        end
    end
    
    return;
end

%% Process the data
zone_name = 'PT-01a Zone 3 (420-440 ft depth)';

console_log('Processing file: %s\n', csv_file);
console_log('Zone: %s\n\n', zone_name);

% Call the processing function
process_pm7_transducer_data(csv_file, zone_name);

console_log('\n✓ Processing complete!\n');
console_log('Check the ''processed'' subfolder for cleaned data files.\n');
