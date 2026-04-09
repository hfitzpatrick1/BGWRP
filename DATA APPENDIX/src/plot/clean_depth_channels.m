function data_out = clean_depth_channels(data_in, depth_m, smooth_window)
%CLEAN_DEPTH_CHANNELS Remove outlier DAS channels and smooth along depth
%
% Detects channels whose temporal mean deviates significantly from their
% neighbors (bad channels from casing joints, splices, etc.) and replaces
% them with interpolated values. Then applies depth-direction movmean.
%
% Only for plot display -- does not modify analysis data.
%
% Inputs:
%   data_in       - [time x depth] matrix
%   depth_m       - depth vector (meters), used for logging only
%   smooth_window - movmean window size in channels (e.g. 21)
%
% Output:
%   data_out      - cleaned and smoothed [time x depth] matrix

data_out = data_in;
n_channels = size(data_in, 2);

if n_channels < 10
    return;
end

% Step 1: Detect outlier channels
% Compare each channel's temporal mean to a local median of channel means
channel_means = mean(data_in, 1, 'omitnan');  % [1 x depth]

% Local median over a wide window to get the "expected" value per channel
local_window = min(31, n_channels);
local_median = movmedian(channel_means, local_window);
local_mad = movmedian(abs(channel_means - local_median), local_window);
local_mad(local_mad < eps) = median(abs(channel_means - median(channel_means)));

% Flag channels that deviate more than 4 MADs from local median
threshold = 4;
outlier_mask = abs(channel_means - local_median) > threshold * local_mad;

n_outliers = sum(outlier_mask);
if n_outliers > 0 && n_outliers < n_channels * 0.1  % sanity: don't remove >10%
    outlier_idx = find(outlier_mask);
    good_idx = find(~outlier_mask);
    
    % Replace outlier channels with linear interpolation from neighbors
    for t = 1:size(data_in, 1)
        row = data_in(t, :);
        row(outlier_idx) = interp1(good_idx, row(good_idx), outlier_idx, 'linear', 'extrap');
        data_out(t, :) = row;
    end
    
    % Log which depths were cleaned
    if n_outliers <= 10
        outlier_depths = depth_m(outlier_idx);
        console_log('    Plot cleaning: interpolated %d outlier channels at depths: %s m\n', ...
            n_outliers, mat2str(round(outlier_depths, 1)));
    else
        console_log('    Plot cleaning: interpolated %d outlier channels\n', n_outliers);
    end
end

% Step 2: Depth-direction moving average to reduce remaining banding
data_out = movmean(data_out, smooth_window, 2);

end
