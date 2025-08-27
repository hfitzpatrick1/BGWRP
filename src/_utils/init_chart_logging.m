function init_chart_logging(config)
%INIT_CHART_LOGGING Initialize chart logging system
%
% This function sets up chart logging for a plotting session.
% Call this at the beginning of generate_plots.m
%
% Input:
%   config - Configuration structure containing base_input path
%
% Usage:
%   init_chart_logging(config);

try
    chart_logger('init', config);
    chart_logger('=== CHART GENERATION SESSION STARTED ===');
    chart_logger('Configuration loaded successfully');
    
    % Log key configuration settings
    if isfield(config, 'dynamic_bounds')
        chart_logger('Dynamic bounds: %s', logical_to_string(config.dynamic_bounds));
    end
    
    if isfield(config, 'plot_method')
        chart_logger('Plot method: %s', config.plot_method);
    end
    
    if isfield(config, 'colormap_name')
        chart_logger('Colormap: %s', config.colormap_name);
    end
    
    if isfield(config, 'save_charts')
        chart_logger('Save charts: %s', logical_to_string(config.save_charts));
    end
    
    chart_logger('Chart logging ready');
    
catch ME
    warning('BGWRP:ChartLogging', 'Chart logging initialization failed: %s', ME.message);
end

end

function str = logical_to_string(val)
%LOGICAL_TO_STRING Convert logical to readable string
if val
    str = 'enabled';
else
    str = 'disabled';
end
end
