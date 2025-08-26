function filtered_data = chen_stage2_somf(data, config)
% CHEN_STAGE2_SOMF - Structure-Oriented Median Filter (Chen et al. Stage 2)
%
% Removes high-amplitude erratic noise while preserving signal structure
% Simplified implementation of structure-oriented median filtering
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - SOMF filtered data [time x channels]
%
% Configuration Parameters:
%   config.chen_somf_window       - Median filter window (default: 17)
%   config.chen_somf_strength     - Filter strength 0-1 (default: 0.3)
%   config.chen_somf_preserve     - Signal preservation 0-1 (default: 0.7)
%   config.chen_somf_adaptive     - Use adaptive filtering (default: true)

% Get configuration parameters
window_size = get_param(config, 'chen_somf_window', 17);
filter_strength = get_param(config, 'chen_somf_strength', 0.3);
preserve_factor = get_param(config, 'chen_somf_preserve', 0.7);
adaptive = get_param(config, 'chen_somf_adaptive', true);

fprintf('      SOMF: window=%d, strength=%.2f, adaptive=%d\n', ...
    window_size, filter_strength, adaptive);

[num_time, num_channels] = size(data);
filtered_data = zeros(size(data));

% Apply median filtering to each channel
for ch = 1:num_channels
    % Extract channel data
    channel_data = data(:, ch);
    
    if adaptive
        % Adaptive median filtering - adjust window based on local noise
        filtered_channel = adaptive_median_filter(channel_data, window_size);
    else
        % Standard median filter
        filtered_channel = medfilt1(channel_data, window_size);
    end
    
    % Combine filtered and original with preservation factor
    noise_estimate = channel_data - filtered_channel;
    filtered_data(:, ch) = channel_data - (noise_estimate * filter_strength);
end

% Apply gentle spatial coherence enhancement
if get_param(config, 'chen_somf_spatial_enhance', true)
    fprintf('        Applying spatial coherence enhancement...\n');
    spatial_window = min(5, num_channels);
    
    for t = 1:num_time
        for ch = 1:num_channels
            % Define spatial neighborhood
            ch_start = max(1, ch - floor(spatial_window/2));
            ch_end = min(num_channels, ch + floor(spatial_window/2));
            
            % Calculate local spatial median
            spatial_data = filtered_data(t, ch_start:ch_end);
            spatial_median = median(spatial_data);
            
            % Blend with spatial median (very gentle)
            blend_factor = 0.1;
            filtered_data(t, ch) = filtered_data(t, ch) * (1 - blend_factor) + ...
                                   spatial_median * blend_factor;
        end
    end
end

fprintf('        SOMF filtering complete\n');

end

function filtered = adaptive_median_filter(data, base_window)
    % Adaptive median filter that adjusts window size based on local variance
    filtered = zeros(size(data));
    n = length(data);
    
    for i = 1:n
        % Calculate local variance to determine optimal window
        local_start = max(1, i - base_window);
        local_end = min(n, i + base_window);
        local_data = data(local_start:local_end);
        local_var = var(local_data);
        
        % Adjust window size based on variance (more variance = larger window)
        if local_var > 2 * var(data)
            window = min(base_window * 2, 51); % Larger window for noisy regions
        else
            window = max(base_window / 2, 3);  % Smaller window for clean regions
        end
        
        % Apply median filter with adaptive window
        win_start = max(1, i - floor(window/2));
        win_end = min(n, i + floor(window/2));
        filtered(i) = median(data(win_start:win_end));
    end
end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
