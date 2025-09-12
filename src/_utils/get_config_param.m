function value = get_config_param(config, param_name, default_value)
%GET_CONFIG_PARAM Safe parameter extraction from config structure
%
% Usage:
%   value = get_config_param(config, 'param_name', default_value)
%
% Returns the parameter value if it exists in config, otherwise returns default_value

if nargin < 3
    default_value = [];
end

if isstruct(config) && isfield(config, param_name)
    value = config.(param_name);
else
    value = default_value;
    if nargin >= 3
        fprintf('      Warning: Parameter "%s" not found, using default: %s\n', ...
            param_name, mat2str(default_value));
    end
end

end




