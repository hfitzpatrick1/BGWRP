function purge_unraw_directories(base_input)
%PURGE_UNRAW_DIRECTORIES Archive non-underscore directories to _raw and purge intermediate processing
%
% 1. Moves any non-underscore directories to _raw (if not already there)
% 2. Removes intermediate processing directories that don't match _raw content
%
% Input:
%   base_input - Base directory path (e.g., 'C:\Coding\BGWRP\data\_BATCH\')

console_log('Archiving non-underscore directories to _raw and purging unmatched intermediate processing...\n');

%% STEP 1: Archive non-underscore directories to _raw
console_log('\n--- STEP 1: ARCHIVING TO _RAW ---\n');

% Ensure _raw directory exists
raw_dir = fullfile(base_input, '_raw');
if ~exist(raw_dir, 'dir')
    mkdir(raw_dir);
    console_log('Created _raw directory: %s\n', raw_dir);
end

% Find non-underscore directories in base_input
base_items = dir(base_input);
non_underscore_dirs = {};
for i = 1:length(base_items)
    if base_items(i).isdir && ~startsWith(base_items(i).name, '.') && ~startsWith(base_items(i).name, '_')
        non_underscore_dirs{end+1} = base_items(i).name;
    end
end

console_log('Found %d non-underscore directories to archive\n', length(non_underscore_dirs));

archived_count = 0;
for i = 1:length(non_underscore_dirs)
    dir_name = non_underscore_dirs{i};
    source_path = fullfile(base_input, dir_name);
    target_path = fullfile(raw_dir, dir_name);
    
    if exist(target_path, 'dir')
        console_log('  ⚠ %s already exists in _raw - skipping\n', dir_name);
    else
        try
            movefile(source_path, target_path);
            console_log('  ✓ Archived %s to _raw\n', dir_name);
            archived_count = archived_count + 1;
        catch ME
            console_log('  ✗ Failed to archive %s: %s\n', dir_name, ME.message);
        end
    end
end

console_log('Archived %d directories to _raw\n', archived_count);

%% STEP 2: Get reference list from _raw
console_log('\n--- STEP 2: GETTING _RAW REFERENCE ---\n');

if ~exist(raw_dir, 'dir')
    console_log('⚠ No _raw directory found after archiving\n');
    return;
end

% Find raw datasets
raw_items = dir(raw_dir);
raw_datasets = {};
for i = 1:length(raw_items)
    if raw_items(i).isdir && ~startsWith(raw_items(i).name, '.')
        raw_datasets{end+1} = raw_items(i).name;
    end
end

if isempty(raw_datasets)
    console_log('⚠ No raw datasets found in %s\n', raw_dir);
    console_log('Nothing to purge against.\n');
    return;
end

console_log('Raw datasets to preserve: %s\n', strjoin(raw_datasets, ', '));

%% STEP 3: Purge intermediate directories that don't match _raw
console_log('\n--- STEP 3: PURGING UNMATCHED INTERMEDIATE ---\n');

% Directories to clean up (all intermediate processing)
intermediate_dirs = {
    '_tdms_to_mat',
    '_concatenated', 
    '_combined_head',
    '_configs',
    '_active'  % Also clean _active if datasets no longer in _raw
};

total_removed = 0;
total_preserved = 0;

for i = 1:length(intermediate_dirs)
    dir_name = intermediate_dirs{i};
    target_dir = fullfile(base_input, dir_name);
    
    if ~exist(target_dir, 'dir')
        console_log('Skipping %s (does not exist)\n', dir_name);
        continue;
    end
    
    console_log('\n--- Cleaning %s ---\n', dir_name);
    
    % Get items in this directory
    items = dir(target_dir);
    datasets_in_dir = {};
    for j = 1:length(items)
        if items(j).isdir && ~startsWith(items(j).name, '.')
            datasets_in_dir{end+1} = items(j).name;
        end
    end
    
    % Also check for individual config files (in _configs)
    if strcmp(dir_name, '_configs')
        config_files = dir(fullfile(target_dir, 'get_timing_*.m'));
        for j = 1:length(config_files)
            % Extract dataset name from config filename
            config_name = config_files(j).name;
            % Pattern: get_timing_<dataset_name>.m
            match = regexp(config_name, 'get_timing_(.+)\.m', 'tokens');
            if ~isempty(match)
                dataset_from_config = match{1}{1};
                if ~ismember(dataset_from_config, datasets_in_dir)
                    datasets_in_dir{end+1} = dataset_from_config;
                end
            end
        end
    end
    
    if isempty(datasets_in_dir)
        console_log('  No datasets found in %s\n', dir_name);
        continue;
    end
    
    % Check each dataset against _raw
    for j = 1:length(datasets_in_dir)
        dataset_name = datasets_in_dir{j};
        
        if ismember(dataset_name, raw_datasets)
            console_log('  ✓ Preserving %s (exists in _raw)\n', dataset_name);
            total_preserved = total_preserved + 1;
        else
            console_log('  ✗ Removing %s (not in _raw)\n', dataset_name);
            
            % Remove dataset directory
            dataset_path = fullfile(target_dir, dataset_name);
            if exist(dataset_path, 'dir')
                try
                    rmdir(dataset_path, 's');
                    console_log('    Removed directory: %s\n', dataset_path);
                    total_removed = total_removed + 1;
                catch ME
                    console_log('    ⚠ Failed to remove %s: %s\n', dataset_path, ME.message);
                end
            end
            
            % For _configs, also remove individual config files
            if strcmp(dir_name, '_configs')
                config_pattern = sprintf('get_timing_%s.m', dataset_name);
                config_file = fullfile(target_dir, config_pattern);
                if exist(config_file, 'file')
                    try
                        delete(config_file);
                        console_log('    Removed config file: %s\n', config_file);
                    catch ME
                        console_log('    ⚠ Failed to remove %s: %s\n', config_file, ME.message);
                    end
                end
                
                % Also check for legacy .mat and .txt files
                legacy_patterns = {sprintf('timing_%s.mat', dataset_name), sprintf('timing_%s.txt', dataset_name)};
                for k = 1:length(legacy_patterns)
                    legacy_file = fullfile(target_dir, legacy_patterns{k});
                    if exist(legacy_file, 'file')
                        try
                            delete(legacy_file);
                            console_log('    Removed legacy file: %s\n', legacy_file);
                        catch ME
                            console_log('    ⚠ Failed to remove %s: %s\n', legacy_file, ME.message);
                        end
                    end
                end
            end
        end
    end
end

console_log('\n=== PURGE SUMMARY ===\n');
console_log('Directories archived to _raw: %d\n', archived_count);
console_log('Datasets preserved in intermediate: %d\n', total_preserved);
console_log('Datasets removed from intermediate: %d\n', total_removed);
console_log('Raw datasets: %s\n', strjoin(raw_datasets, ', '));

end
