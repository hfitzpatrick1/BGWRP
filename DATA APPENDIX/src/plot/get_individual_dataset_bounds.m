function bounds = get_individual_dataset_bounds(das_data, data_type, config, dataset_name)
%GET_INDIVIDUAL_DATASET_BOUNDS Calculate bounds for single dataset
%
% Inputs:
%   das_data     - Single das_data struct
%   data_type    - 'raw', 'displacement', or 'strain'
%   config       - Configuration structure
%   dataset_name - (Optional) Dataset name for per-dataset manual bounds
%
% Output:
%   bounds - [lower_bound, upper_bound]

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
    if nargin >= 4 && ~isempty(dataset_name)
        bounds = get_fixed_bounds(data_type, config, dataset_name);
    else
        bounds = get_fixed_bounds(data_type, config);
    end
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
