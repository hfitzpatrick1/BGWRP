%% Quick Clean PT-01a Zone 3
% Simple script to clean PT-01a Zone 3 transducer data
% No dependencies on paths or complex logic

console_log('Starting PT-01a Zone 3 processing...\n\n');

% Define the file path with forward slashes (MATLAB-safe)
csv_file = 'C:/Coding/BGWRP/data/Transducer Data/a/VuSitu_2023-11-07_08-00-00_PM7_Log_PM7_3_SDT_PT-01a.csv';

% Check if file exists
if ~exist(csv_file, 'file')
    error('File not found: %s', csv_file);
end

% Process the data
console_log('Found file: %s\n\n', csv_file);
process_pm7_transducer_data(csv_file, 'PT-01a Zone 3 (420-440 ft)');

console_log('\nDone!\n');
