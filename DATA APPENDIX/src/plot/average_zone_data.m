function averaged_data = average_zone_data(zones_to_plot, head_data)
%AVERAGE_ZONE_DATA Average recovery data from multiple zones

averaged_data = [];
if isempty(zones_to_plot)
    return;
end

% Get first valid zone as reference for timestamps
ref_zone = [];
for i = 1:length(zones_to_plot)
    zone_name = zones_to_plot{i};
    zone_data = head_data.zones.(zone_name);
    if has_valid_recovery_data(zone_data)
        ref_zone = zone_data;
        break;
    end
end

if isempty(ref_zone)
    return;
end

% Initialize with reference timestamps
averaged_data.Date = ref_zone.recovery_data.Date;
drawdown_matrix = [];

% Collect drawdown data from all zones
for i = 1:length(zones_to_plot)
    zone_name = zones_to_plot{i};
    zone_data = head_data.zones.(zone_name);
    if has_valid_recovery_data(zone_data) && length(zone_data.recovery_data.Date) == length(averaged_data.Date)
        if isempty(drawdown_matrix)
            drawdown_matrix = zone_data.recovery_data.Drawdownft;
        else
            drawdown_matrix = [drawdown_matrix, zone_data.recovery_data.Drawdownft];
        end
    end
end

% Average across zones
if ~isempty(drawdown_matrix)
    averaged_data.Drawdownft = mean(drawdown_matrix, 2);
else
    averaged_data = [];
end

end
