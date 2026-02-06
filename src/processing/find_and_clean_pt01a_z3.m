%% Find and Clean PT-01a Zone 3
% This script searches for your file and processes it automatically

console_log('Searching for PT-01a Zone 3 transducer file...\n\n');

% Search in multiple possible locations
search_locations = {
    'C:/Coding/BGWRP/data/Transducer Data/a';
    'C:/Coding/BGWRP/Transducer Data 10_24_2023/Prepped/PT-01a';
    'C:/Coding/BGWRP';
};

% Possible file name patterns
file_patterns = {
    'PM7_3_SDT_PT-01a*.csv';
    '*PM7_3*PT-01a*.csv';
    'VuSitu*PM7_3*PT-01a*.csv';
};

found_file = '';

% Search for the file
for i = 1:length(search_locations)
    if exist(search_locations{i}, 'dir')
        for j = 1:length(file_patterns)
            files = dir(fullfile(search_locations{i}, file_patterns{j}));
            if ~isempty(files)
                found_file = fullfile(files(1).folder, files(1).name);
                console_log('Found file: %s\n\n', found_file);
                break;
            end
        end
        if ~isempty(found_file)
            break;
        end
    end
end

% Check if we found the file
if isempty(found_file)
    console_log('Could not find PT-01a Zone 3 file!\n');
    console_log('Please manually specify the file path:\n');
    console_log('  csv_file = ''YOUR/PATH/HERE.csv'';\n');
    console_log('  process_pm7_transducer_data(csv_file, ''PT-01a Zone 3'');\n');
    return;
end

% Process the file
console_log('Processing transducer data...\n\n');
process_pm7_transducer_data(found_file, 'PT-01a Zone 3 (420-440 ft)');

console_log('\n=== COMPLETE ===\n');
console_log('Check the output in the ''processed'' subfolder next to your data file.\n');
