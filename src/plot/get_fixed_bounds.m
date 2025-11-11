function bounds = get_fixed_bounds(data_type, config, dataset_name)
%GET_FIXED_BOUNDS Return fixed bounds (manual or traditional)
%
% Inputs:
%   data_type     - 'raw', 'displacement', or 'strain'
%   config        - Configuration structure
%   dataset_name  - (Optional) Dataset name for per-dataset manual bounds
%
% Output:
%   bounds - [lower_bound, upper_bound]

% Check if manual bounds are configured
if nargin >= 2 && isfield(config, 'manual_bounds')
    
    % Try per-dataset bounds first (new structure)
    if nargin >= 3 && ~isempty(dataset_name) && isfield(config.manual_bounds, dataset_name)
        dataset_bounds = config.manual_bounds.(dataset_name);
        
        % Map data_type to chart_type for new bounds structure
        chart_type = map_data_type_to_chart_type(data_type);
        
        if isfield(dataset_bounds, chart_type) && ...
           isfield(dataset_bounds.(chart_type), 'min') && ...
           isfield(dataset_bounds.(chart_type), 'max')
            bounds = [dataset_bounds.(chart_type).min, dataset_bounds.(chart_type).max];
            return;
        end
    end
    
    % Fall back to global manual bounds (new structure)
    if isfield(config.manual_bounds, 'global')
        global_bounds = config.manual_bounds.global;
        chart_type = map_data_type_to_chart_type(data_type);
        
        if isfield(global_bounds, chart_type) && ...
           isfield(global_bounds.(chart_type), 'min') && ...
           isfield(global_bounds.(chart_type), 'max')
            bounds = [global_bounds.(chart_type).min, global_bounds.(chart_type).max];
            return;
        end
    end
    
    % Legacy manual bounds support (old structure)
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

% Check for default bounds before falling back to traditional bounds
if strcmp(lower(data_type), 'depth_axis') && isfield(config, 'default_depth_axis')
    bounds = [config.default_depth_axis.min, config.default_depth_axis.max];
    return;
end

% Fall back to traditional fixed bounds
switch lower(data_type)
    case 'raw'
        bounds = [-2, 2];
    case 'displacement'
        bounds = [-0.25, 0.15];
    case 'strain'
        bounds = [-2, 0];
    case 'depth_axis'
        bounds = [175, 665];  % Default depth range for all pump tests
    otherwise
        bounds = [-1, 1];
end

end
