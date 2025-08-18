function workspace_info = organize_workspace(base_path)
%ORGANIZE_WORKSPACE Intelligent workspace organization for batch processing
%
% Scans root directory for data folders and organizes them into processing subdirectories
% Creates _tdms_to_mat, _concatenated, _active subdirectories
%
% Input:
%   base_path - Root directory path
%
% Output:
%   workspace_info - Structure with organization results

fprintf('=== ORGANIZING WORKSPACE ===\n');
fprintf('Base path: %s\n', base_path);

workspace_info = struct();
workspace_info.base_path = base_path;
workspace_info.input_folders = {};
workspace_info.processing_dirs = struct();

%% Find input folders with TDMS or MAT files
fprintf('\nScanning for input folders...\n');

if ~exist(base_path, 'dir')
    error('Base path does not exist: %s', base_path);
end

% Get all subdirectories in base path (excluding those starting with _)
all_items = dir(base_path);
input_folders = {};

for i = 1:length(all_items)
    item = all_items(i);
    if item.isdir && ~startsWith(item.name, '.') && ~startsWith(item.name, '_')
        folder_path = fullfile(base_path, item.name);
        
        % Check for TDMS files
        tdms_files = dir(fullfile(folder_path, '*.tdms'));
        mat_files = dir(fullfile(folder_path, '*.mat'));
        
        if ~isempty(tdms_files) || ~isempty(mat_files)
            input_folders{end+1} = item.name;
            fprintf('  Found input folder: %s (%d TDMS, %d MAT files)\n', ...
                item.name, length(tdms_files), length(mat_files));
        end
    end
end

workspace_info.input_folders = input_folders;

if isempty(input_folders)
    fprintf('  ⚠ No input folders with TDMS/MAT files found\n');
    return;
end

%% Create processing directories
fprintf('\nCreating processing directories...\n');

processing_dirs = {'_tdms_to_mat', '_concatenated', '_active'};

for i = 1:length(processing_dirs)
    dir_name = processing_dirs{i};
    dir_path = fullfile(base_path, dir_name);
    
    if exist(dir_path, 'dir')
        fprintf('  Cleaning existing directory: %s\n', dir_name);
        rmdir(dir_path, 's');
    end
    
    mkdir(dir_path);
    fprintf('  ✓ Created: %s\n', dir_name);
    
    workspace_info.processing_dirs.(dir_name(2:end)) = dir_path; % Remove _ prefix for field name
end

%% Create subdirectories for each input folder
fprintf('\nCreating subdirectories for input folders...\n');

for i = 1:length(input_folders)
    folder_name = input_folders{i};
    
    % Create subdirectories in processing folders
    for j = 1:length(processing_dirs)
        subdir_path = fullfile(base_path, processing_dirs{j}, folder_name);
        mkdir(subdir_path);
        fprintf('  Created: %s/%s\n', processing_dirs{j}, folder_name);
    end
end

%% Report input files (no copying needed)
fprintf('\nInput files detected:\n');

for i = 1:length(input_folders)
    folder_name = input_folders{i};
    source_path = fullfile(base_path, folder_name);
    
    % Report TDMS files
    tdms_files = dir(fullfile(source_path, '*.tdms'));
    if ~isempty(tdms_files)
        fprintf('  %s: %d TDMS files (will be converted to _tdms_to_mat/%s)\n', ...
            folder_name, length(tdms_files), folder_name);
    end
    
    % Report MAT files
    mat_files = dir(fullfile(source_path, '*.mat'));
    if ~isempty(mat_files)
        if isempty(tdms_files)
            fprintf('  %s: %d MAT files (will be processed from source)\n', ...
                folder_name, length(mat_files));
        else
            fprintf('  %s: %d MAT files (already converted, will use if needed)\n', ...
                folder_name, length(mat_files));
        end
    end
end

workspace_info.status = 'organized';
fprintf('\n✓ Workspace organization complete\n');
fprintf('Input folders: %d\n', length(input_folders));
fprintf('Processing directories created: %d\n', length(processing_dirs));

end
