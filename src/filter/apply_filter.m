function filtered_data = apply_filter(data, filter_type, config)
% APPLY_FILTER - Universal filter dispatcher for DAS data
%
% Central filtering interface that routes to specific filter implementations
% based on configuration parameters
%
% Input:
%   data        - DAS data [time x channels]
%   filter_type - Filter type string
%   config      - Configuration structure with filter parameters
%
% Output:
%   filtered_data - Filtered DAS data [time x channels]
%
% Filter Types:
%   'none'              - No filtering (passthrough)
%   'movmean'           - Moving average (temporal)
%   'movmedian'         - Moving median (temporal)
%   'spatial_median'    - Spatial median filter
%   'chen_full'         - Complete Chen et al. 3-stage framework
%   'chen_stage1'       - Chen Stage 1: Butterworth bandpass
%   'chen_stage2'       - Chen Stage 2: Structure-oriented median
%   'chen_stage3'       - Chen Stage 3: F-K dip filter
%   'butterworth_bp'    - Butterworth bandpass filter
%   'fk_dip'           - F-K domain dip filter
%   'custom'           - Custom filter chain from config

fprintf('  Applying filter: %s\n', filter_type);

switch lower(filter_type)
    case 'none'
        filtered_data = data;
        fprintf('    No filtering applied\n');
        
    case 'movmean'
        window = get_config_param(config, 'temporal_window', 10);
        filtered_data = movmean(data, window, 1);
        fprintf('    Moving average: window=%d\n', window);
        
    case 'movmedian'
        window = get_config_param(config, 'temporal_window', 10);
        filtered_data = movmedian(data, window, 1);
        fprintf('    Moving median: window=%d\n', window);
        
    case 'spatial_median'
        filtered_data = spatial_median_filter(data, config);
        
    case 'chen_full'
        filtered_data = chen_framework_complete(data, config);
        
    case 'chen_stage1'
        filtered_data = chen_stage1_bandpass(data, config);
        
    case 'chen_stage2'
        filtered_data = chen_stage2_somf(data, config);
        
    case 'chen_stage3'
        filtered_data = chen_stage3_fk(data, config);
        
    case 'butterworth_bp'
        filtered_data = butterworth_bandpass(data, config);
        
    case 'fk_dip'
        filtered_data = fk_dip_filter(data, config);
        
    case 'custom'
        filtered_data = apply_custom_filter_chain(data, config);
        
    otherwise
        warning('Unknown filter type: %s, applying no filtering', filter_type);
        filtered_data = data;
end

fprintf('    Filter complete: range [%.3f, %.3f] -> [%.3f, %.3f]\n', ...
    min(data(:)), max(data(:)), min(filtered_data(:)), max(filtered_data(:)));

end

function value = get_config_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
