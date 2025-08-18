function config = load_batch_config(config_file)
%LOAD_BATCH_CONFIG Load configuration from text file
%
% Loads simple key=value configuration file
%
% Input:
%   config_file - Path to config file (optional, defaults to batch_config.txt)
%
% Output:
%   config - Configuration structure

if nargin < 1
    script_dir = fileparts(mfilename('fullpath'));
    batch_dir = fileparts(script_dir);
    config_file = fullfile(batch_dir, 'batch_config.txt');
end

config = struct();

if ~exist(config_file, 'file')
    fprintf('Config file not found: %s\n', config_file);
    fprintf('Using defaults\n');
    return;
end

fprintf('Loading config from: %s\n', config_file);

% Read config file
fid = fopen(config_file, 'r');
if fid == -1
    error('Could not open config file: %s', config_file);
end

line_num = 0;
while ~feof(fid)
    line = fgetl(fid);
    line_num = line_num + 1;
    
    if ischar(line)
        % Skip comments and empty lines
        line = strtrim(line);
        if isempty(line) || startsWith(line, '#')
            continue;
        end
        
        % Parse key=value
        equals_pos = strfind(line, '=');
        if length(equals_pos) == 1
            key = strtrim(line(1:equals_pos-1));
            value = strtrim(line(equals_pos+1:end));
            
            % Handle different value types
            if strcmp(key, 'base_input')
                config.base_input = value;
            elseif strcmp(key, 'test_directories')
                config.test_directories = strsplit(value, ',');
                config.test_directories = cellfun(@strtrim, config.test_directories, 'UniformOutput', false);
            elseif strcmp(key, 'test_labels')
                config.test_labels = strsplit(value, ',');
                config.test_labels = cellfun(@strtrim, config.test_labels, 'UniformOutput', false);
            elseif strcmp(key, 'decimation_factor')
                config.decimation_factor = str2double(value);
            elseif strcmp(key, 'waterfall_display_bounds')
                % Parse waterfall display bounds: min,max
                bounds_values = strsplit(value, ',');
                if length(bounds_values) == 2
                    config.waterfall_display_bounds.min_depth = str2double(strtrim(bounds_values{1}));
                    config.waterfall_display_bounds.max_depth = str2double(strtrim(bounds_values{2}));
                    fprintf('  Waterfall display bounds: %.0f-%.0f ft\n', ...
                        config.waterfall_display_bounds.min_depth, ...
                        config.waterfall_display_bounds.max_depth);
                else
                    fprintf('Invalid waterfall display bounds format: %s (expected: min,max)\n', value);
                end
            elseif startsWith(key, 'waterfall_zone_')
                % Parse waterfall zone filtering: waterfall_zone_DATASET=min,max
                dataset_name = key(16:end); % Remove 'waterfall_zone_' prefix
                zone_values = strsplit(value, ',');
                if length(zone_values) == 2
                    if ~isfield(config, 'waterfall_zones')
                        config.waterfall_zones = struct();
                    end
                    config.waterfall_zones.(dataset_name).min_depth = str2double(strtrim(zone_values{1}));
                    config.waterfall_zones.(dataset_name).max_depth = str2double(strtrim(zone_values{2}));
                    fprintf('  Waterfall zone for %s: %.0f-%.0f ft\n', dataset_name, ...
                        config.waterfall_zones.(dataset_name).min_depth, ...
                        config.waterfall_zones.(dataset_name).max_depth);
                else
                    fprintf('Invalid waterfall zone format for %s: %s (expected: min,max)\n', dataset_name, value);
                end
            else
                fprintf('Unknown config key: %s\n', key);
            end
        else
            fprintf('Invalid config line %d: %s\n', line_num, line);
        end
    end
end

fclose(fid);

fprintf('Config loaded successfully\n');

end
