function filtered_data = apply_spatial_median_filter(data1Hz, config)
%APPLY_SPATIAL_MEDIAN_FILTER Remove vertical artifacts using spatial median filtering
%
% This filter removes coherent vertical noise (striping) while preserving 
% horizontal pump test signals by applying median filtering across channels
%
% Input:
%   data1Hz - Input DAS data [time x channels]
%   config  - Configuration structure
%
% Output:
%   filtered_data - Spatially filtered DAS data [time x channels]

% Get configuration parameters
channels_window = 21;  % Default: 21 channels
time_window = 3;       % Default: 3 time samples

if isfield(config, 'spatial_median_channels')
    channels_window = config.spatial_median_channels;
end
if isfield(config, 'spatial_median_time')
    time_window = config.spatial_median_time;
end

% Ensure odd window size for symmetric filtering
if mod(channels_window, 2) == 0
    channels_window = channels_window + 1;
end

fprintf('  Spatial median filter: %d channels, %d time samples\n', channels_window, time_window);

[num_time, num_channels] = size(data1Hz);
filtered_data = zeros(size(data1Hz));

% Step 1: Apply spatial median filter across channels (removes vertical striping)
fprintf('    Step 1: Removing vertical artifacts...\n');
half_window = floor(channels_window / 2);

for t = 1:num_time
    for ch = 1:num_channels
        % Define channel window boundaries
        ch_start = max(1, ch - half_window);
        ch_end = min(num_channels, ch + half_window);
        
        % Extract spatial neighborhood
        spatial_data = data1Hz(t, ch_start:ch_end);
        
        % Apply median filter to remove outliers/coherent noise
        median_value = median(spatial_data);
        
        % Preserve local variations while removing coherent noise (much gentler)
        filtered_data(t, ch) = data1Hz(t, ch) - (median_value * 0.1);
    end
end

% Step 2: Light temporal smoothing to clean up any remaining noise
if time_window > 1
    fprintf('    Step 2: Light temporal smoothing...\n');
    for ch = 1:num_channels
        filtered_data(:, ch) = movmean(filtered_data(:, ch), time_window);
    end
end

fprintf('  Spatial median filtering complete\n');

end
