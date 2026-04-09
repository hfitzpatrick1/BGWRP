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

% Chart log file disabled - all chart_logger output goes to console_log instead
% To re-enable, uncomment: chart_logger('init', config);
console_log('=== CHART GENERATION SESSION STARTED ===\n');
if isfield(config, 'dynamic_bounds')
    console_log('Dynamic bounds: %s\n', logical_to_string(config.dynamic_bounds));
end
if isfield(config, 'plot_method')
    console_log('Plot method: %s\n', config.plot_method);
end
if isfield(config, 'colormap_name')
    console_log('Colormap: %s\n', config.colormap_name);
end
if isfield(config, 'save_charts')
    console_log('Save charts: %s\n', logical_to_string(config.save_charts));
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
