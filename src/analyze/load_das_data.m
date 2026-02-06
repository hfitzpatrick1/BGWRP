function das_data = load_das_data(test_label, config)
%LOAD_DAS_DATA Load DAS data for a specific test
%
% Inputs:
%   test_label - Test label (e.g., 'PT01c_Recovery_short')
%   config     - Configuration structure
%
% Outputs:
%   das_data - DAS data structure or empty if not found

das_data = [];

% Look for DAS data in _active directory
active_dir = fullfile(config.base_input, '_active', test_label, '_das');
mat_files = dir(fullfile(active_dir, '*.mat'));

if length(mat_files) == 1
    data_file = fullfile(active_dir, mat_files(1).name);
    try
        loaded_data = load(data_file);
        das_data = loaded_data;
        console_log('  Loaded DAS data: %s\n', mat_files(1).name);
    catch ME
        console_log('  Error loading DAS data: %s\n', ME.message);
    end
else
    console_log('  No DAS data found for %s\n', test_label);
end
end
