function handle = apply_plot_config(time_data, depth_data, plot_data, config, plot_type)
%APPLY_PLOT_CONFIG Apply configurable plotting settings to eliminate pixelation
%
% Inputs:
%   time_data  - X-axis data (time)
%   depth_data - Y-axis data (depth)
%   plot_data  - Z-axis data (values to plot)
%   config     - Configuration structure with plotting settings
%   plot_type  - Type hint for optimization: 'waterfall', 'contour', 'surface'
%
% Outputs:
%   handle     - Graphics handle for further modification

% Apply data precision settings
if isfield(config, 'force_double_precision') && config.force_double_precision
    plot_data = double(plot_data);
    time_data = double(time_data);
    depth_data = double(depth_data);
end

% Get plotting method (default: pcolor)
plot_method = 'pcolor';
if isfield(config, 'plot_method')
    plot_method = config.plot_method;
end

% DEBUG: Show what plotting method is being used
console_log('    PLOT DEBUG: Config has plot_method field: %d\n', isfield(config, 'plot_method'));
if isfield(config, 'plot_method')
    console_log('    PLOT DEBUG: Config plot_method value: "%s"\n', config.plot_method);
end
console_log('    PLOT DEBUG: Using method "%s"\n', plot_method);

% Create plot based on method
switch lower(plot_method)
    case 'pcolor'
        handle = pcolor(time_data, depth_data, plot_data);
        
        % Apply shading
        shading_method = 'interp';
        if isfield(config, 'shading_method')
            shading_method = config.shading_method;
        end
        console_log('    PLOT DEBUG: Applying shading "%s"\n', shading_method);
        shading(shading_method);
        
        % Set edge color
        edge_color = 'none';
        if isfield(config, 'edge_display')
            edge_color = config.edge_display;
        end
        set(handle, 'EdgeColor', edge_color);
        
    case 'imagesc'
        % For imagesc, we need to handle axis orientation
        handle = imagesc(time_data, depth_data, plot_data);
        
        % Apply interpolation method if supported
        if isfield(config, 'interpolation_method')
            try
                set(handle, 'Interpolation', config.interpolation_method);
            catch
                % Interpolation not supported in older MATLAB versions
            end
        end
        
    case 'surf'
        handle = surf(time_data, depth_data, plot_data);
        view(2); % Top-down view for waterfall-like appearance
        
        % Set edge color
        edge_color = 'none';
        if isfield(config, 'edge_display')
            edge_color = config.edge_display;
        end
        set(handle, 'EdgeColor', edge_color);
        
        % Apply shading for surf
        shading_method = 'interp';
        if isfield(config, 'shading_method')
            shading_method = config.shading_method;
        end
        shading(shading_method);
        
    case 'contourf'
        % Filled contour plot
        num_levels = 50; % Default number of contour levels
        if isfield(config, 'colormap_resolution')
            num_levels = min(config.colormap_resolution / 4, 100);
        end
        handle = contourf(time_data, depth_data, plot_data, num_levels);
        
        % Set edge color
        edge_color = 'none';
        if isfield(config, 'edge_display')
            edge_color = config.edge_display;
        end
        set(handle, 'EdgeColor', edge_color);
        
    otherwise
        warning('Unknown plot method: %s. Using pcolor.', plot_method);
        handle = pcolor(time_data, depth_data, plot_data);
        shading interp;
        set(handle, 'EdgeColor', 'none');
end

% Apply colormap settings
colormap_name = 'jet';
if isfield(config, 'colormap_name')
    colormap_name = config.colormap_name;
end

colormap_resolution = 256;
if isfield(config, 'colormap_resolution')
    colormap_resolution = config.colormap_resolution;
end

% Set colormap with specified resolution
try
    if colormap_resolution == 256
        colormap(colormap_name); % Use default resolution
    else
        colormap(feval(colormap_name, colormap_resolution));
    end
catch ME
    warning('Failed to set colormap %s with %d colors: %s', colormap_name, colormap_resolution, ME.message);
    colormap('jet'); % Fallback
end

% Apply anti-aliasing if supported and requested
if isfield(config, 'anti_aliasing') && ~config.anti_aliasing
    try
        set(gcf, 'GraphicsSmoothing', 'off');
    catch
        % GraphicsSmoothing not supported in older MATLAB versions
    end
end

end
