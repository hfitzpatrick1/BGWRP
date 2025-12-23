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
                fprintf('    Using manual bounds for raw: [%.1f, %.1f] nm/s\n', bounds(1), bounds(2));
                return;
            end
        case 'displacement'
            if isfield(config.manual_bounds, 'displacement')
                bounds = [config.manual_bounds.displacement.min, config.manual_bounds.displacement.max];
                fprintf('    Using manual bounds for displacement: [%.1f, %.1f] nm/s\n', bounds(1), bounds(2));
                return;
            end
        case 'strain'
            if isfield(config.manual_bounds, 'strain')
                bounds = [config.manual_bounds.strain.min, config.manual_bounds.strain.max];
                fprintf('    Using manual bounds for strain: [%.1f, %.1f] nm/m\n', bounds(1), bounds(2));
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
    case 'head_data'
        bounds = [-0.1, 0.1];  % Default drawdown rate bounds (ft/min)
    case 'pw_head_data'
        bounds = [0, 30];  % Default pumping well drawdown rate bounds (ft/min)
    case 'displacement_rate_line'
        bounds = [-0.3, 0.1];  % Default DAS displacement rate line bounds (nm/s)
    case 'strain_line'
        bounds = [-0.2, 0.2];  % Default DAS strain line bounds (nm/m)
    case 'head_data_strain'
        bounds = [-0.1, 0.1];  % Default head level bounds for strain plots (ft)
    case 'pw_head_strain'
        bounds = [-2, 2];  % Default pumping well head level bounds for strain plots (ft)
    otherwise
        bounds = [-1, 1];
end

end
