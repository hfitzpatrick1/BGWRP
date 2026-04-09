function filtered_data = spatial_median_filter(data, config)
% SPATIAL_MEDIAN_FILTER - Remove vertical artifacts using spatial median filtering
%
% Removes coherent vertical noise (striping) while preserving horizontal signals
% by applying median filtering across channels at each time sample
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - Spatially filtered DAS data [time x channels]
%
% Configuration Parameters:
%   config.spatial_filter_channels     - Channel window size (default: 21)
%   config.spatial_filter_strength     - Filter strength 0-1 (default: 0.1)
%   config.spatial_filter_temporal     - Temporal smoothing window (default: 3)
%   config.spatial_filter_preserve     - Preserve signal strength 0-1 (default: 0.9)

% Get configuration parameters with defaults
channels_window = get_param(config, 'spatial_filter_channels', 21);
filter_strength = get_param(config, 'spatial_filter_strength', 0.1);
temporal_window = get_param(config, 'spatial_filter_temporal', 3);
preserve_factor = get_param(config, 'spatial_filter_preserve', 0.9);

% Ensure odd window size for symmetric filtering
if mod(channels_window, 2) == 0
    channels_window = channels_window + 1;
end

console_log('    Spatial median: %d channels, strength=%.2f, temporal=%d\n', ...
    channels_window, filter_strength, temporal_window);

[num_time, num_channels] = size(data);
filtered_data = zeros(size(data));

% Apply spatial median filter across channels
half_window = floor(channels_window / 2);

for t = 1:num_time
    for ch = 1:num_channels
        % Define channel window boundaries
        ch_start = max(1, ch - half_window);
        ch_end = min(num_channels, ch + half_window);
        
        % Extract spatial neighborhood
        spatial_data = data(t, ch_start:ch_end);
        
        % Calculate spatial median
        median_value = median(spatial_data);
        
        % Apply filter with configurable strength and preservation
        noise_estimate = median_value * filter_strength;
        filtered_data(t, ch) = data(t, ch) * preserve_factor - noise_estimate;
    end
end

% Optional temporal smoothing
if temporal_window > 1
    console_log('      Applying temporal smoothing (window: %d)\n', temporal_window);
    for ch = 1:num_channels
        filtered_data(:, ch) = movmean(filtered_data(:, ch), temporal_window);
    end
end

console_log('      Spatial filtering complete\n');

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
