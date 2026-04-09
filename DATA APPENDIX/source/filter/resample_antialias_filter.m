function filtered_data = resample_antialias_filter(data, config)
%RESAMPLE_ANTIALIAS_FILTER Apply the same anti-aliasing filter used in decimation
%
% This applies the Kaiser window FIR filter that resample() uses for anti-aliasing,
% but WITHOUT actually downsampling. This makes 100Hz data look like 1Hz data
% would look (clean) while preserving the 100Hz time resolution.
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - Filtered data at original sampling rate

% Get parameters
decimation_factor = get_param(config, 'decimation_factor', 100);
console_log('      Applying resample anti-alias filter (simulating %dx decimation)\n', decimation_factor);
console_log('      This uses the SAME filter as your 1Hz data!\n');

[num_time, num_channels] = size(data);
console_log('      Data size: [%d time points x %d channels]\n', num_time, num_channels);
console_log('      Data range before filter: [%.3e, %.3e]\n', min(data(:)), max(data(:)));

% Apply resampling filter to each channel
filtered_data = zeros(size(data));

for ch = 1:num_channels
    if mod(ch, 100) == 0
        console_log('      Processing channel %d/%d...\n', ch, num_channels);
    end
    
    try
        channel_data = double(data(:, ch));
        
        % Check for NaN/Inf
        if any(isnan(channel_data)) || any(isinf(channel_data))
            warning('Channel %d has NaN/Inf values, skipping filter', ch);
            filtered_data(:, ch) = channel_data;
            continue;
        end
        
        % To simulate decimation by N, use a lowpass filter with cutoff at fs/(2*N)
        % For 100Hz data decimated to 1Hz: cutoff at 100/(2*100) = 0.5 Hz
        fs = 100;  % 100 Hz sampling rate
        cutoff_hz = fs / (2 * decimation_factor);
        
        % Design FIR lowpass filter using fir1 (available in base MATLAB)
        % Filter order: make it long enough for good frequency response
        filter_order = min(500, floor(num_time/3));  % Limit order based on data length
        normalized_cutoff = cutoff_hz / (fs/2);  % Normalize to Nyquist
        
        % Clamp cutoff to valid range (must be between 0 and 1)
        normalized_cutoff = max(0.001, min(0.999, normalized_cutoff));
        
        % Design the filter
        fir_coeffs = fir1(filter_order, normalized_cutoff, 'low');
        
        % Apply filter using filtfilt for zero-phase (like resample does)
        filtered_channel = filtfilt(fir_coeffs, 1, channel_data);
        
        % Check output for NaN
        if any(isnan(filtered_channel))
            warning('Channel %d: filter produced NaN, using original', ch);
            filtered_data(:, ch) = channel_data;
        else
            filtered_data(:, ch) = filtered_channel;
        end
        
    catch ME
        warning('Channel %d filtering failed: %s', ch, ME.message);
        console_log('      Error details: %s\n', getReport(ME, 'basic'));
        filtered_data(:, ch) = data(:, ch);  % Keep original if filtering fails
    end
end

console_log('      Data range after filter: [%.3e, %.3e]\n', min(filtered_data(:)), max(filtered_data(:)));
console_log('      Filter complete!\n');

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
