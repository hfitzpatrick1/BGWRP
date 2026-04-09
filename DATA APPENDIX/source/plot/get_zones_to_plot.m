function zones_to_plot = get_zones_to_plot(test_label, available_zones, head_data, config)
%GET_ZONES_TO_PLOT Determine which zones to plot based on configuration

% Get configuration for this dataset
if isfield(config, 'head_zones') && isfield(config.head_zones, test_label)
    zone_config = config.head_zones.(test_label);
elseif isfield(config, 'head_zones') && isfield(config.head_zones, 'default')
    zone_config = config.head_zones.default;
else
    % Fallback: show all zones
    zone_config.zones = 'all';
end

% Parse zone configuration
if ischar(zone_config.zones) && strcmp(zone_config.zones, 'all')
    % Use all available zones with valid recovery data
    zones_to_plot = {};
    for i = 1:length(available_zones)
        zone_name = available_zones{i};
        if has_valid_recovery_data(head_data.zones.(zone_name))
            zones_to_plot{end+1} = zone_name;
        end
    end
elseif ischar(zone_config.zones)
    % Single zone specified
    if ismember(zone_config.zones, available_zones) && has_valid_recovery_data(head_data.zones.(zone_config.zones))
        zones_to_plot = {zone_config.zones};
    else
        zones_to_plot = {};
    end
elseif iscell(zone_config.zones)
    % Multiple zones specified
    zones_to_plot = {};
    for i = 1:length(zone_config.zones)
        zone_name = zone_config.zones{i};
        if ismember(zone_name, available_zones) && has_valid_recovery_data(head_data.zones.(zone_name))
            zones_to_plot{end+1} = zone_name;
        end
    end
else
    zones_to_plot = {};
end

end
