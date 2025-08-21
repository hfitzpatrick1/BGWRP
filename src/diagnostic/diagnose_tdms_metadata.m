function diagnose_tdms_metadata(dataset_name, tdms_directory, options)
%DIAGNOSE_TDMS_METADATA Extract and compare TDMS file metadata to identify amplitude variation sources
%
% Analyzes metadata from multiple TDMS files to understand per-file variations
% that could cause the vertical striping artifacts during concatenation
%
% Inputs:
%   dataset_name     - Name of dataset being analyzed
%   tdms_directory   - Directory containing TDMS files
%   options          - Analysis options structure
%
% This diagnostic helps identify why fixed scaling (adc_scalar=1/8192, data=116*data)
% creates 66.5% RMS variation between file segments

if nargin < 3
    options = struct();
end

% Default options
if ~isfield(options, 'max_files'), options.max_files = 20; end
if ~isfield(options, 'sample_interval'), options.sample_interval = 5; end % Analyze every 5th file
if ~isfield(options, 'use_builtin'), options.use_builtin = true; end % Try MATLAB R2022a+ functions first

fprintf('=== TDMS METADATA DIAGNOSTIC: %s ===\n', dataset_name);
fprintf('Directory: %s\n', tdms_directory);

% Verify directory exists
if ~exist(tdms_directory, 'dir')
    error('TDMS directory does not exist: %s', tdms_directory);
end

% Find TDMS files
files = dir(fullfile(tdms_directory, '*.tdms'));
if isempty(files)
    error('No TDMS files found in directory: %s', tdms_directory);
end

fprintf('Found %d TDMS files\n', length(files));

% Select files to analyze (sample subset to avoid overwhelming analysis)
if length(files) > options.max_files
    file_indices = 1:options.sample_interval:length(files);
    file_indices = file_indices(1:min(options.max_files, length(file_indices)));
    fprintf('Analyzing %d files (every %d files)\n', length(file_indices), options.sample_interval);
else
    file_indices = 1:length(files);
    fprintf('Analyzing all %d files\n', length(file_indices));
end

%% Stage 1: Extract metadata using available methods
fprintf('\n--- STAGE 1: METADATA EXTRACTION ---\n');

metadata_table = [];
extraction_method = 'unknown';

% Try MATLAB built-in functions first (R2022a+)
if options.use_builtin
    try
        fprintf('Testing MATLAB built-in TDMS functions...\n');
        test_file = fullfile(tdms_directory, files(1).name);
        
        % Test tdmsinfo
        info = tdmsinfo(test_file);
        fprintf('✓ tdmsinfo available - using built-in functions\n');
        extraction_method = 'builtin';
        
        % Extract metadata using built-in functions
        metadata_table = extract_metadata_builtin(files, file_indices, tdms_directory);
        
    catch ME
        fprintf('✗ Built-in functions not available: %s\n', ME.message);
        fprintf('  Falling back to Silixa TDMS_Adv_Read...\n');
        extraction_method = 'silixa';
    end
end

% Fallback to Silixa TDMS_Adv_Read
if strcmp(extraction_method, 'silixa') || strcmp(extraction_method, 'unknown')
    try
        fprintf('Using Silixa TDMS_Adv_Read for metadata extraction...\n');
        metadata_table = extract_metadata_silixa(files, file_indices, tdms_directory);
        extraction_method = 'silixa';
        fprintf('✓ Silixa extraction successful\n');
    catch ME
        error('Both extraction methods failed. Last error: %s', ME.message);
    end
end

%% Stage 2: Analyze metadata variations
fprintf('\n--- STAGE 2: METADATA ANALYSIS ---\n');

if isempty(metadata_table)
    error('No metadata extracted');
end

fprintf('Extracted metadata from %d files\n', height(metadata_table));

% Display metadata table overview
fprintf('\nMetadata fields found:\n');
field_names = metadata_table.Properties.VariableNames;
for i = 1:length(field_names)
    fprintf('  %d. %s\n', i, field_names{i});
end

% Analyze key parameters that could affect amplitude scaling
analyze_amplitude_parameters(metadata_table);

%% Stage 3: Identify scaling inconsistencies
fprintf('\n--- STAGE 3: SCALING ANALYSIS ---\n');

% Check for parameters that should inform adaptive scaling
identify_scaling_parameters(metadata_table);

%% Stage 4: Recommendations
fprintf('\n--- STAGE 4: RECOMMENDATIONS ---\n');

generate_scaling_recommendations(metadata_table, extraction_method);

% Save diagnostic results
save_diagnostic_results(dataset_name, metadata_table, tdms_directory);

fprintf('\n=== TDMS METADATA DIAGNOSTIC COMPLETE ===\n');

end

%% Helper Functions

