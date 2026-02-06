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
    fprintf('      Designing filter: fs=%.1f Hz, Nyquist=%.2f Hz\n', fs, nyquist);
    fprintf('      Normalized frequencies: [%.6f, %.6f]\n', low_norm, high_norm);
    [b, a] = butter(filter_order, [low_norm high_norm], 'bandpass');
    fprintf('      Filter designed successfully\n');
    
    % Apply filter to each channel
    [num_time, num_channels] = size(data);
    fprintf('      Data size: [%d time points x %d channels]\n', num_time, num_channels);
    fprintf('      Data range before filter: [%.3e, %.3e]\n', min(data(:)), max(data(:)));
    
    filtered_data = zeros(size(data));
    
    % Check for NaN/Inf in input data
    nan_count = sum(isnan(data(:)));
    inf_count = sum(isinf(data(:)));
    if nan_count > 0 || inf_count > 0
        warning('Input data contains %d NaN and %d Inf values - filtering may fail', nan_count, inf_count);
    end
    
    for ch = 1:num_channels
        % Apply zero-phase filtering to avoid phase distortion
        try
            filtered_data(:, ch) = filtfilt(b, a, data(:, ch));
        catch ME_ch
            warning('Channel %d filtering failed: %s', ch, ME_ch.message);
            filtered_data(:, ch) = data(:, ch);  % Keep original if filtering fails
        end
    end
    
    fprintf('      Data range after filter: [%.3e, %.3e]\n', min(filtered_data(:)), max(filtered_data(:)));
    fprintf('      NaN count after filter: %d\n', sum(isnan(filtered_data(:))));
    fprintf('      Bandpass filtering complete\n');
    
catch ME
    warning('MATLAB:filterDesignFailed', 'Butterworth filter design failed: %s. Using moving average fallback.', ME.message);
    fprintf('      Error details: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('      At: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    % Fallback to simple moving average
    window_size = round(fs / high_cutoff);
    fprintf('      Using fallback moving average (window: %d)\n', window_size);
    filtered_data = movmean(data, window_size, 1);
    fprintf('      Fallback complete\n');
end

end

function value = get_param(config, param_name, default_value)
    if isfield(config, param_name)
        value = config.(param_name);
    else
        value = default_value;
    end
end
