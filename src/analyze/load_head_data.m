function head_data = load_head_data(test_label, config)
%LOAD_HEAD_DATA Load head data for a specific test
%
% Inputs:
%   test_label - Test label (e.g., 'PT01c_Recovery_short')
%   config     - Configuration structure
%
% Outputs:
%   head_data - Head data structure or empty if not found

head_data = [];

% Look for head data in _active directory
active_dir = fullfile(config.base_input, '_active', test_label, '_head');
mat_files = dir(fullfile(active_dir, '*.mat'));

if length(mat_files) == 1
    data_file = fullfile(active_dir, mat_files(1).name);
    try
        loaded_data = load(data_file);
        head_data = loaded_data;
        console_log('  Loaded head data: %s\n', mat_files(1).name);
    catch ME
        console_log('  Error loading head data: %s\n', ME.message);
    end
else
    console_log('  No head data found for %s\n', test_label);
end
end