function metadata_table = extract_metadata_builtin(files, file_indices, tdms_directory)
%Extract metadata using MATLAB built-in functions (R2022a+)

metadata_cell = {};

for i = 1:length(file_indices)
    file_idx = file_indices(i);
    filename = files(file_idx).name;
    filepath = fullfile(tdms_directory, filename);
    
    fprintf('  Processing file %d of %d: %s\n', i, length(file_indices), filename);
    
    try
        % Get general info
        info = tdmsinfo(filepath);
        
        % Get detailed properties
        props = tdmsreadprop(filepath);
        
        % Extract key metadata
        file_metadata = struct();
        file_metadata.filename = filename;
        file_metadata.file_index = file_idx;
        
        % From tdmsinfo
        if isfield(info, 'Title'), file_metadata.title = info.Title; end
        if isfield(info, 'Author'), file_metadata.author = info.Author; end
        if isfield(info, 'Version'), file_metadata.version = info.Version; end
        if isfield(info, 'ChannelList'), file_metadata.num_channels = length(info.ChannelList); end
        
        % From tdmsreadprop - look for critical parameters
        if istable(props)
            % Look for sampling frequency
            fs_rows = contains(props.name, 'SamplingFrequency', 'IgnoreCase', true);
            if any(fs_rows)
                file_metadata.sampling_frequency = props.value(find(fs_rows, 1));
            end
            
            % Look for spatial resolution
            spatial_rows = contains(props.name, 'SpatialResolution', 'IgnoreCase', true);
            if any(spatial_rows)
                file_metadata.spatial_resolution = props.value(find(spatial_rows, 1));
            end
            
            % Look for gauge length
            gauge_rows = contains(props.name, 'GaugeLength', 'IgnoreCase', true);
            if any(gauge_rows)
                file_metadata.gauge_length = props.value(find(gauge_rows, 1));
            end
            
            % Look for calibration or scaling parameters
            calib_rows = contains(props.name, {'Calibration', 'Scale', 'Gain', 'Offset'}, 'IgnoreCase', true);
            if any(calib_rows)
                calib_props = props(calib_rows, :);
                for j = 1:height(calib_props)
                    param_name = matlab.lang.makeValidName(calib_props.name{j});
                    file_metadata.(param_name) = calib_props.value(j);
                end
            end
        end
        
        metadata_cell{i} = file_metadata;
        
    catch ME
        fprintf('    ✗ Error processing %s: %s\n', filename, ME.message);
        % Create empty entry to maintain indexing
        file_metadata = struct();
        file_metadata.filename = filename;
        file_metadata.file_index = file_idx;
        file_metadata.error = ME.message;
        metadata_cell{i} = file_metadata;
    end
end

% Convert to table
metadata_table = struct2table(vertcat(metadata_cell{:}));

end

function metadata_table = extract_metadata_silixa(files, file_indices, tdms_directory)
%Extract metadata using Silixa TDMS_Adv_Read function

metadata_cell = {};

for i = 1:length(file_indices)
    file_idx = file_indices(i);
    filename = files(file_idx).name;
    filepath = fullfile(tdms_directory, filename);
    
    fprintf('  Processing file %d of %d: %s\n', i, length(file_indices), filename);
    
    try
        % Use TDMS_Adv_Read to extract properties only
        [~, fileinfo] = TDMS_Adv_Read(filepath);
        
        % Extract key metadata
        file_metadata = struct();
        file_metadata.filename = filename;
        file_metadata.file_index = file_idx;
        file_metadata.num_channels = fileinfo.n_ch;
        file_metadata.channel_length = fileinfo.ChannelLength;
        file_metadata.data_type = fileinfo.DataType;
        file_metadata.chunk_size = fileinfo.ChunkSize;
        file_metadata.decimated = fileinfo.decimated;
        
        % Extract properties from Properties cell array
        if isfield(fileinfo, 'Properties') && ~isempty(fileinfo.Properties)
            props = fileinfo.Properties;
            for j = 1:size(props, 1)
                prop_name = props{j, 1};
                prop_value = props{j, 2};
                
                % Convert property name to valid field name
                field_name = matlab.lang.makeValidName(prop_name);
                file_metadata.(field_name) = prop_value;
            end
        end
        
        metadata_cell{i} = file_metadata;
        
    catch ME
        fprintf('    ✗ Error processing %s: %s\n', filename, ME.message);
        % Create empty entry to maintain indexing
        file_metadata = struct();
        file_metadata.filename = filename;
        file_metadata.file_index = file_idx;
        file_metadata.error = ME.message;
        metadata_cell{i} = file_metadata;
    end
end

% Convert to table
metadata_table = struct2table(vertcat(metadata_cell{:}));

end

