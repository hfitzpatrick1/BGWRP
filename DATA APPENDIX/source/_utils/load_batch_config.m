function config = load_batch_config()
%LOAD_BATCH_CONFIG Load configuration using MATLAB function approach
%
% Loads configuration by calling get_batch_config() function
%
% Output:
%   config - Configuration structure

console_log('Loading batch configuration...\n');

% Get configuration from MATLAB function
config = config();

% Validate required fields
if ~isfield(config, 'base_input') || isempty(config.base_input)
    error('base_input is required in configuration');
end

% Set defaults for optional fields
if ~isfield(config, 'save_charts')
    config.save_charts = false;
end

if ~isfield(config, 'decimation_factor')
    config.decimation_factor = 100;
end

% Display configuration summary
console_log('Configuration summary:\n');
console_log('  Base input: %s\n', config.base_input);
if isfield(config, 'waterfall_display_bounds')
    console_log('  Waterfall display bounds: %.0f-%.0f ft\n', ...
        config.waterfall_display_bounds.min_depth, ...
        config.waterfall_display_bounds.max_depth);
end
if isfield(config, 'waterfall_zones')
    zone_names = fieldnames(config.waterfall_zones);
    console_log('  Configured waterfall zones:\n');
    for i = 1:length(zone_names)
        zone = zone_names{i};
        console_log('    %s: %.0f-%.0f ft\n', zone, ...
            config.waterfall_zones.(zone).min_depth, ...
            config.waterfall_zones.(zone).max_depth);
    end
end

end
