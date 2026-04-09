function fft_results = analyze_fft_spectrum_improved(das_data, config)
%ANALYZE_FFT_SPECTRUM_IMPROVED Fundamental FFT analysis following core principles
%
% Performs proper frequency domain analysis based on fundamental FFT principles:
% 1. Time-Domain to Frequency-Domain Conversion
% 2. Decomposition into Frequencies (sine wave components)
% 3. Spectral View (amplitude vs frequency)
% 4. Clear Amplitude and Frequency Determination
%
% Inputs:
%   das_data - DAS analysis results structure
%   config   - Configuration structure
%
% Outputs:
%   fft_results - Structure containing proper frequency analysis

console_log('    Computing improved FFT spectrum analysis...\n');

% Initialize results
fft_results = struct();

% Get higher resolution data if available (before heavy decimation)
if isfield(das_data, 'raw_data') && ~isempty(das_data.raw_data)
    % Use higher sampling rate raw data for better frequency resolution
    signal_data = das_data.raw_data;
    fs = get_config_param(config, 'raw_sampling_rate', 100);  % Original 100 Hz before decimation
    console_log('      Using raw data at %d Hz sampling rate\n', fs);
else
    % Fall back to smoothed data
    signal_data = das_data.smoothed_data;
    fs = get_config_param(config, 'sampling_rate', 1.0);
    console_log('      Using decimated data at %.1f Hz sampling rate\n', fs);
end

% Select analysis window
if isfield(das_data, 'analysis_time') && isfield(das_data, 'time_array')
    analysis_start = min(das_data.analysis_time);
    analysis_end = max(das_data.analysis_time);
    
    if fs == 1.0  % Decimated data
        time_array = das_data.time_array;
    else  % Raw data - create time array
        n_samples = size(signal_data, 1);
        time_array = das_data.time_array(1) + seconds(0:1/fs:(n_samples-1)/fs);
    end
    
    analysis_mask = time_array >= analysis_start & time_array <= analysis_end;
    analysis_data = signal_data(analysis_mask, :);
    analysis_time = time_array(analysis_mask);
else
    analysis_data = signal_data;
    analysis_time = das_data.time_array;
end

[n_time, n_channels] = size(analysis_data);
console_log('      Analysis: %d samples at %.1f Hz, %d channels\n', n_time, fs, n_channels);

% Select representative channel (pumping zone if available)
if isfield(das_data, 'pumping_zone') && isfield(das_data.pumping_zone, 'channel_idx')
    rep_channel = das_data.pumping_zone.channel_idx;
else
    rep_channel = round(n_channels / 2);
end
rep_channel = max(1, min(rep_channel, n_channels));

%% FUNDAMENTAL FFT ANALYSIS
console_log('      Performing fundamental FFT analysis...\n');

% Get signal from representative channel
signal = analysis_data(:, rep_channel);

% Remove DC component and linear trend (standard preprocessing)
signal_centered = signal - mean(signal);
signal_detrended = detrend(signal_centered);

% Apply window function to reduce spectral leakage
if n_time > 1
    window_func = hann(n_time);  % Hann window for good frequency resolution
    signal_windowed = signal_detrended .* window_func;
else
    signal_windowed = signal_detrended;
end

% Compute FFT (core principle: time-domain to frequency-domain)
N = length(signal_windowed);
Y = fft(signal_windowed, N);

% Create frequency vector (Hz)
freq_vector = (0:N-1) * (fs/N);
nyquist_idx = floor(N/2) + 1;  % Only keep up to Nyquist frequency

% Extract magnitude and phase (fundamental FFT outputs)
magnitude = abs(Y(1:nyquist_idx));  % Amplitude of each frequency component
phase = angle(Y(1:nyquist_idx));    % Phase of each frequency component
freq_one_sided = freq_vector(1:nyquist_idx);

% Convert to Power Spectral Density for better visualization
% Scale properly: multiply by 2 for one-sided spectrum (except DC)
psd = magnitude.^2 / (fs * N);
psd(2:end-1) = 2 * psd(2:end-1);  % Scale for one-sided spectrum

% Store fundamental results
fft_results.freq_vector = freq_one_sided;
fft_results.magnitude = magnitude;
fft_results.phase = phase;
fft_results.psd = psd;
fft_results.fs = fs;
fft_results.N = N;
fft_results.rep_channel = rep_channel;

