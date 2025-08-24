function dataset_info = discover_datasets(base_input, discovery_mode, options)
%DISCOVER_DATASETS Universal dataset discovery for all BGWRP modules
%
% Scans directory for data folders and returns standardized info
% Used by ALL modules (prep, analysis, diagnostic) for consistent behavior
%
% Inputs:
%   base_input     - Root directory path  
%   discovery_mode - 'raw' (scan base_input for TDMS/MAT), 'active' (scan _active subdir)
%   options        - Discovery options (optional)
%     .verbose     - Print discovery details (default: true)
%     .require_files - Require files to exist (default: true)
%
% Outputs:
%   dataset_info - Structure with discovered datasets
%     .base_path   - Base directory used for discovery
%     .mode        - Discovery mode used
%     .datasets    - Cell array of discovered dataset names
%     .paths       - Full paths to each dataset directory
%     .types       - Type of data in each dataset ('tdms', 'mat', 'both', 'empty')
%     .file_counts - Number of files in each dataset

if nargin < 2
    discovery_mode = 'raw';  % Default to raw data discovery
end

if nargin < 3
    options = struct();
end

% Default options
if ~isfield(options, 'verbose'), options.verbose = true; end
if ~isfield(options, 'require_files'), options.require_files = true; end

% Initialize output structure
dataset_info = struct();
dataset_info.base_path = base_input;
dataset_info.mode = discovery_mode;
dataset_info.datasets = {};
dataset_info.paths = {};
dataset_info.types = {};
dataset_info.file_counts = [];

if options.verbose
    fprintf('=== DATASET DISCOVERY ===\n');
    fprintf('Base path: %s\n', base_input);
    fprintf('Discovery mode: %s\n', discovery_mode);
end

% Validate base path
if ~exist(base_input, 'dir')
    error('DISCOVERY ERROR: Base directory does not exist: %s', base_input);
end

% Determine scan directory based on mode
switch lower(discovery_mode)
    case 'raw'
        scan_directory = base_input;
        if options.verbose
            fprintf('Scanning for raw data (TDMS/MAT files in subdirectories)\n');
        end
        
    case 'active'
        scan_directory = fullfile(base_input, '_active');
        if ~exist(scan_directory, 'dir')
            error('DISCOVERY ERROR: Active directory does not exist: %s\nRun prep mode first to create processed datasets', scan_directory);
        end
        if options.verbose
            fprintf('Scanning _active directory for processed datasets\n');
        end
        
    otherwise
        error('DISCOVERY ERROR: Unknown discovery mode: %s. Valid modes: ''raw'', ''active''', discovery_mode);
end

%% Scan for dataset directories
if options.verbose
    fprintf('\nScanning directory: %s\n', scan_directory);
end

% Get all subdirectories (excluding those starting with . or _)
all_items = dir(scan_directory);
discovered_datasets = {};
discovered_paths = {};
discovered_types = {};
discovered_counts = [];

for i = 1:length(all_items)
    item = all_items(i);
    if item.isdir && ~startsWith(item.name, '.') && ~startsWith(item.name, '_')
        dataset_path = fullfile(scan_directory, item.name);
        
        % Count files by type
        tdms_files = dir(fullfile(dataset_path, '*.tdms'));
        mat_files = dir(fullfile(dataset_path, '*.mat'));
        
        % Determine dataset type
        if ~isempty(tdms_files) && ~isempty(mat_files)
            dataset_type = 'both';
        elseif ~isempty(tdms_files)
            dataset_type = 'tdms';
        elseif ~isempty(mat_files)
            dataset_type = 'mat';
        else
            dataset_type = 'empty';
        end
        
        % Include dataset if it has files or if we don't require files
        total_files = length(tdms_files) + length(mat_files);
        if total_files > 0 || ~options.require_files
            discovered_datasets{end+1} = item.name;
            discovered_paths{end+1} = dataset_path;
            discovered_types{end+1} = dataset_type;
            discovered_counts(end+1) = total_files;
            
            if options.verbose
                if strcmp(dataset_type, 'both')
                    fprintf('  ✓ Found dataset: %s (%d TDMS, %d MAT files)\n', ...
                        item.name, length(tdms_files), length(mat_files));
                elseif strcmp(dataset_type, 'tdms')
                    fprintf('  ✓ Found dataset: %s (%d TDMS files)\n', ...
                        item.name, length(tdms_files));
                elseif strcmp(dataset_type, 'mat')
                    fprintf('  ✓ Found dataset: %s (%d MAT files)\n', ...
                        item.name, length(mat_files));
                else
                    fprintf('  ⚠ Found empty dataset: %s (no data files)\n', item.name);
                end
            end
        end
    end
end

%% Validate results
if isempty(discovered_datasets)
    error_msg = sprintf('DISCOVERY ERROR: No datasets found in %s\n', scan_directory);
    if strcmp(discovery_mode, 'raw')
        error_msg = [error_msg 'Expected: Subdirectories containing TDMS or MAT files\n'];
        error_msg = [error_msg 'Check that your data directories exist and contain files'];
    else  % active mode
        error_msg = [error_msg 'Expected: Processed datasets in _active subdirectory\n'];
        error_msg = [error_msg 'Run prep mode first to create processed datasets'];
    end
    error('%s', error_msg);
end

%% Populate output structure
dataset_info.datasets = discovered_datasets;
dataset_info.paths = discovered_paths;
dataset_info.types = discovered_types;
dataset_info.file_counts = discovered_counts;

if options.verbose
    fprintf('\n✓ Discovery complete: Found %d datasets\n', length(discovered_datasets));
    fprintf('Dataset names: %s\n', strjoin(discovered_datasets, ', '));
end

end
