function filtered_data = chen_stage1_bandpass(data, config)
% CHEN_STAGE1_BANDPASS - Butterworth bandpass filter (Chen et al. Stage 1)
%
% Removes high-frequency noise using Butterworth bandpass filtering
% as described in Chen et al. (2023)
%
% Input:
%   data   - DAS data [time x channels]
%   config - Configuration structure
%
% Output:
%   filtered_data - Bandpass filtered data [time x channels]
%
% Configuration Parameters:
%   config.chen_bandpass_low      - Low cutoff frequency Hz (default: 0.001)
%   config.chen_bandpass_high     - High cutoff frequency Hz (default: 0.4)
%   config.chen_bandpass_order    - Filter order (default: 6)
%   config.chen_sampling_rate     - Sampling rate Hz (default: 1.0)

% Get configuration parameters
low_cutoff = get_param(config, 'chen_bandpass_low', 0.001);
high_cutoff = get_param(config, 'chen_bandpass_high', 0.4);
filter_order = get_param(config, 'chen_bandpass_order', 6);
fs = get_param(config, 'chen_sampling_rate', 1.0);

fprintf('      Butterworth BP: [%.4f, %.3f] Hz, order=%d\n', ...
    low_cutoff, high_cutoff, filter_order);

% Design Butterworth bandpass filter
nyquist = fs / 2;
low_norm = low_cutoff / nyquist;
high_norm = high_cutoff / nyquist;

% Ensure normalized frequencies are valid
low_norm = max(low_norm, 1e-6);  % Avoid zero frequency
high_norm = min(high_norm, 0.99); % Stay below Nyquist

try
    % Design bandpass filter
    [b, a] = butter(filter_order, [low_norm high_norm], 'bandpass');
    
    % Apply filter to each channel
    [num_time, num_channels] = size(data);
    filtered_data = zeros(size(data));
    
    for ch = 1:num_channels
        % Apply zero-phase filtering to avoid phase distortion
        filtered_data(:, ch) = filtfilt(b, a, data(:, ch));
    end
    
    fprintf('        Bandpass filtering complete\n');
    
catch ME
    warning('MATLAB:filterDesignFailed', 'Butterworth filter design failed: %s. Using moving average fallback.', ME.message);
    % Fallback to simple moving average
    window_size = round(fs / high_cutoff);
    filtered_data = movmean(data, window_size, 1);
    fprintf('        Fallback moving average applied (window: %d)\n', window_size);
end

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
