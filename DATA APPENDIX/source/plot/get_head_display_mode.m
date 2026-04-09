function display_mode = get_head_display_mode(test_label, config)
%GET_HEAD_DISPLAY_MODE Get display mode for head data

if isfield(config, 'head_zones') && isfield(config.head_zones, test_label) && isfield(config.head_zones.(test_label), 'display_mode')
    display_mode = config.head_zones.(test_label).display_mode;
elseif isfield(config, 'head_zones') && isfield(config.head_zones, 'default') && isfield(config.head_zones.default, 'display_mode')
    display_mode = config.head_zones.default.display_mode;
else
    display_mode = 'multiple';  % Default
end

end
