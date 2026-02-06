function bounds = get_plot_bounds(das_data_array, data_type, config, dataset_name)
%GET_PLOT_BOUNDS Get appropriate plot bounds based on configuration
%
% Wrapper function that determines whether to use individual dataset bounds
% or unified bounds across related datasets.
%
% Inputs:
%   das_data_array - Single das_data struct OR cell array of das_data structs
%   data_type      - 'raw', 'displacement', or 'strain'  
%   config         - Configuration structure
%   dataset_name   - (Optional) Dataset name for per-dataset manual bounds
%
% Output:
%   bounds - [lower_bound, upper_bound]

% Handle single dataset case
if isstruct(das_data_array)
    das_data_array = {das_data_array};
end

% Check configuration for bounds calculation method
if ~isfield(config, 'dynamic_bounds') || ~config.dynamic_bounds
    % Use fixed bounds (manual or traditional)
    if nargin >= 4 && ~isempty(dataset_name)
        bounds = get_fixed_bounds(data_type, config, dataset_name);
    else
        bounds = get_fixed_bounds(data_type, config);
    end
    if isfield(config, 'manual_bounds')
        console_log('    Manual %s bounds: [%.3f, %.3f]\n', data_type, bounds(1), bounds(2));
    else
        console_log('    Fixed %s bounds: [%.3f, %.3f]\n', data_type, bounds(1), bounds(2));
    end
    return;
end

% Dynamic bounds enabled - check if we should use related bounds
if length(das_data_array) > 1 && isfield(config, 'use_related_bounds') && config.use_related_bounds
    % Calculate unified bounds across all datasets
    bounds = get_related_dataset_bounds(das_data_array, data_type, config);
    console_log('    Unified %s bounds: [%.6f, %.6f]\n', data_type, bounds(1), bounds(2));
else
    % Calculate bounds for single dataset
    if nargin >= 4 && ~isempty(dataset_name)
        bounds = get_individual_dataset_bounds(das_data_array{1}, data_type, config, dataset_name);
    else
        bounds = get_individual_dataset_bounds(das_data_array{1}, data_type, config);
    end
    console_log('    Individual %s bounds: [%.6f, %.6f]\n', data_type, bounds(1), bounds(2));
end

end