function workspace_info = organize_workspace(base_path, cleanup_dirs, selective_mode)
%ORGANIZE_WORKSPACE Intelligent workspace organization for batch processing
%
% Scans root directory for data folders and organizes them into processing subdirectories
% Creates _tdms_to_mat, _concatenated, _active subdirectories
%
% Input:
%   base_path     - Root directory path
%   cleanup_dirs  - Whether to clean existing directories (default: false)
%   selective_mode - 'selective' (default), 'purge', or 'legacy'
%
% Output:
%   workspace_info - Structure with organization results

fprintf('=== ORGANIZING WORKSPACE ===\n');
fprintf('Base path: %s\n', base_path);

if nargin < 2
    cleanup_dirs = false;  % Default: don't cleanup existing directories
end

if nargin < 3
    selective_mode = 'selective';  % Default: selective processing
end

workspace_info = struct();
workspace_info.base_path = base_path;
workspace_info.input_folders = {};
workspace_info.processing_dirs = struct();

%% Find input folders with TDMS or MAT files
fprintf('\nScanning for input folders (mode: %s)...\n', selective_mode);

if ~exist(base_path, 'dir')
    error('Base path does not exist: %s', base_path);
end

% Create _raw directory if it doesn't exist (for archiving)
raw_dir = fullfile(base_path, '_raw');
if ~exist(raw_dir, 'dir')
    mkdir(raw_dir);
    fprintf('  Created _raw directory for archiving\n');
end

% Get all subdirectories in base path (excluding those starting with _)
all_items = dir(base_path);
input_folders = {};

for i = 1:length(all_items)
    item = all_items(i);
    if item.isdir && ~startsWith(item.name, '.') && ~startsWith(item.name, '_')
        folder_path = fullfile(base_path, item.name);
        
        % Check for new structure: _das and _head subdirectories
        das_dir = fullfile(folder_path, '_das');
        head_dir = fullfile(folder_path, '_head');
        
        tdms_files = [];
        mat_files = [];
        
        % Check _das subdirectory for TDMS files
        if exist(das_dir, 'dir')
            tdms_files = dir(fullfile(das_dir, '*.tdms'));
        end
        
        % Check _head subdirectory for MAT files
        if exist(head_dir, 'dir')
            mat_files = dir(fullfile(head_dir, '*.mat'));
        end
        
        if ~isempty(tdms_files) || ~isempty(mat_files)
            input_folders{end+1} = item.name;
            fprintf('  Found input folder: %s (%d TDMS in _das, %d MAT in _head)\n', ...
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

processing_dirs = {'_tdms_to_mat', '_combined_head', '_concatenated', '_active'};

for i = 1:length(processing_dirs)
    dir_name = processing_dirs{i};
    dir_path = fullfile(base_path, dir_name);
    
    if exist(dir_path, 'dir')
        if cleanup_dirs
            if strcmp(selective_mode, 'selective')
                % Selective mode: only clean subdirectories matching current input folders
                fprintf('  Selective cleaning in: %s\n', dir_name);
                for j = 1:length(input_folders)
                    subfolder_path = fullfile(dir_path, input_folders{j});
                    if exist(subfolder_path, 'dir')
                        fprintf('    Cleaning %s/%s\n', dir_name, input_folders{j});
                        rmdir(subfolder_path, 's');
                    end
                end
            else
                % Purge mode: clean entire directory (legacy behavior)
                fprintf('  Purge cleaning directory: %s\n', dir_name);
                rmdir(dir_path, 's');
                mkdir(dir_path);
            end
            fprintf('  ✓ Cleaned: %s\n', dir_name);
        else
            fprintf('  ✓ Using existing: %s\n', dir_name);
        end
    else
        mkdir(dir_path);
        fprintf('  ✓ Created: %s\n', dir_name);
    end
    
    workspace_info.processing_dirs.(dir_name(2:end)) = dir_path; % Remove _ prefix for field name
end

%% Create subdirectories for each input folder
fprintf('\nCreating subdirectories for input folders...\n');

for i = 1:length(input_folders)
    folder_name = input_folders{i};
    
    % Create subdirectories in processing folders
    for j = 1:length(processing_dirs)
        subdir_path = fullfile(base_path, processing_dirs{j}, folder_name);
        if ~exist(subdir_path, 'dir')
            mkdir(subdir_path);
            fprintf('  Created: %s/%s\n', processing_dirs{j}, folder_name);
        else
            fprintf('  ✓ Using existing: %s/%s\n', processing_dirs{j}, folder_name);
        end
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

%% Archive processed directories (selective mode only)
if strcmp(selective_mode, 'selective')
    workspace_info.archive_function = @() archive_processed_directories(base_path, input_folders);
    fprintf('\nNote: After processing, use archive_processed_directories() to move source dirs to _raw\n');
else
    workspace_info.archive_function = [];
end

workspace_info.status = 'organized';
workspace_info.selective_mode = selective_mode;
fprintf('\n✓ Workspace organization complete\n');
fprintf('Input folders: %d\n', length(input_folders));
fprintf('Processing directories created: %d\n', length(processing_dirs));

end

function archive_processed_directories(base_path, processed_folders)
%ARCHIVE_PROCESSED_DIRECTORIES Move processed source directories to _raw
fprintf('\n=== ARCHIVING PROCESSED DIRECTORIES ===\n');

raw_dir = fullfile(base_path, '_raw');
for i = 1:length(processed_folders)
    folder_name = processed_folders{i};
    source_path = fullfile(base_path, folder_name);
    archive_path = fullfile(raw_dir, folder_name);
    
    if exist(source_path, 'dir')
        if exist(archive_path, 'dir')
            fprintf('  Replacing existing archive: %s\n', folder_name);
            rmdir(archive_path, 's');
        end
        
        fprintf('  Archiving: %s -> _raw/%s\n', folder_name, folder_name);
        movefile(source_path, archive_path);
        fprintf('  ✓ Archived: %s\n', folder_name);
    else
        fprintf('  ⚠ Source already moved: %s\n', folder_name);
    end
end

fprintf('✓ Archive complete\n');
end
