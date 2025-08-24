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

%% Stage 4: Data Quality Analysis
fprintf('\n--- STAGE 4: DATA QUALITY ANALYSIS ---\n');

analyze_data_quality_issues(metadata_table);

%% Stage 5: Recommendations  
fprintf('\n--- STAGE 5: RECOMMENDATIONS ---\n');

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
%Analyze parameters that vary between files (potential scaling sources)

fprintf('Analyzing metadata for variations between files...\n');

% Separate analysis for numeric and non-numeric fields
varying_fields = {};
constant_fields = {};

fprintf('\n=== FIELDS THAT VARY BETWEEN FILES ===\n');

for i = 1:width(metadata_table)
    field_name = metadata_table.Properties.VariableNames{i};
    values = metadata_table{:, i};
    
    % Skip filename and file_index (expected to vary)
    if strcmp(field_name, 'filename') || strcmp(field_name, 'file_index')
        continue;
    end
    
    has_variation = false;
    
    if isnumeric(values)
        % Numeric field analysis
        valid_values = values(~isnan(values));
        if length(valid_values) > 1
            if length(unique(valid_values)) > 1
                % Ensure values are double for calculations
                valid_values = double(valid_values);
                mean_val = mean(valid_values);
                if abs(mean_val) > eps  % Avoid division by zero
                    variation_pct = (std(valid_values) / abs(mean_val)) * 100;
                else
                    variation_pct = 0;
                end
                fprintf('  📊 %s: mean=%.6f, std=%.6f, variation=%.2f%%\n', ...
                    field_name, mean(valid_values), std(valid_values), variation_pct);
                
                % Show actual values if small number of files
                if length(valid_values) <= 10
                    fprintf('       Values: [%s]\n', num2str(valid_values', '%.6f '));
                end
                
                has_variation = true;
                varying_fields{end+1} = field_name;
            else
                constant_fields{end+1} = field_name;
            end
        end
    else
        % Non-numeric field analysis (strings, etc.)
        if iscell(values)
            unique_values = unique(values);
        else
            unique_values = unique(string(values));
        end
        
        if length(unique_values) > 1
            fprintf('  📝 %s: %d different values\n', field_name, length(unique_values));
            % Show actual values if reasonable number
            if length(unique_values) <= 5
                if iscell(values)
                    fprintf('       Values: %s\n', strjoin(unique_values, ', '));
                else
                    fprintf('       Values: %s\n', strjoin(string(unique_values), ', '));
                end
            end
            has_variation = true;
            varying_fields{end+1} = field_name;
        else
            constant_fields{end+1} = field_name;
        end
    end
end

fprintf('\n=== SUMMARY ===\n');
fprintf('Fields that VARY between files: %d\n', length(varying_fields));
if ~isempty(varying_fields)
    fprintf('  Variable fields: %s\n', strjoin(varying_fields, ', '));
end

fprintf('Fields that are CONSTANT: %d\n', length(constant_fields));
fprintf('  (Use -verbose flag to see constant fields)\n');

% Highlight critical scaling-related fields that vary
scaling_keywords = {'calibration', 'gain', 'scale', 'factor', 'unit', 'voltage', 'amplitude', 'offset'};
critical_varying_fields = {};

for i = 1:length(varying_fields)
    field_name_lower = lower(varying_fields{i});
    for j = 1:length(scaling_keywords)
        if contains(field_name_lower, scaling_keywords{j})
            critical_varying_fields{end+1} = varying_fields{i};
            break;
        end
    end
end

if ~isempty(critical_varying_fields)
    fprintf('\n⚠️  CRITICAL: Scaling-related fields that vary:\n');
    for i = 1:length(critical_varying_fields)
        fprintf('    → %s\n', critical_varying_fields{i});
    end
    fprintf('   These are likely candidates for fixing amplitude variations!\n');
end

end

function analyze_data_quality_issues(metadata_table)
%Analyze data quality and processing order implications

fprintf('Analyzing data quality and processing order issues...\n');

%% 1. Native Sampling Rate Analysis
fprintf('\n=== NATIVE SAMPLING RATE ANALYSIS ===\n');

% Extract sampling frequency information
if any(strcmp('SamplingFrequency_Hz_', metadata_table.Properties.VariableNames))
    fs_values = metadata_table.SamplingFrequency_Hz_;
    unique_fs = unique(fs_values);
    fprintf('Sampling Frequency: %.1f Hz', unique_fs(1));
    if length(unique_fs) > 1
        fprintf(' (VARIES: %s)', num2str(unique_fs'));
    end
    fprintf('\n');
else
    fprintf('⚠ No SamplingFrequency_Hz found in metadata\n');
    unique_fs = 100; % Assume based on typical values
end

% Check for decimation information in TDMS
if any(strcmp('decimated', metadata_table.Properties.VariableNames))
    decimated_values = metadata_table.decimated;
    if any(decimated_values)
        fprintf('⚠ TDMS files are already decimated (pre-processing occurred)\n');
        fprintf('  This may indicate aliasing artifacts already present\n');
    else
        fprintf('✓ TDMS files contain non-decimated data\n');
    end
end

% Check for original acquisition rate hints
if any(strcmp('PreciseSamplingFrequency_Hz_', metadata_table.Properties.VariableNames))
    precise_fs = unique(metadata_table.PreciseSamplingFrequency_Hz_);
    if precise_fs ~= unique_fs
        fprintf('⚠ Precise sampling frequency differs: %.6f Hz\n', precise_fs(1));
        fprintf('  May indicate clock drift or resampling\n');
    end
end

%% 2. Data Type and Precision Analysis  
fprintf('\n=== DATA TYPE AND PRECISION ANALYSIS ===\n');

if any(strcmp('data_type', metadata_table.Properties.VariableNames))
    data_types = metadata_table.data_type;
    unique_types = unique(data_types);
    fprintf('TDMS Data Type: %d', unique_types(1));
    
    % Interpret data type codes
    switch unique_types(1)
        case 2
            fprintf(' (16-bit signed integer)\n');
            bit_depth = 16;
            is_integer = true;
        case 9  
            fprintf(' (32-bit floating point)\n');
            bit_depth = 32;
            is_integer = false;
        otherwise
            fprintf(' (unknown type)\n');
            bit_depth = 16; % Assume worst case
            is_integer = true;
    end
    
    if is_integer
        fprintf('✓ Integer data preserves maximum dynamic range\n');
        fprintf('  Recommendation: Keep as integer until final scaling step\n');
    else
        fprintf('⚠ Floating point data may have reduced precision\n');
        fprintf('  Data may have been processed/scaled before TDMS storage\n');
        end
    else
    fprintf('⚠ No data type information found\n');
    bit_depth = 16;
    is_integer = true;
end

%% 3. Processing Order Impact Analysis
fprintf('\n=== PROCESSING ORDER IMPACT ANALYSIS ===\n');

% Calculate theoretical dynamic range
if is_integer
    max_range = 2^(bit_depth-1);
    fprintf('Theoretical dynamic range: ±%d counts (%.1f dB)\n', max_range, 20*log10(max_range));
else
    fprintf('Floating point data - dynamic range depends on original source\n');
end

% Analyze current scaling approach impact
fprintf('\nCurrent pipeline analysis:\n');
fprintf('1. TDMS → MAT: Apply adc_scalar (1/8192) + physical scaling (×116)\n');
fprintf('2. MAT → Concatenated: Load, concatenate, decimate\n');

if is_integer
    fprintf('\n⚠ POTENTIAL ISSUE: Early floating point conversion\n');
    fprintf('  Converting to float in step 1 may introduce quantization noise\n');
    fprintf('  Better: Keep integer precision until after decimation\n');
end

% Check for file size implications
if any(strcmp('channel_length', metadata_table.Properties.VariableNames))
    samples_per_file = unique(metadata_table.channel_length);
    if any(strcmp('num_channels', metadata_table.Properties.VariableNames))
        num_channels = unique(metadata_table.num_channels);
        
        fprintf('\nMemory analysis:\n');
        fprintf('  Samples per file: %d\n', samples_per_file(1));
        fprintf('  Channels: %d\n', num_channels(1));
        
        if is_integer
            bytes_per_sample = bit_depth / 8;
        else
            bytes_per_sample = 4; % Single precision
        end
        
        file_size_mb = (samples_per_file(1) * num_channels(1) * bytes_per_sample) / (1024^2);
        fprintf('  Raw file size: %.1f MB\n', file_size_mb);
        
        % Estimate concatenation memory requirements
        num_files = height(metadata_table);
        total_raw_mb = file_size_mb * num_files;
        fprintf('  Total raw concatenation memory: %.1f MB\n', total_raw_mb);
        
        if total_raw_mb > 1000
            fprintf('  ⚠ Large memory requirement for direct concatenation\n');
        else
            fprintf('  ✓ Reasonable memory requirement for optimal processing\n');
        end
    end
end

%% 4. Anti-Aliasing Analysis
fprintf('\n=== ANTI-ALIASING ANALYSIS ===\n');

if exist('unique_fs', 'var')
    nyquist_freq = unique_fs(1) / 2;
    fprintf('Current Nyquist frequency: %.1f Hz\n', nyquist_freq);
    
    % Check if this looks like already-decimated data
    if unique_fs(1) <= 200
        fprintf('⚠ Low sampling rate suggests pre-decimation occurred\n');
        fprintf('  Original acquisition may have been at higher rate\n');
        fprintf('  Check for aliasing artifacts in frequency domain\n');
    else
        fprintf('✓ Sampling rate suggests minimal pre-decimation\n');
    end
    
    % Decimation impact analysis
    decimation_factor = 100; % From current pipeline
    final_nyquist = nyquist_freq / decimation_factor;
    fprintf('After 100x decimation: Nyquist = %.3f Hz\n', final_nyquist);
    
    if final_nyquist < 0.1
        fprintf('⚠ Very low final Nyquist frequency\n');
        fprintf('  Consider whether 100x decimation is appropriate\n');
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

