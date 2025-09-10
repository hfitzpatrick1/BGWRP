function fft_results = analyze_fft_spectrum(das_data, config)
%ANALYZE_FFT_SPECTRUM Comprehensive FFT analysis of DAS data
%
% Performs frequency domain analysis including:
% - Power Spectral Density (PSD) computation
% - Dominant frequency identification  
% - Spatial frequency coherence analysis
% - Time-frequency evolution (spectrogram)
%
% Inputs:
%   das_data - DAS analysis results structure containing:
%              .smoothed_data, .time_array, .depth_ft, .analysis_time
%   config   - Configuration structure with FFT parameters
%
% Outputs:
%   fft_results - Structure containing frequency analysis results

fprintf('    Computing FFT spectrum analysis...\n');

% Initialize results structure
fft_results = struct();

% Get FFT configuration parameters
fs = get_config_param(config, 'sampling_rate', 1.0);  % Hz (usually 1 Hz for decimated data)
fft_window_length = get_config_param(config, 'fft_window_length', 512);
fft_overlap = get_config_param(config, 'fft_overlap', 0.5);
freq_range_max = get_config_param(config, 'freq_range_max', 0.4);  % Hz (below Nyquist)
psd_method = get_config_param(config, 'psd_method', 'pwelch');  % 'pwelch' or 'periodogram'

% Adaptive window size - ensure window is not larger than data
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start = min(das_data.analysis_time);
    analysis_end = max(das_data.analysis_time);
    analysis_mask = das_data.time_array >= analysis_start & das_data.time_array <= analysis_end;
    n_analysis_samples = sum(analysis_mask);
else
    n_analysis_samples = size(das_data.smoothed_data, 1);
end

% Adapt window size if necessary
if fft_window_length >= n_analysis_samples
    fft_window_length = min(fft_window_length, floor(n_analysis_samples / 4));
    fft_window_length = max(fft_window_length, 16);  % Minimum window size
    fprintf('      Adapted FFT window size to %d samples (data length: %d)\n', fft_window_length, n_analysis_samples);
end

% Extract analysis window data (reuse the mask from above)
if exist('analysis_mask', 'var')
    analysis_data = das_data.smoothed_data(analysis_mask, :);
    analysis_time = das_data.time_array(analysis_mask);
else
    % Use full dataset if analysis window not available
    analysis_data = das_data.smoothed_data;
    analysis_time = das_data.time_array;
end

[n_time, n_channels] = size(analysis_data);
fprintf('      Analysis window: %d samples, %d channels\n', n_time, n_channels);

%% 1. OVERALL FREQUENCY SPECTRUM (PSD)
fprintf('      Computing power spectral density...\n');

% Select representative channel (pumping zone if available)
if isfield(das_data, 'pumping_zone') && isfield(das_data.pumping_zone, 'channel_idx')
    rep_channel = das_data.pumping_zone.channel_idx;
else
    rep_channel = round(n_channels / 2);  % Middle channel as fallback
end

% Ensure representative channel is valid
rep_channel = max(1, min(rep_channel, n_channels));

% Get signal from representative channel
signal = analysis_data(:, rep_channel);
signal_detrended = detrend(signal);

% Compute PSD using specified method
if strcmp(psd_method, 'pwelch')
    % Welch's method for better noise averaging
    window = hamming(fft_window_length);
    noverlap = round(fft_window_length * fft_overlap);
    nfft = 2^nextpow2(fft_window_length);
    [psd_values, freq_vector] = pwelch(signal_detrended, window, noverlap, nfft, fs);
else
    % Periodogram method
    nfft = 2^nextpow2(n_time);
    [psd_values, freq_vector] = periodogram(signal_detrended, hamming(length(signal_detrended)), nfft, fs);
end

% Limit to specified frequency range
freq_mask = freq_vector <= freq_range_max;
fft_results.freq_vector = freq_vector(freq_mask);
fft_results.psd_values = psd_values(freq_mask);
fft_results.rep_channel = rep_channel;

%% 2. DOMINANT FREQUENCY IDENTIFICATION
fprintf('      Identifying dominant frequencies...\n');

% Find peaks in PSD (dominant frequencies)
psd_smooth = movmean(fft_results.psd_values, 5);  % Smooth for peak detection
psd_threshold = median(psd_smooth) + 2*std(psd_smooth);
[peak_powers, peak_indices] = findpeaks(psd_smooth, 'MinPeakHeight', psd_threshold, 'MinPeakDistance', 5);

fft_results.dominant_freqs = fft_results.freq_vector(peak_indices);
fft_results.dominant_powers = peak_powers;

% Calculate frequency band power distributions
low_freq_mask = fft_results.freq_vector <= 0.1;   % Geological signals
grid_slow_mask = fft_results.freq_vector >= 0.15 & fft_results.freq_vector <= 0.33;  % Slow grid patterns
grid_fast_mask = fft_results.freq_vector >= 0.35 & fft_results.freq_vector <= 0.45;  % Fast grid patterns

