function unified_bounds = get_related_dataset_bounds(das_data_array, data_type, config)
%GET_RELATED_DATASET_BOUNDS Calculate unified bounds across related datasets
%
% Analyzes multiple datasets and calculates consistent bounds that work
% well for all datasets in the group, enabling visual comparison.
%
% Inputs:
%   das_data_array - Cell array of das_data structures from multiple tests
%   data_type      - Type of data to analyze: 'raw', 'displacement', 'strain'
%   config         - Configuration structure with dynamic bounds settings
%
% Output:
%   unified_bounds - [lower_bound, upper_bound] suitable for all datasets

console_log('Calculating unified bounds for %d related datasets (%s data)\n', ...
        length(das_data_array), data_type);

% Extract data from all datasets
all_data = {};
dataset_names = {};

for i = 1:length(das_data_array)
    das_data = das_data_array{i};
    
    % Get dataset identifier
    if isfield(das_data, 'data_file')
        [~, dataset_name, ~] = fileparts(das_data.data_file);
        dataset_names{i} = dataset_name;
    else
        dataset_names{i} = sprintf('Dataset_%d', i);
    end
    
    % Extract appropriate data based on type
    switch lower(data_type)
        case 'raw'
            if isfield(das_data, 'smoothed_data')
                data = das_data.smoothed_data;
            else
                warning('No smoothed_data found for %s', dataset_names{i});
                continue;
            end
            
        case 'displacement'
            if isfield(das_data, 'analysis_strain_rate')
                data = das_data.analysis_strain_rate;
            else
                warning('No analysis_strain_rate found for %s', dataset_names{i});
                continue;
            end
            
        case 'strain'
            % For strain unified bounds, use a simplified approach since we can't 
            % replicate the exact integration + detrending done during plotting
            warning('Strain unified bounds use simplified calculation - may differ from individual bounds');
            if isfield(das_data, 'smoothed_data')
                % Use a simple proxy: integrated raw data (without detrending)
                data = cumsum(das_data.smoothed_data, 1) / 10;  % Similar scaling to plotting
            else
                warning('No smoothed_data found for strain bounds calculation for %s', dataset_names{i});
                continue;
            end
            
        otherwise
            error('Unknown data type: %s. Use raw, displacement, or strain', data_type);
    end
    
    % Store data for combined analysis
    if ~isempty(data) && isnumeric(data)
        all_data{end+1} = data;
        console_log('  %s: [%.3f, %.3f] (size: %dx%d)\n', ...
                dataset_names{i}, min(data(:)), max(data(:)), size(data, 1), size(data, 2));
    end
end

% Check if we have any valid data
if isempty(all_data)
    warning('No valid data found for any dataset');
    unified_bounds = [0, 1];
    return;
end

% Get dynamic bounds configuration
if isfield(config, 'dynamic_bounds_mode')
    mode = config.dynamic_bounds_mode;
else
    mode = 'percentile';  % Default
end

% Calculate unified bounds using all data
console_log('Calculating unified bounds using mode: %s\n', mode);

% Apply different parameters based on data type
switch lower(data_type)
    case 'raw'
        % Raw data: use conservative percentiles
        unified_bounds = calculate_dynamic_bounds(all_data, mode, ...
                                                'Percentiles', [5, 95], ...
                                                'StdDevFactor', 2.5);
    case 'displacement'
        % Displacement rate: more sensitive to small changes
        unified_bounds = calculate_dynamic_bounds(all_data, mode, ...
                                                'Percentiles', [10, 90], ...
                                                'StdDevFactor', 2);
    case 'strain'
        % Strain: often shows gradual accumulation
        unified_bounds = calculate_dynamic_bounds(all_data, mode, ...
                                                'Percentiles', [2, 98], ...
                                                'StdDevFactor', 3, ...
                                                'Symmetric', true);
end

console_log('✓ Unified bounds: [%.6f, %.6f]\n', unified_bounds(1), unified_bounds(2));

% Provide individual dataset statistics for comparison
console_log('\nIndividual dataset ranges:\n');
for i = 1:length(all_data)
    data = all_data{i};
    individual_bounds = calculate_dynamic_bounds(data, mode);
    console_log('  %s: [%.6f, %.6f]\n', dataset_names{i}, individual_bounds(1), individual_bounds(2));
end

end
