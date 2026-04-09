function cleaned_data = mask_bad_channels(data, depth_ft, config)
%MASK_BAD_CHANNELS Detect and remove bad channels (horizontal artifacts)
%
% Detects channels with anomalously high variance or outlier values and
% either sets them to NaN or interpolates over them.
%
% Inputs:
%   data      - DAS data [time x channels]
%   depth_ft  - Depth array [1 x channels]
%   config    - Configuration structure
%
% Outputs:
%   cleaned_data - Data with bad channels removed/interpolated

console_log('  Detecting and removing bad channels...\n');

% Get configuration parameters
method = 'interpolate';
if isfield(config, 'bad_channel_method')
    method = config.bad_channel_method;
end

variance_threshold = 10;  % Multiple of median variance
if isfield(config, 'bad_channel_variance_threshold')
    variance_threshold = config.bad_channel_variance_threshold;
end

outlier_threshold = 5;  % Standard deviations from mean
if isfield(config, 'bad_channel_threshold')
    outlier_threshold = config.bad_channel_threshold;
end

% Calculate variance for each channel (spatial dimension)
channel_variance = var(data, 0, 1, 'omitnan');  % Variance across time for each channel
median_variance = median(channel_variance, 'omitnan');

% Detect bad channels based on high variance
bad_channels_variance = channel_variance > (variance_threshold * median_variance);

% Detect bad channels based on outlier values
channel_mean = mean(data, 1, 'omitnan');
global_mean = mean(channel_mean, 'omitnan');
global_std = std(channel_mean, 'omitnan');
bad_channels_outlier = abs(channel_mean - global_mean) > (outlier_threshold * global_std);

% Combine detection methods
bad_channels = bad_channels_variance | bad_channels_outlier;

n_bad = sum(bad_channels);
console_log('    Detected %d bad channels (%.1f%% of total)\n', n_bad, 100*n_bad/length(bad_channels));

if n_bad == 0
    console_log('    No bad channels detected\n');
    cleaned_data = data;
    return;
end

% Report bad channel depths
bad_depths = depth_ft(bad_channels);
console_log('    Bad channel depths: ');
for i = 1:min(10, length(bad_depths))
    console_log('%.1f ', bad_depths(i));
end
if length(bad_depths) > 10
    console_log('... (%d more)', length(bad_depths) - 10);
end
console_log(' ft\n');

% Apply correction method
cleaned_data = data;

switch lower(method)
    case 'nan'
        % Set bad channels to NaN
        cleaned_data(:, bad_channels) = NaN;
        console_log('    Set %d bad channels to NaN\n', n_bad);
        
    case 'interpolate'
        % Interpolate over bad channels using neighboring good channels
        console_log('    Interpolating over bad channels...\n');
        
        % For each bad channel, interpolate using surrounding good channels
        for t = 1:size(data, 1)
            time_slice = data(t, :);
            good_channels = ~bad_channels & ~isnan(time_slice);
            
            if sum(good_channels) >= 2
                % Interpolate bad channels from good channels
                good_depths = depth_ft(good_channels);
                good_values = time_slice(good_channels);
                bad_depths_t = depth_ft(bad_channels);
                
                % Use linear interpolation
                interpolated_values = interp1(good_depths, good_values, bad_depths_t, 'linear', 'extrap');
                cleaned_data(t, bad_channels) = interpolated_values;
            end
        end
        console_log('    Interpolated %d bad channels\n', n_bad);
        
    otherwise
        warning('Unknown bad channel method: %s. Using NaN method.', method);
        cleaned_data(:, bad_channels) = NaN;
end

% Report results
original_range = [min(data(:), 'omitnan'), max(data(:), 'omitnan')];
cleaned_range = [min(cleaned_data(:), 'omitnan'), max(cleaned_data(:), 'omitnan')];
console_log('    Data range: [%.3f, %.3f] -> [%.3f, %.3f] nm/s\n', ...
    original_range(1), original_range(2), cleaned_range(1), cleaned_range(2));

end
