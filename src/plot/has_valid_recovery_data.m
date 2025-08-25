function has_valid_data = has_valid_recovery_data(zone_data)
%HAS_VALID_RECOVERY_DATA Check if zone has valid recovery data for plotting

has_valid_data = isfield(zone_data, 'recovery_data') && ~isempty(zone_data.recovery_data) && ...
                 isfield(zone_data.recovery_data, 'Date') && isfield(zone_data.recovery_data, 'Drawdownft') && ...
                 length(zone_data.recovery_data.Date) > 1;

end