function analyze_amplitude_parameters(metadata_table)
%Analyze parameters that could affect amplitude scaling

fprintf('Analyzing amplitude-related parameters...\n');

% Check for variation in key numeric parameters
numeric_fields = {};
for i = 1:width(metadata_table)
    field_name = metadata_table.Properties.VariableNames{i};
    if isnumeric(metadata_table{:, i}) && ~all(isnan(metadata_table{:, i}))
        numeric_fields{end+1} = field_name;
    end
end

fprintf('Found %d numeric metadata fields:\n', length(numeric_fields));

for i = 1:length(numeric_fields)
    field_name = numeric_fields{i};
    values = metadata_table{:, field_name};
    
    % Remove NaN values
    valid_values = values(~isnan(values));
    
    if length(valid_values) > 1
        variation_pct = (std(valid_values) / mean(valid_values)) * 100;
        fprintf('  %s: mean=%.6f, std=%.6f, variation=%.2f%%\n', ...
            field_name, mean(valid_values), std(valid_values), variation_pct);
        
        if variation_pct > 1  % More than 1% variation
            fprintf('    → HIGH VARIATION detected in %s\n', field_name);
        end
    else
        fprintf('  %s: constant value=%.6f\n', field_name, valid_values(1));
    end
end

end

function identify_scaling_parameters(metadata_table)
%Identify parameters that should inform adaptive scaling

fprintf('Identifying scaling-relevant parameters...\n');

% Look for fields that might contain scaling information
scaling_keywords = {'sampling', 'frequency', 'spatial', 'resolution', 'gauge', 'length', ...
                   'calibration', 'scale', 'gain', 'offset', 'adc', 'conversion'};

field_names = metadata_table.Properties.VariableNames;
scaling_fields = {};

for i = 1:length(field_names)
    field_name = lower(field_names{i});
    for j = 1:length(scaling_keywords)
        if contains(field_name, scaling_keywords{j})
            scaling_fields{end+1} = field_names{i};
            break;
        end
    end
end

if ~isempty(scaling_fields)
    fprintf('Found %d potential scaling parameters:\n', length(scaling_fields));
    for i = 1:length(scaling_fields)
        fprintf('  %s\n', scaling_fields{i});
    end
else
    fprintf('No obvious scaling parameters found in metadata\n');
end

end

function generate_scaling_recommendations(metadata_table, extraction_method)
%Generate recommendations for adaptive scaling

fprintf('Generating recommendations...\n');

% Check if we found varying parameters that could explain amplitude differences
recommendations = {};

% Look for high-variation numeric fields
high_variation_fields = {};

for i = 1:width(metadata_table)
    field_name = metadata_table.Properties.VariableNames{i};
    if isnumeric(metadata_table{:, i})
        values = metadata_table{:, i};
        valid_values = values(~isnan(values));
        
        if length(valid_values) > 1
            variation_pct = (std(valid_values) / mean(valid_values)) * 100;
            if variation_pct > 5  % More than 5% variation
                high_variation_fields{end+1} = field_name;
            end
        end
    end
end

if ~isempty(high_variation_fields)
    recommendations{end+1} = sprintf('FOUND %d parameters with >5%% variation: %s', ...
        length(high_variation_fields), strjoin(high_variation_fields, ', '));
    recommendations{end+1} = 'Consider implementing per-file scaling based on these parameters';
else
    recommendations{end+1} = 'No high-variation parameters found in metadata';
    recommendations{end+1} = 'Amplitude variations may be due to environmental factors not recorded in metadata';
end

% Always recommend replacing fixed scaling
recommendations{end+1} = 'CURRENT ISSUE: Fixed scaling (adc_scalar=1/8192, data=116*data) ignores per-file conditions';
recommendations{end+1} = 'RECOMMENDATION: Implement adaptive scaling based on file-specific metadata';

fprintf('\nRecommendations:\n');
for i = 1:length(recommendations)
    fprintf('  %d. %s\n', i, recommendations{i});
end

end

function save_diagnostic_results(dataset_name, metadata_table, tdms_directory)
%Save diagnostic results for further analysis

output_filename = sprintf('tdms_metadata_diagnostic_%s_%s.mat', ...
    dataset_name, datestr(now, 'yyyymmdd_HHMMSS'));

save(output_filename, 'metadata_table', 'tdms_directory', 'dataset_name');

fprintf('\nDiagnostic results saved to: %s\n', output_filename);

% Also save as CSV for easy viewing
csv_filename = strrep(output_filename, '.mat', '.csv');
try
    writetable(metadata_table, csv_filename);
    fprintf('Metadata table saved to: %s\n', csv_filename);
catch
    fprintf('Could not save CSV (table may contain mixed data types)\n');
end

end

