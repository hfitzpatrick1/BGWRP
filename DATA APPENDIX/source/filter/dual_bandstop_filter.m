function filtered_data = dual_bandstop_filter(data, config)
% DUAL_BANDSTOP_FILTER Targeted removal of grid pattern frequencies
%
% Removes both slow (0.15-0.33 Hz) and fast (0.395-0.473 Hz) grid patterns
% while preserving low-frequency geological signals (<0.1 Hz)
%
% Input:
%   data   - [time x channels] DAS data matrix
%   config - Configuration structure with filter parameters
%
% Output:
%   filtered_data - Filtered data with grid patterns removed

console_log('Applying dual bandstop filter for grid pattern removal...\n');

[n_time, n_channels] = size(data);
filtered_data = zeros(size(data));

% Filter parameters from config or defaults
fs = get_config_param(config, 'sampling_rate', 1.0);  % Hz
filter_order = get_config_param(config, 'bandstop_order', 4);

% Grid pattern frequency ranges identified from diagnostics
slow_grid_low = get_config_param(config, 'slow_grid_low', 0.15);   % Hz
slow_grid_high = get_config_param(config, 'slow_grid_high', 0.33); % Hz
fast_grid_low = get_config_param(config, 'fast_grid_low', 0.395);  % Hz
fast_grid_high = get_config_param(config, 'fast_grid_high', 0.473); % Hz

console_log('Filter settings:\n');
console_log('  Sampling rate: %.1f Hz\n', fs);
console_log('  Nyquist frequency: %.2f Hz\n', fs/2);
console_log('  Slow grid stop band: %.3f - %.3f Hz\n', slow_grid_low, slow_grid_high);
console_log('  Fast grid stop band: %.3f - %.3f Hz\n', fast_grid_low, fast_grid_high);
console_log('  Filter order: %d\n', filter_order);

% Validate frequencies are within Nyquist limit
nyquist = fs / 2;
if fast_grid_high >= nyquist
    warning('Fast grid high frequency (%.3f Hz) >= Nyquist (%.2f Hz), clamping to %.2f Hz', ...
        fast_grid_high, nyquist, nyquist * 0.95);
    fast_grid_high = nyquist * 0.95;
end

try
    % Design dual bandstop filter using elliptic design for sharp transitions
    % Stop band 1: Slow grid patterns (0.15-0.33 Hz)
    [b1, a1] = ellip(filter_order, 1, 40, [slow_grid_low slow_grid_high]/(nyquist), 'stop');
    
    % Stop band 2: Fast grid patterns (0.395-0.473 Hz) 
    [b2, a2] = ellip(filter_order, 1, 40, [fast_grid_low fast_grid_high]/(nyquist), 'stop');
    
    console_log('Filter design successful\n');
    
catch ME
    warning('MATLAB:filterDesignFailed', 'Elliptic filter design failed: %s. Using Butterworth fallback.', ME.message);
    try
        % Fallback to Butterworth filters
        [b1, a1] = butter(filter_order, [slow_grid_low slow_grid_high]/(nyquist), 'stop');
        [b2, a2] = butter(filter_order, [fast_grid_low fast_grid_high]/(nyquist), 'stop');
        console_log('Butterworth filter design successful\n');
    catch ME2
        warning('MATLAB:filterDesignFailed', 'Filter design completely failed: %s. Applying no filtering.', ME2.message);
        filtered_data = data;
        return;
    end
end

% Apply filters to each channel
console_log('Filtering channels: ');
for ch = 1:n_channels
    if mod(ch, 100) == 0 || ch == n_channels
        console_log('%d ', ch);
    end
    
    try
        % Get channel data
        channel_data = data(:, ch);
        
        % Apply first bandstop filter (slow grid)
        filtered_ch = filtfilt(b1, a1, channel_data);
        
        % Apply second bandstop filter (fast grid) 
        filtered_ch = filtfilt(b2, a2, filtered_ch);
        
        % Store result
        filtered_data(:, ch) = filtered_ch;
        
    catch ME
        warning('MATLAB:channelFilterFailed', 'Filtering failed for channel %d: %s. Using original data.', ch, ME.message);
        filtered_data(:, ch) = data(:, ch);
    end
end
console_log('\n');

% Calculate filter performance metrics
original_power = sum(var(data, 0, 1));
filtered_power = sum(var(filtered_data, 0, 1));
noise_reduction = (original_power - filtered_power) / original_power * 100;

% Calculate signal preservation in low-frequency band (<0.1 Hz)
signal_freq_range = [0.01, 0.1]; % Hz - geological recovery signals
try
    % Design low-pass filter to extract signal band
    [b_sig, a_sig] = butter(2, signal_freq_range(2)/(nyquist), 'low');
    
    original_signal = filtfilt(b_sig, a_sig, mean(data, 2));
    filtered_signal = filtfilt(b_sig, a_sig, mean(filtered_data, 2));
    
    signal_correlation = corrcoef(original_signal, filtered_signal);
    signal_preservation = signal_correlation(1,2) * 100;
    
    console_log('Performance metrics:\n');
    console_log('  Overall noise reduction: %.1f%%\n', noise_reduction);
    console_log('  Low-frequency signal preservation: %.1f%%\n', signal_preservation);
    
catch
    console_log('Performance metrics:\n');
    console_log('  Overall noise reduction: %.1f%%\n', noise_reduction);
    console_log('  Signal preservation: Unable to calculate\n');
end

% Amplitude analysis
original_range = [min(data(:)), max(data(:))];
filtered_range = [min(filtered_data(:)), max(filtered_data(:))];
amplitude_change = (diff(filtered_range) / diff(original_range)) * 100;

console_log('  Amplitude preservation: %.1f%%\n', amplitude_change);
console_log('  Original range: [%.3f, %.3f]\n', original_range(1), original_range(2));
console_log('  Filtered range: [%.3f, %.3f]\n', filtered_range(1), filtered_range(2));

console_log('Dual bandstop filtering complete\n');

end

function value = get_config_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
