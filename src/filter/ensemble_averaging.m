function filtered_data = ensemble_averaging(data, depth_ft, config)
% ENSEMBLE_AVERAGING Multi-channel ensemble averaging for signal extraction
%
% Usage:
%   filtered_data = ensemble_averaging(data, depth_ft, config)
%
% Inputs:
%   data      - [time x channels] DAS data matrix
%   depth_ft  - [1 x channels] depth array in feet
%   config    - Configuration structure with ensemble parameters
%
% Output:
%   filtered_data - [time x channels] processed data with grid artifacts reduced
%
% Method:
%   1. Group channels by geological depth zones
%   2. Calculate ensemble average within each zone
%   3. Use ensemble as reference to enhance signal-to-noise ratio
%   4. Apply weighted combination of original signal and ensemble
%
% Key insight: Geological responses are spatially coherent across formations,
% while grid artifacts are spatially random across channels.

    fprintf('Applying multi-channel ensemble averaging...\n');
    
    [n_time, n_channels] = size(data);
    filtered_data = data; % Initialize output
    
    % Extract configuration parameters
    zone_window = config.ensemble_zone_window;     % Depth window for averaging (ft)
    signal_weight = config.ensemble_signal_weight; % Weight for original vs ensemble
    min_channels = config.ensemble_min_channels;   % Minimum channels per zone
    overlap_ratio = config.ensemble_overlap_ratio; % Zone overlap for smoothing
    
    fprintf('Zone window: %.1f ft, Signal weight: %.2f, Min channels: %d\n', ...
        zone_window, signal_weight, min_channels);
    
    % Calculate depth range and step
    depth_min = min(depth_ft);
    depth_max = max(depth_ft);
    zone_step = zone_window * (1 - overlap_ratio); % Allow overlap between zones
    
    % Process each depth zone
    zone_count = 0;
    processed_channels = false(1, n_channels);
    
    for zone_center = depth_min:zone_step:depth_max
        zone_count = zone_count + 1;
        
        % Define zone boundaries
        zone_start = zone_center - zone_window/2;
        zone_end = zone_center + zone_window/2;
        
        % Find channels in this zone
        zone_channels = find(depth_ft >= zone_start & depth_ft <= zone_end);
        
        if length(zone_channels) < min_channels
            continue; % Skip zones with too few channels
        end
        
        % Calculate ensemble average for this zone
        zone_data = data(:, zone_channels);
        ensemble_signal = mean(zone_data, 2);
        
        % Apply ensemble-based enhancement to each channel in zone
        for i = 1:length(zone_channels)
            ch = zone_channels(i);
            original_signal = data(:, ch);
            
            % Method 1: Weighted combination
            % Enhanced signal = original + ensemble reference
            enhanced_signal = signal_weight * original_signal + ...
                            (1 - signal_weight) * ensemble_signal;
            
            % Method 2: Residual-based enhancement (alternative)
            % residual = original_signal - ensemble_signal;
            % enhanced_signal = ensemble_signal + signal_weight * residual;
            
            % Apply overlap weighting for smooth transitions between zones
            if processed_channels(ch)
                % Channel already processed by previous zone - blend results
                weight = calculate_overlap_weight(depth_ft(ch), zone_center, zone_window);
                filtered_data(:, ch) = weight * enhanced_signal + ...
                                     (1 - weight) * filtered_data(:, ch);
            else
                % First time processing this channel
                filtered_data(:, ch) = enhanced_signal;
                processed_channels(ch) = true;
            end
        end
        
        fprintf('Zone %d: Depth %.1f-%.1f ft, %d channels, ensemble range [%.3f, %.3f]\n', ...
            zone_count, zone_start, zone_end, length(zone_channels), ...
            min(ensemble_signal), max(ensemble_signal));
    end
    
    % Handle any unprocessed channels (edge cases)
    unprocessed = find(~processed_channels);
    if ~isempty(unprocessed)
        fprintf('Warning: %d channels not processed (insufficient zone coverage)\n', ...
            length(unprocessed));
        % Apply simple smoothing to unprocessed channels
        for ch = unprocessed
            filtered_data(:, ch) = smooth(data(:, ch), 5);
        end
    end
    
    % Calculate improvement metrics
    original_std = std(data(:));
    filtered_std = std(filtered_data(:));
    noise_reduction = (original_std - filtered_std) / original_std * 100;
    
    fprintf('Ensemble averaging complete:\n');
    fprintf('  Processed zones: %d\n', zone_count);
    fprintf('  Processed channels: %d/%d (%.1f%%)\n', ...
        sum(processed_channels), n_channels, sum(processed_channels)/n_channels*100);
    fprintf('  Noise reduction: %.1f%%\n', noise_reduction);
    
end

function weight = calculate_overlap_weight(channel_depth, zone_center, zone_window)
% Calculate weighting for overlapping zones based on distance from center
    distance_from_center = abs(channel_depth - zone_center);
    max_distance = zone_window / 2;
    
    % Linear weighting: closer to center = higher weight
    weight = max(0, 1 - distance_from_center / max_distance);
end
