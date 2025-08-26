function bounds = get_plot_bounds(das_data_array, data_type, config)
%GET_PLOT_BOUNDS Get appropriate plot bounds based on configuration
%
% Wrapper function that determines whether to use individual dataset bounds
% or unified bounds across related datasets.
%
% Inputs:
%   das_data_array - Single das_data struct OR cell array of das_data structs
%   data_type      - 'raw', 'displacement', or 'strain'
%   config         - Configuration structure
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
    bounds = get_fixed_bounds(data_type, config);
    if isfield(config, 'manual_bounds')
        fprintf('    Manual %s bounds: [%.3f, %.3f]\n', data_type, bounds(1), bounds(2));
    else
        fprintf('    Fixed %s bounds: [%.3f, %.3f]\n', data_type, bounds(1), bounds(2));
    end
    return;
end

% Dynamic bounds enabled - check if we should use related bounds
if length(das_data_array) > 1 && isfield(config, 'use_related_bounds') && config.use_related_bounds
    % Calculate unified bounds across all datasets
    bounds = get_related_dataset_bounds(das_data_array, data_type, config);
    fprintf('    Unified %s bounds: [%.6f, %.6f]\n', data_type, bounds(1), bounds(2));
else
    % Calculate bounds for single dataset
    bounds = get_individual_dataset_bounds(das_data_array{1}, data_type, config);
    fprintf('    Individual %s bounds: [%.6f, %.6f]\n', data_type, bounds(1), bounds(2));
end

end

function bounds = get_fixed_bounds(data_type, config)
%GET_FIXED_BOUNDS Return fixed bounds (manual or traditional)

% Check if manual bounds are configured
if nargin > 1 && isfield(config, 'manual_bounds')
    switch lower(data_type)
        case 'raw'
            if isfield(config.manual_bounds, 'raw')
                bounds = [config.manual_bounds.raw.min, config.manual_bounds.raw.max];
                return;
            end
        case 'displacement'
            if isfield(config.manual_bounds, 'displacement')
                bounds = [config.manual_bounds.displacement.min, config.manual_bounds.displacement.max];
                return;
            end
        case 'strain'
            if isfield(config.manual_bounds, 'strain')
                bounds = [config.manual_bounds.strain.min, config.manual_bounds.strain.max];
                return;
            end
    end
end

% Fall back to traditional fixed bounds
switch lower(data_type)
    case 'raw'
        bounds = [-2, 2];
    case 'displacement'
        bounds = [-0.25, 0.15];
    case 'strain'
        bounds = [-2, 0];
    otherwise
        bounds = [-1, 1];
end
end

function bounds = get_individual_dataset_bounds(das_data, data_type, config)
%GET_INDIVIDUAL_DATASET_BOUNDS Calculate bounds for single dataset

% Get analysis window for focused bounds calculation
if isfield(das_data, 'analysis_time') && length(das_data.analysis_time) >= 2
    analysis_start = das_data.analysis_time(1);
    analysis_end = das_data.analysis_time(end);
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
else
    analysis_mask = true(size(das_data.time_array));
end

% Get pumping zone for focused bounds calculation
if isfield(das_data, 'pumping_zone')
    zone_mask = das_data.depth_ft >= das_data.pumping_zone.min_ft & ...
                das_data.depth_ft <= das_data.pumping_zone.max_ft;
else
    zone_mask = true(size(das_data.depth_ft));
end

% Extract data based on type
switch lower(data_type)
    case 'raw'
        if isfield(das_data, 'smoothed_data')
            data = das_data.smoothed_data(analysis_mask, zone_mask);
        else
            error('No smoothed_data found in das_data structure');
        end
        
    case 'displacement'
        if isfield(das_data, 'analysis_strain_rate')
            data = das_data.analysis_strain_rate;  % Already a 1D time series for representative channel
        else
            error('No analysis_strain_rate found in das_data structure');
        end
        
    case 'strain'
        if isfield(das_data, 'analysis_strain_rate') && isfield(das_data, 'analysis_time')
            strain_rate = das_data.analysis_strain_rate;  % Already a 1D time series for representative channel
            time_vec = das_data.analysis_time;
            dt = seconds(mean(diff(time_vec)));
            data = cumsum(strain_rate * dt, 1);
        else
            error('Cannot calculate strain: missing analysis_strain_rate or analysis_time');
        end
        
    otherwise
        error('Unknown data type: %s', data_type);
end

% Check if dynamic bounds are enabled
if ~isfield(config, 'dynamic_bounds') || ~config.dynamic_bounds
    % Use fixed bounds
    bounds = get_fixed_bounds(data_type, config);
else
    % Get bounds mode from config
    if isfield(config, 'dynamic_bounds_mode')
        mode = config.dynamic_bounds_mode;
    else
        mode = 'percentile';
    end

    % Calculate bounds using appropriate parameters for data type
    switch lower(data_type)
        case 'raw'
            bounds = calculate_dynamic_bounds(data, mode, 'Percentiles', [5, 95]);
        case 'displacement'
            bounds = calculate_dynamic_bounds(data, mode, 'Percentiles', [10, 90]);
        case 'strain'
            bounds = calculate_dynamic_bounds(data, mode, 'Percentiles', [2, 98], 'Symmetric', true);
    end
end

end