fft_results.power_bands.low_freq = sum(fft_results.psd_values(low_freq_mask));
fft_results.power_bands.grid_slow = sum(fft_results.psd_values(grid_slow_mask));
fft_results.power_bands.grid_fast = sum(fft_results.psd_values(grid_fast_mask));
fft_results.power_bands.total = sum(fft_results.psd_values);

fprintf('        Found %d dominant frequencies\n', length(fft_results.dominant_freqs));
if ~isempty(fft_results.dominant_freqs)
    fprintf('        Dominant frequencies: ');
    fprintf('%.3f ', fft_results.dominant_freqs);
    fprintf('Hz\n');
end

%% 3. SPATIAL FREQUENCY COHERENCE
fprintf('      Computing spatial frequency coherence...\n');

% Select subset of channels for coherence analysis (computational efficiency)
n_coherence_channels = min(20, n_channels);
channel_step = max(1, floor(n_channels / n_coherence_channels));
coherence_channels = 1:channel_step:n_channels;

% Compute coherence between representative channel and others
coherence_matrix = zeros(length(fft_results.freq_vector), length(coherence_channels));

for i = 1:length(coherence_channels)
    ch = coherence_channels(i);
    signal_ch = detrend(analysis_data(:, ch));
    
    % Compute magnitude-squared coherence
    [coh_values, ~] = mscohere(signal_detrended, signal_ch, ...
        hamming(fft_window_length), round(fft_window_length * fft_overlap), ...
        length(fft_results.freq_vector), fs);
    
    % Handle size mismatch by interpolating or truncating
    if length(coh_values) == size(coherence_matrix, 1)
        coherence_matrix(:, i) = coh_values;
    else
        % Interpolate to match expected size
        coherence_matrix(:, i) = interp1(1:length(coh_values), coh_values, ...
            linspace(1, length(coh_values), size(coherence_matrix, 1)), 'linear', 'extrap');
    end
end

fft_results.coherence_matrix = coherence_matrix;
fft_results.coherence_channels = coherence_channels;

%% 4. TIME-FREQUENCY ANALYSIS (SPECTROGRAM)
fprintf('      Computing time-frequency evolution...\n');

% Compute spectrogram for representative channel
window_size = min(fft_window_length, floor(n_time/10));  % Adaptive window size
overlap_size = round(window_size * fft_overlap);

[S, F, T] = spectrogram(signal_detrended, hamming(window_size), overlap_size, ...
    fft_results.freq_vector, fs);

% Convert to power and limit frequency range
S_power = abs(S).^2;

fft_results.spectrogram.power = S_power;
fft_results.spectrogram.frequencies = F;
fft_results.spectrogram.time_relative = T;  % Relative time within analysis window

% Convert relative time to absolute time
if length(analysis_time) > 1
    time_offset = analysis_time(1);
    time_scale = (analysis_time(end) - analysis_time(1)) / (length(analysis_time) - 1);
    fft_results.spectrogram.time_absolute = time_offset + fft_results.spectrogram.time_relative * time_scale;
else
    fft_results.spectrogram.time_absolute = analysis_time(1) + fft_results.spectrogram.time_relative / fs;
end

%% 5. NOISE PATTERN CHARACTERIZATION
fprintf('      Characterizing noise patterns...\n');

% Grid pattern analysis based on known artifact frequencies
grid_slow_power = mean(fft_results.psd_values(grid_slow_mask));
grid_fast_power = mean(fft_results.psd_values(grid_fast_mask));
background_power = median(fft_results.psd_values);

fft_results.noise_analysis.grid_slow_ratio = grid_slow_power / background_power;
fft_results.noise_analysis.grid_fast_ratio = grid_fast_power / background_power;
fft_results.noise_analysis.snr_estimate = max(fft_results.psd_values) / background_power;

% Flag potential grid pattern contamination
grid_threshold = 2.0;  % Ratio threshold for grid pattern detection
fft_results.noise_analysis.has_slow_grid = fft_results.noise_analysis.grid_slow_ratio > grid_threshold;
fft_results.noise_analysis.has_fast_grid = fft_results.noise_analysis.grid_fast_ratio > grid_threshold;

if fft_results.noise_analysis.has_slow_grid || fft_results.noise_analysis.has_fast_grid
    fprintf('        WARNING: Grid pattern artifacts detected!\n');
    if fft_results.noise_analysis.has_slow_grid
        fprintf('          Slow grid (0.15-0.33 Hz): %.1fx above background\n', fft_results.noise_analysis.grid_slow_ratio);
    end
    if fft_results.noise_analysis.has_fast_grid
        fprintf('          Fast grid (0.35-0.45 Hz): %.1fx above background\n', fft_results.noise_analysis.grid_fast_ratio);
    end
end

fprintf('      FFT analysis complete\n');

end

function value = get_config_param(config, param_name, default_value)
%GET_CONFIG_PARAM Safely get configuration parameter with default fallback
if isfield(config, param_name)
    value = config.(param_name);
else
    value = default_value;
end
end
