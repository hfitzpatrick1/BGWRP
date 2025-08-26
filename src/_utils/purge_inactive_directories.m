function purge_inactive_directories(base_input)
%PURGE_INACTIVE_DIRECTORIES Clean up intermediate processing directories that don't match _active content
%
% Removes datasets from intermediate directories (_tdms_to_mat, _concatenated, _combined_head, _configs)
% if they don't have corresponding datasets in _active directory
%
% Input:
%   base_input - Base directory path (e.g., 'C:\Coding\BGWRP\data\_BATCH\')

fprintf('Purging intermediate directories that do not match _active content...\n');

% Get list of active datasets
active_dir = fullfile(base_input, '_active');
if ~exist(active_dir, 'dir')
    fprintf('⚠ No _active directory found: %s\n', active_dir);
    fprintf('Nothing to purge against.\n');
    return;
end

% Find active datasets
active_items = dir(active_dir);
active_datasets = {};
for i = 1:length(active_items)
    if active_items(i).isdir && ~startsWith(active_items(i).name, '.')
        active_datasets{end+1} = active_items(i).name;
    end
end

if isempty(active_datasets)
    fprintf('⚠ No active datasets found in %s\n', active_dir);
    fprintf('Nothing to purge against.\n');
    return;
end

fprintf('Active datasets to preserve: %s\n', strjoin(active_datasets, ', '));

% Directories to clean up
intermediate_dirs = {
    '_tdms_to_mat',
    '_concatenated', 
    '_combined_head',
    '_configs'
};

total_removed = 0;
total_preserved = 0;

for i = 1:length(intermediate_dirs)
    dir_name = intermediate_dirs{i};
    target_dir = fullfile(base_input, dir_name);
    
    if ~exist(target_dir, 'dir')
        fprintf('Skipping %s (does not exist)\n', dir_name);
        continue;
    end
    
    fprintf('\n--- Cleaning %s ---\n', dir_name);
    
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
        fprintf('  No datasets found in %s\n', dir_name);
        continue;
    end
    
    % Check each dataset
    for j = 1:length(datasets_in_dir)
        dataset_name = datasets_in_dir{j};
        
        if ismember(dataset_name, active_datasets)
            fprintf('  ✓ Preserving %s (active)\n', dataset_name);
            total_preserved = total_preserved + 1;
        else
            fprintf('  ✗ Removing %s (inactive)\n', dataset_name);
            
            % Remove dataset directory
            dataset_path = fullfile(target_dir, dataset_name);
            if exist(dataset_path, 'dir')
                try
                    rmdir(dataset_path, 's');
                    fprintf('    Removed directory: %s\n', dataset_path);
                    total_removed = total_removed + 1;
                catch ME
                    fprintf('    ⚠ Failed to remove %s: %s\n', dataset_path, ME.message);
                end
            end
            
            % For _configs, also remove individual config files
            if strcmp(dir_name, '_configs')
                config_pattern = sprintf('get_timing_%s.m', dataset_name);
                config_file = fullfile(target_dir, config_pattern);
                if exist(config_file, 'file')
                    try
                        delete(config_file);
                        fprintf('    Removed config file: %s\n', config_file);
                    catch ME
                        fprintf('    ⚠ Failed to remove %s: %s\n', config_file, ME.message);
                    end
                end
                
                % Also check for legacy .mat and .txt files
                legacy_patterns = {sprintf('timing_%s.mat', dataset_name), sprintf('timing_%s.txt', dataset_name)};
                for k = 1:length(legacy_patterns)
                    legacy_file = fullfile(target_dir, legacy_patterns{k});
                    if exist(legacy_file, 'file')
                        try
                            delete(legacy_file);
                            fprintf('    Removed legacy file: %s\n', legacy_file);
                        catch ME
                            fprintf('    ⚠ Failed to remove %s: %s\n', legacy_file, ME.message);
                        end
                    end
                end
            end
        end
    end
end

fprintf('\n=== PURGE SUMMARY ===\n');
fprintf('Datasets preserved: %d\n', total_preserved);
fprintf('Datasets removed: %d\n', total_removed);
fprintf('Active datasets: %s\n', strjoin(active_datasets, ', '));

end