%% FREQUENCY COMPONENT IDENTIFICATION
console_log('      Identifying frequency components...\n');

% Find significant frequency peaks (sine wave components)
% Use relative threshold based on signal characteristics
magnitude_db = 20 * log10(magnitude + eps);  % Convert to dB
noise_floor = median(magnitude_db);
peak_threshold = noise_floor + 10;  % 10 dB above noise floor

[peak_mags, peak_indices] = findpeaks(magnitude_db, 'MinPeakHeight', peak_threshold, ...
    'MinPeakDistance', max(1, round(length(magnitude_db)/100)));

% Store dominant frequency components
fft_results.dominant_frequencies = freq_one_sided(peak_indices);
fft_results.dominant_magnitudes = magnitude(peak_indices);
fft_results.dominant_phases = phase(peak_indices);
fft_results.dominant_amplitudes = fft_results.dominant_magnitudes / (N/2);  % Convert to actual amplitudes

console_log('        Found %d significant frequency components:\n', length(fft_results.dominant_frequencies));
for i = 1:length(fft_results.dominant_frequencies)
    freq_hz = fft_results.dominant_frequencies(i);
    amp = fft_results.dominant_amplitudes(i);
    phase_deg = rad2deg(fft_results.dominant_phases(i));
    console_log('          %.3f Hz: Amplitude = %.2e, Phase = %.1f°\n', freq_hz, amp, phase_deg);
end

%% FREQUENCY BAND ANALYSIS
console_log('      Analyzing frequency bands...\n');

% Define meaningful frequency bands for DAS data
bands = struct();
bands.dc = [0, 0.001];                    % DC component
bands.very_low = [0.001, 0.01];           % Very low frequency (< 0.01 Hz)
bands.geological = [0.01, 0.1];           % Geological signals (0.01-0.1 Hz)
bands.low_noise = [0.1, 1.0];             % Low frequency noise (0.1-1 Hz)

if fs > 10  % Only analyze higher frequencies if we have sufficient sampling rate
    bands.grid_patterns = [1.0, 10.0];    % Grid pattern artifacts (1-10 Hz)
    bands.high_freq = [10.0, fs/2];       % High frequency content (10 Hz - Nyquist)
end

% Calculate power in each band
for band_name = fieldnames(bands)'
    band_range = bands.(band_name{1});
    band_mask = freq_one_sided >= band_range(1) & freq_one_sided <= band_range(2);
    if any(band_mask)
        fft_results.power_bands.(band_name{1}) = sum(psd(band_mask));
    else
        fft_results.power_bands.(band_name{1}) = 0;
    end
end

% Calculate total power
fft_results.power_bands.total = sum(psd);

% Report power distribution
console_log('        Power distribution:\n');
for band_name = fieldnames(fft_results.power_bands)'
    if ~strcmp(band_name{1}, 'total')
        power_pct = 100 * fft_results.power_bands.(band_name{1}) / fft_results.power_bands.total;
        console_log('          %s: %.1f%%\n', band_name{1}, power_pct);
    end
end

%% SPECTRAL QUALITY ASSESSMENT
console_log('      Assessing spectral quality...\n');

% Calculate SNR and spectral characteristics
dc_power = psd(1);  % DC component power
signal_power = sum(psd(2:end));  % AC signal power
snr_db = 10 * log10(signal_power / dc_power);

% Spectral flatness (measure of how "white" the noise is)
geometric_mean = exp(mean(log(psd(2:end) + eps)));
arithmetic_mean = mean(psd(2:end));
spectral_flatness = geometric_mean / arithmetic_mean;

fft_results.quality.snr_db = snr_db;
fft_results.quality.spectral_flatness = spectral_flatness;
fft_results.quality.frequency_resolution = fs / N;

console_log('        SNR: %.1f dB\n', snr_db);
console_log('        Frequency resolution: %.4f Hz\n', fft_results.quality.frequency_resolution);
console_log('        Spectral flatness: %.3f (0=tonal, 1=white noise)\n', spectral_flatness);

console_log('      Improved FFT analysis complete\n');

end

function value = get_config_param(config, param_name, default_value)
%GET_CONFIG_PARAM Safely get configuration parameter with default fallback
if isfield(config, param_name)
    value = config.(param_name);
else
    value = default_value;
end
end

