function organize_head_data(base_input)
%ORGANIZE_HEAD_DATA Copy appropriate head data files to active directories
%
% This function reads head data files from data/head directory and copies
% the appropriate ones to each active dataset directory based on timestamp
% matching, not filename patterns.
%
% Input:
%   base_input - Base input directory path
%
% The function:
% 1. Scans all head data files and reads their timestamps
% 2. Scans all active dataset directories  
% 3. Matches head files to datasets based on timestamp overlap
% 4. Copies matched head files to appropriate active directories
% 5. Renames them to generic "head_data_zX.mat" format

fprintf('=== ORGANIZING HEAD DATA FILES ===\n');

% Paths
head_source_dir = fullfile(fileparts(base_input), 'data', 'head');
active_base_dir = fullfile(base_input, '_active');

if ~exist(head_source_dir, 'dir')
    fprintf('⚠ Head data source directory not found: %s\n', head_source_dir);
    return;
end

if ~exist(active_base_dir, 'dir')
    fprintf('⚠ Active datasets directory not found: %s\n', active_base_dir);
    return;
end

%% Step 1: Read all head data files and their timestamps
fprintf('Step 1: Reading head data file timestamps...\n');
head_files = dir(fullfile(head_source_dir, '*.mat'));
head_info = struct();

for i = 1:length(head_files)
    filename = head_files(i).name;
    filepath = fullfile(head_source_dir, filename);
    
    try
        fprintf('  Reading: %s\n', filename);
        data = load(filepath);
        
        if isfield(data, 'Date') && ~isempty(data.Date)
            % Store timing info
            head_info(i).filename = filename;
            head_info(i).filepath = filepath;
            head_info(i).start_time = data.Date(1);
            head_info(i).end_time = data.Date(end);
            head_info(i).num_points = length(data.Date);
            
            % Extract zone info from filename for organizing
            zone_match = regexp(filename, '_(z\d+)\.mat', 'tokens');
            if ~isempty(zone_match)
                head_info(i).zone = zone_match{1}{1};
            else
                head_info(i).zone = 'unknown';
            end
            
            fprintf('    Timestamps: %s to %s (%d points, zone %s)\n', ...
                head_info(i).start_time, head_info(i).end_time, ...
                head_info(i).num_points, head_info(i).zone);
        else
            fprintf('    ⚠ No Date field found in %s\n', filename);
        end
        
    catch ME
        fprintf('    ✗ Error reading %s: %s\n', filename, ME.message);
    end
end

%% Step 2: Read all active dataset timing configs
fprintf('\nStep 2: Reading active dataset timing configs...\n');
dataset_dirs = dir(active_base_dir);
dataset_dirs = dataset_dirs([dataset_dirs.isdir] & ~startsWith({dataset_dirs.name}, '.'));

dataset_info = struct();
for i = 1:length(dataset_dirs)
    dataset_name = dataset_dirs(i).name;
    dataset_dir = fullfile(active_base_dir, dataset_name);
    
    % Look for timing config file
    timing_files = dir(fullfile(dataset_dir, 'get_timing_*.m'));
    if length(timing_files) == 1
        % Load timing config
        [~, func_name, ~] = fileparts(timing_files(1).name);
        addpath(dataset_dir);
        try
            timing_config = feval(func_name);
            dataset_info(i).name = dataset_name;
            dataset_info(i).dir = dataset_dir;
            dataset_info(i).start_time = timing_config.start;
            dataset_info(i).end_time = timing_config.end;
            
            fprintf('  Dataset: %s\n', dataset_name);
            fprintf('    Timing: %s to %s\n', timing_config.start, timing_config.end);
            
        catch ME
            fprintf('    ⚠ Error loading timing config for %s: %s\n', dataset_name, ME.message);
        end
        rmpath(dataset_dir);
    else
        fprintf('  ⚠ Dataset %s: Expected 1 timing config, found %d\n', dataset_name, length(timing_files));
    end
end

%% Step 3: Match head files to datasets based on timestamp overlap
fprintf('\nStep 3: Matching head files to datasets...\n');

for d = 1:length(dataset_info)
    if ~isfield(dataset_info(d), 'start_time')
        continue;
    end
    
    dataset = dataset_info(d);
    fprintf('  Processing dataset: %s\n', dataset.name);
    
    matched_files = {};
    for h = 1:length(head_info)
        if ~isfield(head_info(h), 'start_time')
            continue;
        end
        
        head = head_info(h);
        
        % Check for timestamp overlap
        % Dataset window: [dataset.start_time, dataset.end_time]
        % Head data window: [head.start_time, head.end_time]
        overlap = (head.start_time <= dataset.end_time) && (head.end_time >= dataset.start_time);
        
        if overlap
            fprintf('    ✓ Match: %s (zone %s) overlaps with dataset window\n', head.filename, head.zone);
            matched_files{end+1} = head;
        end
    end
    
    %% Step 4: Copy matched files to dataset directory
    if ~isempty(matched_files)
        fprintf('    Copying %d head files to %s...\n', length(matched_files), dataset.name);
        
        for m = 1:length(matched_files)
            head = matched_files{m};
            
            % Create standardized filename: head_data_z1.mat, head_data_z2.mat, etc.
            new_filename = sprintf('head_data_%s.mat', head.zone);
            dest_path = fullfile(dataset.dir, new_filename);
            
            try
                copyfile(head.filepath, dest_path);
                fprintf('      ✓ Copied %s -> %s\n', head.filename, new_filename);
            catch ME
                fprintf('      ✗ Failed to copy %s: %s\n', head.filename, ME.message);
            end
        end
    else
        fprintf('    ⚠ No head files matched dataset %s\n', dataset.name);
    end
end

fprintf('\n=== HEAD DATA ORGANIZATION COMPLETE ===\n');

end
